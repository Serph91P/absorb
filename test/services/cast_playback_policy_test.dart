import 'package:absorb/services/cast_playback_policy.dart';
import 'package:absorb/services/sleep_timer_tick_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Cast playback policy', () {
    test('buffering receiver with recently advancing position is active', () {
      final now = DateTime.utc(2026, 1, 1, 12);
      final receiverActive = isCastReceiverActive(
        CastPlaybackState.buffering,
        lastPositionAdvance: now.subtract(const Duration(seconds: 10)),
        now: now,
      );

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

    test('stale buffering position holds the timer and shows play', () {
      final now = DateTime.utc(2026, 1, 1, 12);
      final receiverActive = isCastReceiverActive(
        CastPlaybackState.buffering,
        lastPositionAdvance: now.subtract(const Duration(seconds: 31)),
        now: now,
      );

      expect(receiverActive, isFalse);
      expect(
        shouldPauseCastOnToggle(
          CastPlaybackState.buffering,
          receiverActive: receiverActive,
        ),
        isFalse,
      );
      expect(
        sleepTimerTickAction(
          timeRemaining: const Duration(minutes: 30),
          isPlaybackActive: receiverActive,
          isPauseRequested: false,
        ),
        SleepTimerTickAction.wait,
      );
    });

    test('acknowledged pause holds despite a recent buffering position', () {
      final now = DateTime.utc(2026, 1, 1, 12);
      final receiverActive = isCastReceiverActive(
        CastPlaybackState.buffering,
        lastPositionAdvance: now.subtract(const Duration(seconds: 1)),
        now: now,
        isPauseRequested: true,
      );

      expect(receiverActive, isFalse);
      expect(
        shouldPauseCastOnToggle(
          CastPlaybackState.paused,
          receiverActive: receiverActive,
        ),
        isFalse,
      );
      expect(
        sleepTimerTickAction(
          timeRemaining: const Duration(minutes: 30),
          isPlaybackActive: receiverActive,
          isPauseRequested: false,
        ),
        SleepTimerTickAction.wait,
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

    test('buffering without receiver position evidence holds the timer', () {
      expect(isCastReceiverActive(CastPlaybackState.buffering), isFalse);
      expect(
        shouldPauseCastOnToggle(
          CastPlaybackState.buffering,
          receiverActive: false,
        ),
        isFalse,
      );
    });

    test('paused and idle receivers are inactive and toggle to play', () {
      for (final state in [CastPlaybackState.paused, CastPlaybackState.idle]) {
        expect(isCastReceiverActive(state), isFalse);
        expect(shouldPauseCastOnToggle(state), isFalse);
      }
    });
  });
}
