import 'package:absorb/services/cast_playback_policy.dart';
import 'package:absorb/services/sleep_timer_tick_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Cast playback policy', () {
    test('buffering receiver is active for controls and sleep timer', () {
      final receiverActive = isCastReceiverActive(CastPlaybackState.buffering);

      expect(receiverActive, isTrue);
      expect(shouldPauseCastOnToggle(CastPlaybackState.buffering), isTrue);
      expect(
        sleepTimerTickAction(
          timeRemaining: const Duration(minutes: 30),
          isPlaybackActive: receiverActive,
          isPauseRequested: false,
        ),
        SleepTimerTickAction.countDown,
      );
    });

    test('loading receiver pauses on toggle but does not run sleep timer', () {
      expect(isCastReceiverActive(CastPlaybackState.loading), isFalse);
      expect(shouldPauseCastOnToggle(CastPlaybackState.loading), isTrue);
    });

    test('playing receiver is active and pauses on toggle', () {
      expect(isCastReceiverActive(CastPlaybackState.playing), isTrue);
      expect(shouldPauseCastOnToggle(CastPlaybackState.playing), isTrue);
    });

    test('paused and idle receivers are inactive and toggle to play', () {
      for (final state in [CastPlaybackState.paused, CastPlaybackState.idle]) {
        expect(isCastReceiverActive(state), isFalse);
        expect(shouldPauseCastOnToggle(state), isFalse);
      }
    });
  });
}
