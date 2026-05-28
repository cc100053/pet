import 'chat_message.dart';

class ChatWindowState {
  ChatWindowState({required this.pageSize, required this.maxVisibleMessages});

  final int pageSize;
  final int maxVisibleMessages;
  final List<ChatMessage> _visibleMessages = <ChatMessage>[];
  // Live messages that arrived while in history mode. We keep the full message
  // objects (not just ids) so we can flush them into the window locally on
  // rejoin without a network refetch or a hard content swap.
  final Map<String, ChatMessage> _pendingLiveMessages = <String, ChatMessage>{};

  List<ChatMessage> get visibleMessages =>
      List<ChatMessage>.unmodifiable(_visibleMessages);
  bool get isHistoryMode => _mode == ChatWindowMode.history;
  bool get isLiveMode => _mode == ChatWindowMode.live;
  bool get hasMoreOlder => _hasMoreOlder;
  int get pendingLiveMessageCount => _pendingLiveMessages.length;

  ChatMessage? get oldestMessage =>
      _visibleMessages.isEmpty ? null : _visibleMessages.first;
  ChatMessage? get newestMessage =>
      _visibleMessages.isEmpty ? null : _visibleMessages.last;

  ChatWindowMode _mode = ChatWindowMode.live;
  bool _hasMoreOlder = true;

  void hydrateCache(List<ChatMessage> messages) {
    _mode = ChatWindowMode.live;
    _pendingLiveMessages.clear();
    _setVisibleMessages(_takeLatest(messages, pageSize));
  }

  void replaceWithLatest(
    List<ChatMessage> messages, {
    required bool hasMoreOlder,
  }) {
    _mode = ChatWindowMode.live;
    _hasMoreOlder = hasMoreOlder;
    _pendingLiveMessages.clear();
    _setVisibleMessages(_takeLatest(messages, pageSize));
  }

  void mergeLatestPage(
    List<ChatMessage> messages, {
    required bool hasMoreOlder,
  }) {
    _mode = ChatWindowMode.live;
    _hasMoreOlder = hasMoreOlder;
    _pendingLiveMessages.clear();
    final merged = _mergeSortedUnique(_visibleMessages, messages);
    _setVisibleMessages(_trimKeepLatest(merged, maxVisibleMessages));
  }

  void transitionToLatest(
    List<ChatMessage> messages, {
    required bool hasMoreOlder,
  }) {
    _mode = ChatWindowMode.live;
    _hasMoreOlder = hasMoreOlder;
    _pendingLiveMessages.clear();
    final merged = _mergeSortedUnique(_visibleMessages, messages);
    _setVisibleMessages(_trimKeepLatest(merged, maxVisibleMessages));
  }

  /// Flush buffered live messages into the visible window and return to live
  /// mode, entirely from local state. Keeps the newest [maxVisibleMessages] so
  /// the in-memory cap is preserved. When nothing is buffered this is just a
  /// mode flip with no content change, so rejoining the latest end while
  /// reading history no longer forces a refetch or a visible content swap.
  void flushBufferedToLatest() {
    _mode = ChatWindowMode.live;
    if (_pendingLiveMessages.isEmpty) {
      return;
    }
    final merged = _mergeSortedUnique(
      _visibleMessages,
      _pendingLiveMessages.values.toList(growable: false),
    );
    _pendingLiveMessages.clear();
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
    _pendingLiveMessages[message.id] = message;
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
    _pendingLiveMessages.remove(message.id);
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
    _pendingLiveMessages.remove(messageId);
  }

  bool containsVisibleMessage(String messageId) =>
      _containsVisibleMessage(messageId);

  void clearPendingLiveMessages() {
    _pendingLiveMessages.clear();
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
