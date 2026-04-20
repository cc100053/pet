import 'dart:convert';

import 'package:flutter_chat_core/flutter_chat_core.dart' as fc;
import 'package:pet/l10n/app_localizations.dart';

import '../../shop/shop_item_localization.dart';
import '../chat_message.dart';

class PetChatMessageAdapter {
  const PetChatMessageAdapter._();

  static const String systemAuthorId = '__system__';
  static const String metadataTypeKey = 'petMessageType';
  static const String customTypeKey = 'customType';
  static const String feedCardType = 'feed_card';
  static const String captionKey = 'caption';
  static const String imageUrlKey = 'imageUrl';
  static const String localImagePathKey = 'localImagePath';
  static const String coinsAwardedKey = 'coinsAwarded';
  static const String isOptimisticKey = 'isOptimistic';
  static const String isEditedKey = 'isEdited';
  static const String isDeletedKey = 'isDeleted';

  static fc.Message toUiMessage(
    ChatMessage message,
    AppLocalizations l10n, {
    bool isOptimistic = false,
  }) {
    final authorId = _authorIdFor(message.senderId);
    final metadata = <String, dynamic>{
      metadataTypeKey: message.type,
      if (isOptimistic) isOptimisticKey: true,
      if (message.isEdited) isEditedKey: true,
      if (message.isDeleted) isDeletedKey: true,
    };

    if (message.isSystem) {
      return fc.Message.system(
        id: message.id,
        authorId: authorId,
        createdAt: message.createdAt,
        sentAt: message.createdAt,
        replyToMessageId: message.replyToMessageId,
        status: fc.MessageStatus.sent,
        metadata: metadata,
        text: localizedSystemText(message, l10n),
      );
    }

    if (message.isImageFeed) {
      return fc.Message.custom(
        id: message.id,
        authorId: authorId,
        createdAt: message.createdAt,
        sentAt: isOptimistic ? null : message.createdAt,
        replyToMessageId: message.replyToMessageId,
        status: isOptimistic ? fc.MessageStatus.sending : fc.MessageStatus.sent,
        metadata: <String, dynamic>{
          ...metadata,
          customTypeKey: feedCardType,
          captionKey: message.caption,
          imageUrlKey: message.imageUrl,
          localImagePathKey: message.localImagePath,
          coinsAwardedKey: message.coinsAwarded,
        },
      );
    }

    return fc.Message.text(
      id: message.id,
      authorId: authorId,
      createdAt: message.createdAt,
      sentAt: isOptimistic ? null : message.createdAt,
      replyToMessageId: message.replyToMessageId,
      status: isOptimistic ? fc.MessageStatus.sending : fc.MessageStatus.sent,
      metadata: metadata,
      text: message.isDeleted
          ? l10n.chatMessageDeleted
          : (message.body ?? '').trim(),
    );
  }

  static String previewTextForMessage(
    ChatMessage message,
    AppLocalizations l10n,
  ) {
    if (message.isSystem) {
      return localizedSystemText(message, l10n);
    }
    if (message.isImageFeed) {
      final caption = (message.caption ?? '').trim();
      return caption.isNotEmpty ? caption : l10n.feedTitle;
    }
    if (message.isDeleted) {
      return l10n.chatMessageDeleted;
    }
    final body = (message.body ?? '').trim();
    return body.isNotEmpty ? body : l10n.chatMessageHint;
  }

  static String previewTextForReply(
    ChatReplyPreview preview,
    AppLocalizations l10n,
  ) {
    if (preview.isImageFeed) {
      final caption = (preview.caption ?? '').trim();
      return caption.isNotEmpty ? caption : l10n.feedTitle;
    }
    if (preview.isDeleted) {
      return l10n.chatMessageDeleted;
    }
    final body = (preview.body ?? '').trim();
    return body.isNotEmpty ? body : l10n.chatMessageHint;
  }

  static String feedRewardLabel(int amount, AppLocalizations l10n) {
    return l10n.chatCoinsAwarded(amount);
  }

  static String localizedSystemText(
    ChatMessage message,
    AppLocalizations l10n,
  ) {
    final raw = message.body?.trim();
    if (raw == null || raw.isEmpty) {
      return l10n.chatSystemUpdate;
    }

    final hungerAlert = _parseHungerAlert(raw, l10n);
    if (hungerAlert != null) {
      return hungerAlert.level == 10
          ? l10n.chatPetHungryUrgentMessage(hungerAlert.petName)
          : l10n.chatPetHungryReminderMessage(hungerAlert.petName);
    }

    final storePurchase = _parseStructuredStorePurchase(raw, l10n);
    if (storePurchase != null) {
      return storePurchase;
    }

    final lower = raw.toLowerCase();
    final phrases = <String>['cleaned the poop', '清理了便便', 'うんちを掃除した', '배변을 치웠'];
    final matchedPhrase = phrases.firstWhere(
      (phrase) => lower.contains(phrase),
      orElse: () => '',
    );
    if (matchedPhrase.isNotEmpty) {
      final phraseIndex = lower.indexOf(matchedPhrase);
      final nameRaw = phraseIndex > 0 ? raw.substring(0, phraseIndex) : '';
      final name = nameRaw.trim().isEmpty
          ? l10n.chatSystemUpdate
          : nameRaw.trim();
      final amountFromBody = RegExp(r'\+(\d+)').firstMatch(raw)?.group(1);
      final amount = message.coinsAwarded > 0
          ? message.coinsAwarded.toString()
          : (amountFromBody ?? '0');
      return l10n.chatCleanPoopMessage(name, amount);
    }

    final renamedFromMessage = _parseRenameFromMessage(raw, l10n);
    if (renamedFromMessage != null) {
      return renamedFromMessage;
    }

    final storePurchaseMessage = _parseStorePurchaseMessage(raw, l10n);
    if (storePurchaseMessage != null) {
      return storePurchaseMessage;
    }

    final renameMatch = RegExp(
      r'^(.+?)\s*renamed the pet to\s*(.+?)\s*\.?$',
      caseSensitive: false,
    ).firstMatch(raw);
    if (renameMatch != null) {
      final name = (renameMatch.group(1) ?? '').trim().isEmpty
          ? l10n.chatSystemUpdate
          : renameMatch.group(1)!.trim();
      final petName = (renameMatch.group(2) ?? '').trim();
      if (petName.isNotEmpty) {
        return l10n.chatPetRenamedMessage(name, l10n.petNameUnnamed, petName);
      }
    }

    final renameLocalizedMatch = RegExp(
      r'^(.+?)\s*(?:renamed the pet to|將寵物名字改為|改了寵物名字為|ペットの名前を)(.+?)\s*\.?$',
      caseSensitive: false,
    ).firstMatch(raw);
    if (renameLocalizedMatch != null) {
      final name = (renameLocalizedMatch.group(1) ?? '').trim().isEmpty
          ? l10n.chatSystemUpdate
          : renameLocalizedMatch.group(1)!.trim();
      final petName = (renameLocalizedMatch.group(2) ?? '').trim();
      if (petName.isNotEmpty) {
        return l10n.chatPetRenamedMessage(name, l10n.petNameUnnamed, petName);
      }
    }

    return raw.replaceAll('Coins', l10n.chatCandyLabel);
  }

