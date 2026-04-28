import 'package:supabase_flutter/supabase_flutter.dart';

typedef EconomyRpcInvoker =
    Future<dynamic> Function(String rpcName, {Map<String, dynamic>? params});

abstract class EconomyPurchaseAdapter {
  Future<EconomyPurchaseResult> purchaseItemWithCoins({
    required String itemId,
    int quantity = 1,
  });

  Future<EconomyPurchaseResult> purchaseItemWithDiamonds({
    required String itemId,
    required int previousCoinBalance,
    int quantity = 1,
  });

  Future<EconomyPurchaseResult> purchaseRoomFurnitureWithCoins({
    required String roomId,
    required String itemId,
  });

  Future<EconomyPurchaseResult> purchaseRoomFurnitureWithDiamonds({
    required String roomId,
    required String itemId,
  });

  Future<EconomyPurchaseResult> purchaseRoomBackgroundWithCoins({
    required String roomId,
    required String itemId,
  });

  Future<EconomyPurchaseResult> purchaseRoomBackgroundWithDiamonds({
    required String roomId,
    required String itemId,
  });

  Future<EconomyIapGrantResult> grantIapCoins({
    required String productId,
    required int amount,
    required String transactionId,
  });

  Future<EconomyIapGrantResult> grantIapDiamonds({
    required String productId,
    required int amount,
    required String transactionId,
  });
}

class EconomyPurchaseResult {
  const EconomyPurchaseResult({
    this.remainingCoins,
    this.remainingDiamonds,
    this.inventoryQuantity,
    this.roomInventoryQuantity,
    this.coinBalance,
    this.coinGain,
    this.backgroundAlreadyOwned = false,
    this.purchaseNotificationMessageId,
  });

  final int? remainingCoins;
  final int? remainingDiamonds;
  final int? inventoryQuantity;
  final int? roomInventoryQuantity;
  final int? coinBalance;
  final int? coinGain;
  final bool backgroundAlreadyOwned;
  final String? purchaseNotificationMessageId;

  int? get resolvedInventoryQuantity =>
      roomInventoryQuantity ?? inventoryQuantity;
}

class EconomyIapGrantResult {
  const EconomyIapGrantResult({this.newBalance});

  final int? newBalance;
}

class EconomyPurchaseResultException implements Exception {
  const EconomyPurchaseResultException(this.message);

  final String message;

  @override
  String toString() => 'EconomyPurchaseResultException: $message';
}

class SupabaseEconomyPurchaseAdapter implements EconomyPurchaseAdapter {
  SupabaseEconomyPurchaseAdapter({EconomyRpcInvoker? rpc})
    : _rpc = rpc ?? _supabaseRpc;

  final EconomyRpcInvoker _rpc;

  static Future<dynamic> _supabaseRpc(
    String rpcName, {
    Map<String, dynamic>? params,
  }) {
    return Supabase.instance.client.rpc(rpcName, params: params);
  }

  @override
  Future<EconomyPurchaseResult> purchaseItemWithCoins({
    required String itemId,
    int quantity = 1,
  }) async {
    final row = await _callRequiredResult(
      'purchase_item_with_coins',
      params: {'p_item_id': itemId, 'p_quantity': quantity},
    );
    return EconomyPurchaseResult(
      remainingCoins: _intValue(row['remaining_coins']),
      inventoryQuantity: _intValue(row['new_quantity']),
    );
  }

  @override
  Future<EconomyPurchaseResult> purchaseItemWithDiamonds({
    required String itemId,
    required int previousCoinBalance,
    int quantity = 1,
  }) async {
    final row = await _callRequiredResult(
      'purchase_item_with_diamonds',
      params: {'p_item_id': itemId, 'p_quantity': quantity},
    );
    final newCoinBalance = _intValue(row['new_coin_balance']);
    return EconomyPurchaseResult(
      remainingDiamonds: _intValue(row['remaining_diamonds']),
      inventoryQuantity: _intValue(row['new_quantity']),
      coinBalance: newCoinBalance,
      coinGain: newCoinBalance == null
          ? null
          : newCoinBalance - previousCoinBalance,
    );
  }

