import 'package:supabase_flutter/supabase_flutter.dart';

/// Best-effort teardown for a Supabase realtime channel.
///
/// Tries `removeChannel` first and falls back to `unsubscribe`, swallowing
/// errors so widget/route disposal can never fail a user flow. Safe to call
/// with a null channel.
Future<void> removeRealtimeChannelSafely(RealtimeChannel? channel) async {
  if (channel == null) {
    return;
  }
  try {
    await Supabase.instance.client.removeChannel(channel);
  } catch (_) {
    try {
      await channel.unsubscribe();
    } catch (_) {
      // Best-effort cleanup; disposal must not fail user flows.
    }
  }
}
