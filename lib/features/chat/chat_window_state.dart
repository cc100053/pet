import 'chat_message.dart';

class ChatWindowState {
  ChatWindowState({required this.pageSize, required this.maxVisibleMessages});

  final int pageSize;
  final int maxVisibleMessages;
  final List<ChatMessage> _visibleMessages = <ChatMessage>[];
  final Set<String> _pendingLiveMessageIds = <String>{};

  List<ChatMessage> get visibleMessages =>
      List<ChatMessage>.unmodifiable(_visibleMessages);
  bool get isHistoryMode => _mode == ChatWindowMode.history;
  bool get isLiveMode => _mode == ChatWindowMode.live;
  bool get hasMoreOlder => _hasMoreOlder;
  int get pendingLiveMessageCount => _pendingLiveMessageIds.length;

  ChatMessage? get oldestMessage =>
      _visibleMessages.isEmpty ? null : _visibleMessages.first;
  ChatMessage? get newestMessage =>
      _visibleMessages.isEmpty ? null : _visibleMessages.last;

  ChatWindowMode _mode = ChatWindowMode.live;
  bool _hasMoreOlder = true;

  void hydrateCache(List<ChatMessage> messages) {
    _mode = ChatWindowMode.live;
    _pendingLiveMessageIds.clear();
    _setVisibleMessages(_takeLatest(messages, pageSize));
  }

  void replaceWithLatest(
    List<ChatMessage> messages, {
    required bool hasMoreOlder,
  }) {
    _mode = ChatWindowMode.live;
    _hasMoreOlder = hasMoreOlder;
    _pendingLiveMessageIds.clear();
    _setVisibleMessages(_takeLatest(messages, pageSize));
  }

  void mergeLatestPage(
    List<ChatMessage> messages, {
    required bool hasMoreOlder,
  }) {
    _mode = ChatWindowMode.live;
    _hasMoreOlder = hasMoreOlder;
    _pendingLiveMessageIds.clear();
    final merged = _mergeSortedUnique(_visibleMessages, messages);
    _setVisibleMessages(_trimKeepLatest(merged, maxVisibleMessages));
  }

  void transitionToLatest(
    List<ChatMessage> messages, {
    required bool hasMoreOlder,
  }) {
    _mode = ChatWindowMode.live;
    _hasMoreOlder = hasMoreOlder;
    _pendingLiveMessageIds.clear();
    final merged = _mergeSortedUnique(_visibleMessages, messages);
    _setVisibleMessages(_trimKeepLatest(merged, maxVisibleMessages));
  }

  void prependOlderPage(
    List<ChatMessage> messages, {
    required bool hasMoreOlder,
  }) {
    _mode = ChatWindowMode.history;
    _hasMoreOlder = hasMoreOlder;
    final merged = _mergeSortedUnique(messages, _visibleMessages);
    _setVisibleMessages(_trimKeepOldest(merged, maxVisibleMessages));
  }

  void bufferLiveMessage(ChatMessage message) {
    if (_containsVisibleMessage(message.id)) {
      return;
    }
    _pendingLiveMessageIds.add(message.id);
  }

  void upsertVisibleMessage(
    ChatMessage message, {
    required bool keepLatestWindow,
  }) {
    final merged = _mergeSortedUnique(_visibleMessages, <ChatMessage>[message]);
    final trimmed = keepLatestWindow
        ? _trimKeepLatest(merged, maxVisibleMessages)
        : _trimKeepOldest(merged, maxVisibleMessages);
    _setVisibleMessages(trimmed);
    _pendingLiveMessageIds.remove(message.id);
  }

  void replaceVisibleMessage(ChatMessage message) {
    final index = _visibleMessages.indexWhere(
      (entry) => entry.id == message.id,
    );
    if (index == -1) {
      return;
    }
    _visibleMessages[index] = message;
    _visibleMessages.sort(_compareMessagesAsc);
  }

  void removeVisibleMessage(String messageId) {
    _visibleMessages.removeWhere((message) => message.id == messageId);
    _pendingLiveMessageIds.remove(messageId);
  }

  bool containsVisibleMessage(String messageId) =>
      _containsVisibleMessage(messageId);

  void clearPendingLiveMessages() {
    _pendingLiveMessageIds.clear();
  }

  List<ChatMessage> latestVisibleCanonicalSlice({
    required bool Function(ChatMessage message) includeMessage,
  }) {
    final canonical = _visibleMessages.where(includeMessage).toList();
    if (canonical.length <= pageSize) {
      return canonical;
    }
    return canonical.sublist(canonical.length - pageSize);
  }

  void _setVisibleMessages(List<ChatMessage> messages) {
    _visibleMessages
      ..clear()
      ..addAll(messages);
  }

  bool _containsVisibleMessage(String messageId) {
    for (final message in _visibleMessages) {
      if (message.id == messageId) {
        return true;
      }
    }
    return false;
  }

  static List<ChatMessage> _takeLatest(List<ChatMessage> messages, int limit) {
    final sorted = _mergeSortedUnique(messages, const <ChatMessage>[]);
    return _trimKeepLatest(sorted, limit);
  }

  static List<ChatMessage> _trimKeepLatest(
    List<ChatMessage> messages,
    int limit,
  ) {
    if (messages.length <= limit) {
      return List<ChatMessage>.from(messages);
    }
    return messages.sublist(messages.length - limit);
  }

  static List<ChatMessage> _trimKeepOldest(
    List<ChatMessage> messages,
    int limit,
  ) {
    if (messages.length <= limit) {
      return List<ChatMessage>.from(messages);
    }
    return messages.sublist(0, limit);
  }

  static List<ChatMessage> _mergeSortedUnique(
    List<ChatMessage> left,
    List<ChatMessage> right,
  ) {
    final mergedById = <String, ChatMessage>{};
    for (final message in left) {
      mergedById[message.id] = message;
    }
    for (final message in right) {
      mergedById[message.id] = message;
    }
    final merged = mergedById.values.toList()..sort(_compareMessagesAsc);
    return merged;
  }
}

enum ChatWindowMode { live, history }

int _compareMessagesAsc(ChatMessage a, ChatMessage b) {
  final createdCompare = a.createdAt.compareTo(b.createdAt);
  if (createdCompare != 0) {
    return createdCompare;
  }
  return a.id.compareTo(b.id);
}
