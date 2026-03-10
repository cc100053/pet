import 'package:audioplayers/audioplayers.dart';

class AppSfx {
  AppSfx._();

  static final AudioPlayer _eatingPlayer = AudioPlayer();
  static final AudioPlayer _candyPlayer = AudioPlayer();
  static final AudioContext _sfxAudioContext = AudioContextConfig(
    respectSilence: true,
  ).build();

  static Future<void> playEating() =>
      _play(player: _eatingPlayer, source: AssetSource('sound/eating.m4a'));

  static Future<void> playCandyGain() =>
      _play(player: _candyPlayer, source: AssetSource('sound/get_candy.m4a'));

  static Future<void> _play({
    required AudioPlayer player,
    required AssetSource source,
  }) async {
    try {
      await player.stop();
      await player.play(
        source,
        mode: PlayerMode.lowLatency,
        ctx: _sfxAudioContext,
      );
    } catch (_) {
      // Best-effort SFX. Ignore plugin/platform failures.
    }
  }
}
