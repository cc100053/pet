import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the fix for the scroll-time crash:
/// `'_dependents.isEmpty': is not true` + "Tried to build dirty widget in the
/// wrong build scope", thrown while deactivating a subtree through a
/// `_LayoutBuilderElement`.
///
/// Root cause: per-message `GlobalKey`s on the lazily-built, reversed chat list
/// got reparented across flutter_chat_ui's `LayoutBuilder`/inherited scope when
/// a scroll-time window trim rebuilt the list, leaving an `InheritedElement`
/// with live dependents during deactivation. The bubbles now register a plain
/// `BuildContext` (via `_MessageSurfaceAnchor`) instead, which has no
/// GlobalKey reparenting semantics.
void main() {
  final viewSource = File(
    'lib/features/chat/chat_room_view_v2.dart',
  ).readAsStringSync();
  final messagesSource = File(
    'lib/features/chat/chat_room_view_v2_messages.dart',
  ).readAsStringSync();
  final buildSource = File(
    'lib/features/chat/chat_room_view_v2_build.dart',
  ).readAsStringSync();

  test(
    'message bubbles use a BuildContext registry, not per-message GlobalKeys',
    () {
      // The lifecycle-managed anchor replaces the GlobalKey surface.
      expect(messagesSource, contains('_MessageSurfaceAnchor('));
      expect(messagesSource, contains('class _MessageSurfaceAnchorState'));
      expect(
        messagesSource,
        contains('final Map<String, BuildContext> surfaceRegistry;'),
      );
      // No GlobalKey surface params remain on the lazily-built bubbles.
      expect(messagesSource, isNot(contains('final GlobalKey surfaceKey;')));
      expect(messagesSource, isNot(contains('key: surfaceKey')));
    },
  );

  test(
    'chat view stores live message surface contexts, not anchor GlobalKeys',
    () {
      expect(
        viewSource,
        contains('Map<String, BuildContext> _messageSurfaceContexts'),
      );
      expect(viewSource, contains('BuildContext? _messageSurfaceContext('));
      // The old GlobalKey map and accessor are gone.
      expect(viewSource, isNot(contains('_messageAnchorKeys')));
      expect(viewSource, isNot(contains('GlobalKey _messageAnchorKey(')));
      // Builders wire the registry through, not a per-message GlobalKey.
      expect(buildSource, contains('surfaceRegistry: _messageSurfaceContexts'));
      expect(buildSource, isNot(contains('surfaceKey: _messageAnchorKey(')));
    },
  );

  test('anchor lifecycle unregisters its context on dispose', () {
    // Self-cleaning registry: dispose removes the entry so no stale contexts
    // accumulate and no manual pruning is required.
    expect(messagesSource, contains('void dispose()'));
    expect(
      messagesSource,
      contains('widget.registry.remove(widget.messageId)'),
    );
    expect(
      messagesSource,
      contains('!identical(oldWidget.registry, widget.registry)'),
    );
  });
}
