import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StoreView extends StatefulWidget {
  const StoreView({super.key});

  @override
  State<StoreView> createState() => _StoreViewState();
}

class _StoreViewState extends State<StoreView> {
  bool _loading = true;
  bool _purchasing = false;
  String? _error;
  int _coins = 0;
  List<StoreItem> _items = [];
  final Map<String, int> _inventory = {};

  @override
  void initState() {
    super.initState();
    _loadStore();
  }

  Future<void> _loadStore() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
        _error = 'Please sign in to access the store.';
      });
      return;
    }

    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('coins')
          .eq('user_id', user.id)
          .maybeSingle();

      final itemsResponse = await Supabase.instance.client
          .from('items')
          .select('id,sku,type,name,price_coins,metadata')
          .eq('is_active', true)
          .order('price_coins', ascending: true);

      final inventoryResponse = await Supabase.instance.client
          .from('inventories')
          .select('item_id,quantity')
          .eq('user_id', user.id);

      final items = (itemsResponse as List<dynamic>)
          .map((row) => StoreItem.fromJson(row as Map<String, dynamic>))
          .toList();

      final inventory = <String, int>{};
      for (final row in inventoryResponse as List<dynamic>) {
        final itemId = row['item_id'] as String?;
        final quantity = row['quantity'] as int?;
        if (itemId != null && quantity != null) {
          inventory[itemId] = quantity;
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _coins = (profile?['coins'] as int?) ?? 0;
        _items = items;
        _inventory
          ..clear()
          ..addAll(inventory);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Failed to load store: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _purchaseItem(StoreItem item) async {
    if (_purchasing) {
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return;
    }

    setState(() {
      _purchasing = true;
    });

    try {
      final response = await Supabase.instance.client.rpc(
        'purchase_item_with_coins',
        params: {
          'p_item_id': item.id,
          'p_quantity': 1,
        },
      );

      Map<String, dynamic>? row;
      if (response is List && response.isNotEmpty) {
        row = response.first as Map<String, dynamic>;
      } else if (response is Map) {
        row = response.cast<String, dynamic>();
      }

      if (row != null) {
        final remaining = row['remaining_coins'] as int?;
        final newQuantity = row['new_quantity'] as int?;
        setState(() {
          if (remaining != null) {
            _coins = remaining;
          }
          if (newQuantity != null) {
            _inventory[item.id] = newQuantity;
          }
        });
      }

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Purchased ${item.name}.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Purchase failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _purchasing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Chip(
                label: Text('Coins: $_coins'),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStore,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 160),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _loadStore,
            child: const Text('Try again'),
          ),
        ],
      );
    }

    if (_items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: const [
          Text(
            'Store is empty for now.',
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        final ownedQty = _inventory[item.id] ?? 0;
        final isCosmetic = item.type == 'cosmetic';
        final isOwned = isCosmetic && ownedQty > 0;
        final canAfford = item.priceCoins != null && _coins >= item.priceCoins!;
        final showQuantity = !isCosmetic && ownedQty > 0;
        final canBuy =
            !_purchasing && !isOwned && canAfford && item.priceCoins != null;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.displayType,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: canBuy ? () => _purchaseItem(item) : null,
                      child: Text(isOwned ? 'Owned' : 'Buy'),
                    ),
                  ],
                ),
                if (item.description != null) ...[
                  const SizedBox(height: 8),
                  Text(item.description!),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('Coins: ${item.priceCoins ?? '-'}'),
                    if (item.priceJpy != null) ...[
                      const SizedBox(width: 12),
                      Text('JPY ${item.priceJpy}'),
                    ],
                  ],
                ),
                if (showQuantity) ...[
                  const SizedBox(height: 6),
                  Text('Owned: $ownedQty'),
                ] else if (isOwned) ...[
                  const SizedBox(height: 6),
                  const Text('Owned'),
                ],
                if (!canAfford && !isOwned && item.priceCoins != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Not enough coins.',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class StoreItem {
  StoreItem({
    required this.id,
    required this.sku,
    required this.type,
    required this.name,
    required this.priceCoins,
    required this.priceJpy,
    required this.description,
  });

  final String id;
  final String sku;
  final String type;
  final String name;
  final int? priceCoins;
  final int? priceJpy;
  final String? description;

  String get displayType {
    switch (type) {
      case 'cosmetic':
        return 'Cosmetic';
      case 'consumable':
        return 'Consumable';
      default:
        return type;
    }
  }

  factory StoreItem.fromJson(Map<String, dynamic> json) {
    final metadata = (json['metadata'] as Map?)?.cast<String, dynamic>() ?? {};
    final priceJpyRaw = metadata['price_jpy'];
    final description = metadata['description'] as String?;

    int? priceJpy;
    if (priceJpyRaw is int) {
      priceJpy = priceJpyRaw;
    } else if (priceJpyRaw is double) {
      priceJpy = priceJpyRaw.round();
    } else if (priceJpyRaw is String) {
      priceJpy = int.tryParse(priceJpyRaw);
    }

    return StoreItem(
      id: json['id'] as String,
      sku: json['sku'] as String,
      type: json['type'] as String? ?? 'consumable',
      name: json['name'] as String? ?? 'Item',
      priceCoins: json['price_coins'] as int?,
      priceJpy: priceJpy,
      description: description,
    );
  }
}