  @override
  Future<EconomyPurchaseResult> purchaseRoomFurnitureWithCoins({
    required String roomId,
    required String itemId,
  }) async {
    final row = await _callRequiredResult(
      'purchase_room_furniture_with_coins',
      params: {'p_room_id': roomId, 'p_item_id': itemId},
    );
    return EconomyPurchaseResult(
      remainingCoins: _intValue(row['remaining_coins']),
      inventoryQuantity: _intValue(row['new_quantity']),
      roomInventoryQuantity: _intValue(row['room_total_quantity']),
      purchaseNotificationMessageId: _nonEmptyString(row['message_id']),
    );
  }

  @override
  Future<EconomyPurchaseResult> purchaseRoomFurnitureWithDiamonds({
    required String roomId,
    required String itemId,
  }) async {
    final row = await _callRequiredResult(
      'purchase_room_furniture_with_diamonds',
      params: {'p_room_id': roomId, 'p_item_id': itemId},
    );
    return EconomyPurchaseResult(
      remainingDiamonds: _intValue(row['remaining_diamonds']),
      inventoryQuantity: _intValue(row['new_quantity']),
      roomInventoryQuantity: _intValue(row['room_total_quantity']),
      purchaseNotificationMessageId: _nonEmptyString(row['message_id']),
    );
  }

  @override
  Future<EconomyPurchaseResult> purchaseRoomBackgroundWithCoins({
    required String roomId,
    required String itemId,
  }) async {
    final row = await _callRequiredResult(
      'purchase_room_background_with_coins',
      params: {'p_room_id': roomId, 'p_item_id': itemId},
    );
    return _backgroundResult(
      row,
      remainingCoins: _intValue(row['remaining_coins']),
    );
  }

  @override
  Future<EconomyPurchaseResult> purchaseRoomBackgroundWithDiamonds({
    required String roomId,
    required String itemId,
  }) async {
    final row = await _callRequiredResult(
      'purchase_room_background_with_diamonds',
      params: {'p_room_id': roomId, 'p_item_id': itemId},
    );
    return _backgroundResult(
      row,
      remainingDiamonds: _intValue(row['remaining_diamonds']),
    );
  }

  @override
  Future<EconomyIapGrantResult> grantIapCoins({
    required String productId,
    required int amount,
    required String transactionId,
  }) async {
    final row = _optionalResult(
      await _rpc(
        'grant_iap_coins',
        params: {
          'p_product_id': productId,
          'p_amount': amount,
          'p_transaction_id': transactionId,
        },
      ),
    );
    return EconomyIapGrantResult(newBalance: _intValue(row?['new_balance']));
  }

  @override
  Future<EconomyIapGrantResult> grantIapDiamonds({
    required String productId,
    required int amount,
    required String transactionId,
  }) async {
    final row = _optionalResult(
      await _rpc(
        'grant_iap_diamonds',
        params: {
          'p_product_id': productId,
          'p_amount': amount,
          'p_transaction_id': transactionId,
        },
      ),
    );
    return EconomyIapGrantResult(newBalance: _intValue(row?['new_balance']));
  }

  Future<Map<String, dynamic>> _callRequiredResult(
    String rpcName, {
    required Map<String, dynamic> params,
  }) async {
    final response = await _rpc(rpcName, params: params);
    final row = _optionalResult(response);
    if (row == null) {
      throw EconomyPurchaseResultException(
        'store.$rpcName returned no purchase result',
      );
    }
    return row;
  }

  EconomyPurchaseResult _backgroundResult(
    Map<String, dynamic> row, {
    int? remainingCoins,
    int? remainingDiamonds,
  }) {
    final alreadyOwned = row['already_owned'] as bool? ?? false;
    return EconomyPurchaseResult(
      remainingCoins: remainingCoins,
      remainingDiamonds: remainingDiamonds,
      backgroundAlreadyOwned: alreadyOwned,
      purchaseNotificationMessageId: alreadyOwned
          ? null
          : _nonEmptyString(row['message_id']),
    );
  }

  Map<String, dynamic>? _optionalResult(dynamic response) {
    if (response is List && response.isNotEmpty) {
      final first = response.first;
      if (first is Map) {
        return first.cast<String, dynamic>();
      }
      return null;
    }
    if (response is Map) {
      return response.cast<String, dynamic>();
    }
    return null;
  }

  int? _intValue(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  String? _nonEmptyString(Object? value) {
    if (value is! String) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
