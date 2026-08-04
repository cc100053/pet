import 'chat_message.dart';
import 'widgets/deterministic_chat_list.dart';

/// Decides which bubbles render their sender's name.
///
/// The chat package's own grouping only compares the adjacent author id, and a
/// system pill emitted for a user's action carries that user's id — so the
/// user's next message looked "grouped" and silently lost its name. Sender-name
/// visibility is therefore resolved from the domain list here:
///
/// * system pills sit outside the name system: they never carry a name and
///   never extend the previous sender's group;
/// * feed photos always name their sender, so the sender stays obvious;
/// * consecutive text from one sender still names only the first bubble.
///
/// [messages] must be the visible messages in ascending time order.
/// [historyGroupingBoundaryMessageId] is the oldest message of a freshly loaded
/// history page, which always restarts a group.
Set<String> senderNameVisibleMessageIds(
  List<ChatMessage> messages, {
  String? historyGroupingBoundaryMessageId,
}) {
  final visibleIds = <String>{};
  ChatMessage? previous;
  for (final message in messages) {
    if (message.isSystem) {
      previous = null;
      continue;
    }
    final showsName =
        alwaysShowsSenderName(message) ||
        message.id == historyGroupingBoundaryMessageId ||
        previous == null ||
        !canGroupSenderNames(previous, message);
    if (showsName) {
      visibleIds.add(message.id);
    }
    previous = message;
  }
  return visibleIds;
}

/// A feed photo always names its sender; a recalled one renders as a plain
/// tombstone bubble and follows the normal grouping rules.
bool alwaysShowsSenderName(ChatMessage message) =>
    message.isImageFeed && !message.isDeleted;

/// How long a sender's group stays open, mirroring `flutter_chat_ui`'s default
/// `messageGroupingTimeoutInSeconds` so bubble grouping and sender names agree.
const Duration senderNameGroupingTimeout = Duration(minutes: 5);

/// Whether [b] continues [a]'s name group (same sender, same local day, within
/// [senderNameGroupingTimeout]).
bool canGroupSenderNames(ChatMessage a, ChatMessage b) {
  if (a.isSystem || b.isSystem) {
    return false;
  }
  if (b.createdAt.difference(a.createdAt) >= senderNameGroupingTimeout) {
    return false;
  }
  final aSender = a.senderId?.trim();
  final bSender = b.senderId?.trim();
  if (aSender == null ||
      aSender.isEmpty ||
      bSender == null ||
      bSender.isEmpty) {
    return false;
  }
  return aSender == bSender && isSameLocalChatDay(a.createdAt, b.createdAt);
}
