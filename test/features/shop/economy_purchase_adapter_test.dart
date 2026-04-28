import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/shop/services/economy_purchase_adapter.dart';

void main() {
  group('SupabaseEconomyPurchaseAdapter', () {
    test('parses coin item purchase balance and inventory deltas', () async {
      final rpc = _FakeRpc({
        'purchase_item_with_coins': [
          {'remaining_coins': 120, 'new_quantity': 3},
        ],
      });
      final adapter = SupabaseEconomyPurchaseAdapter(rpc: rpc.call);

      final result = await adapter.purchaseItemWithCoins(itemId: 'item-a');

      expect(result.remainingCoins, 120);
      expect(result.resolvedInventoryQuantity, 3);
      expect(rpc.calls.single.rpcName, 'purchase_item_with_coins');
      expect(rpc.calls.single.params, {'p_item_id': 'item-a', 'p_quantity': 1});
    });

    test('parses diamond item purchase and gained candy balance', () async {
      final rpc = _FakeRpc({
        'purchase_item_with_diamonds': {
          'remaining_diamonds': 8,
          'new_quantity': 1,
          'new_coin_balance': 750,
        },
      });
      final adapter = SupabaseEconomyPurchaseAdapter(rpc: rpc.call);

      final result = await adapter.purchaseItemWithDiamonds(
        itemId: 'pack-a',
        previousCoinBalance: 250,
      );

      expect(result.remainingDiamonds, 8);
      expect(result.resolvedInventoryQuantity, 1);
      expect(result.coinBalance, 750);
      expect(result.coinGain, 500);
      expect(rpc.calls.single.rpcName, 'purchase_item_with_diamonds');
    });

    test(
      'prefers room furniture total quantity and exposes message id',
      () async {
        final rpc = _FakeRpc({
          'purchase_room_furniture_with_coins': [
            {
              'remaining_coins': 30,
              'new_quantity': 2,
              'room_total_quantity': 5,
              'message_id': 'message-1',
            },
          ],
        });
        final adapter = SupabaseEconomyPurchaseAdapter(rpc: rpc.call);

        final result = await adapter.purchaseRoomFurnitureWithCoins(
          roomId: 'room-a',
          itemId: 'chair-a',
        );

        expect(result.remainingCoins, 30);
        expect(result.inventoryQuantity, 2);
        expect(result.roomInventoryQuantity, 5);
        expect(result.resolvedInventoryQuantity, 5);
        expect(result.purchaseNotificationMessageId, 'message-1');
        expect(rpc.calls.single.params, {
          'p_room_id': 'room-a',
          'p_item_id': 'chair-a',
        });
      },
    );

    test(
      'suppresses background notification message when already owned',
      () async {
        final rpc = _FakeRpc({
          'purchase_room_background_with_diamonds': {
            'remaining_diamonds': 12,
            'already_owned': true,
            'message_id': 'message-owned',
          },
        });
        final adapter = SupabaseEconomyPurchaseAdapter(rpc: rpc.call);

        final result = await adapter.purchaseRoomBackgroundWithDiamonds(
          roomId: 'room-a',
          itemId: 'background-a',
        );

        expect(result.remainingDiamonds, 12);
        expect(result.backgroundAlreadyOwned, isTrue);
        expect(result.purchaseNotificationMessageId, isNull);
      },
    );

    test('parses IAP grants and keeps RPC params stable', () async {
      final rpc = _FakeRpc({
        'grant_iap_coins': {'new_balance': 900},
        'grant_iap_diamonds': [
          {'new_balance': 42},
        ],
      });
      final adapter = SupabaseEconomyPurchaseAdapter(rpc: rpc.call);

      final coinGrant = await adapter.grantIapCoins(
        productId: 'coin.pack',
        amount: 500,
        transactionId: 'txn-1',
      );
      final diamondGrant = await adapter.grantIapDiamonds(
        productId: 'diamond.pack',
        amount: 40,
        transactionId: 'txn-2',
      );

      expect(coinGrant.newBalance, 900);
      expect(diamondGrant.newBalance, 42);
      expect(rpc.calls[0].rpcName, 'grant_iap_coins');
      expect(rpc.calls[0].params, {
        'p_product_id': 'coin.pack',
        'p_amount': 500,
        'p_transaction_id': 'txn-1',
      });
      expect(rpc.calls[1].rpcName, 'grant_iap_diamonds');
      expect(rpc.calls[1].params, {
        'p_product_id': 'diamond.pack',
        'p_amount': 40,
        'p_transaction_id': 'txn-2',
      });
    });

    test('throws typed failure when purchase RPC returns no row', () async {
      final rpc = _FakeRpc({'purchase_item_with_coins': <dynamic>[]});
      final adapter = SupabaseEconomyPurchaseAdapter(rpc: rpc.call);

      await expectLater(
        adapter.purchaseItemWithCoins(itemId: 'item-a'),
        throwsA(isA<EconomyPurchaseResultException>()),
      );
    });
  });
}

class _FakeRpc {
  _FakeRpc(this.responses);

  final Map<String, dynamic> responses;
  final List<_RpcCall> calls = [];

  Future<dynamic> call(String rpcName, {Map<String, dynamic>? params}) async {
    calls.add(_RpcCall(rpcName, params ?? const <String, dynamic>{}));
    return responses[rpcName];
  }
}

class _RpcCall {
  const _RpcCall(this.rpcName, this.params);

  final String rpcName;
  final Map<String, dynamic> params;
}