  static String _authorIdFor(String? senderId) {
    final trimmed = senderId?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return systemAuthorId;
    }
    return trimmed;
  }

  static _HungerAlertInfo? _parseHungerAlert(
    String raw,
    AppLocalizations l10n,
  ) {
    final level = raw.startsWith('hunger_alert_50::')
        ? 50
        : (raw.startsWith('hunger_alert_30::')
              ? 30
              : (raw.startsWith('hunger_alert_10::') ? 10 : null));
    if (level == null) {
      return null;
    }

    final separatorIndex = raw.indexOf('::');
    final petName = separatorIndex >= 0
        ? raw.substring(separatorIndex + 2).trim()
        : '';
    return _HungerAlertInfo(
      level: level,
      petName: petName.isEmpty ? l10n.petNameUnknown : petName,
    );
  }

  static String? _parseRenameFromMessage(String raw, AppLocalizations l10n) {
    final lower = raw.toLowerCase();
    const phrase = 'renamed the pet from';
    final phraseIndex = lower.indexOf(phrase);
    if (phraseIndex == -1) {
      return null;
    }

    final userPart = raw.substring(0, phraseIndex).trim();
    final userName = userPart.isEmpty ? l10n.chatSystemUpdate : userPart;
    final rest = raw.substring(phraseIndex + phrase.length).trim();
    if (rest.isEmpty) {
      return null;
    }

    final lowerRest = rest.toLowerCase();
    final toIndex = lowerRest.lastIndexOf(' to ');
    if (toIndex == -1) {
      return null;
    }

    final oldNameRaw = rest.substring(0, toIndex).trim();
    var newName = rest.substring(toIndex + 4).trim();
    newName = newName.replaceAll(RegExp(r'[.]$'), '').trim();
    if (newName.isEmpty) {
      return null;
    }

    final normalizedOld = oldNameRaw.trim();
    final oldLower = normalizedOld.toLowerCase();
    final isUnnamed =
        normalizedOld.isEmpty ||
        oldLower == 'unnamed' ||
        normalizedOld == '이름 없음';
    final oldName = isUnnamed ? l10n.petNameUnnamed : normalizedOld;

    return l10n.chatPetRenamedMessage(userName, oldName, newName);
  }

  static String? _parseStorePurchaseMessage(String raw, AppLocalizations l10n) {
    final match = RegExp(
      r'^(.+?)\s+bought\s+(furniture|a background|background)\s+for\s+(.+?)\s*\.?$',
      caseSensitive: false,
    ).firstMatch(raw);
    if (match == null) {
      return null;
    }

    final userName = (match.group(1) ?? '').trim();
    final category = (match.group(2) ?? '').trim().toLowerCase();
    final petName = (match.group(3) ?? '').trim();
    if (petName.isEmpty) {
      return null;
    }

    final normalizedUser = userName.isEmpty ? l10n.chatSystemUpdate : userName;
    return category == 'furniture'
        ? l10n.chatBoughtFurnitureMessage(normalizedUser, petName)
        : l10n.chatBoughtBackgroundMessage(normalizedUser, petName);
  }

  static String? _parseStructuredStorePurchase(
    String raw,
    AppLocalizations l10n,
  ) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      final payload = Map<String, dynamic>.from(decoded);
      if ((payload['kind'] as String?) != 'store_purchase') {
        return null;
      }
      final userName = (payload['user_name'] as String? ?? '').trim();
      final petName = (payload['pet_name'] as String? ?? '').trim();
      final itemSku = (payload['item_sku'] as String? ?? '').trim();
      if (petName.isEmpty || itemSku.isEmpty) {
        return null;
      }
      final normalizedUser = userName.isEmpty
          ? l10n.chatSystemUpdate
          : userName;
      final itemName = localizedShopItemNameForSku(itemSku, l10n);
      return l10n.chatBoughtStoreItemMessage(normalizedUser, itemName, petName);
    } catch (_) {
      return null;
    }
  }
}

class _HungerAlertInfo {
  const _HungerAlertInfo({required this.level, required this.petName});

  final int level;
  final String petName;
}
