import 'package:absorb/services/cast_playback_policy.dart';
import 'package:absorb/services/chromecast_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChromecastService Cast pause seam', () {
    test('successful pause command immediately renders paused', () async {
      var pauseCalls = 0;
      final service = ChromecastService.forTesting(
        pauseCommand: () async => pauseCalls++,
      )..setTestReceiverState(CastPlaybackState.playing);
      addTearDown(service.dispose);

      await service.pause();

      expect(pauseCalls, 1);
      expect(service.playbackState, CastPlaybackState.paused);
      expect(service.isReceiverActive, isFalse);
      expect(service.shouldPauseOnToggle, isFalse);
    });

    test('thrown pause command leaves a playing receiver active', () async {
      final service = ChromecastService.forTesting(
        pauseCommand: () =>
            Future<void>.error(StateError('receiver rejected pause')),
      )..setTestReceiverState(CastPlaybackState.playing);
      addTearDown(service.dispose);

      await service.pause();

      expect(service.playbackState, CastPlaybackState.playing);
      expect(service.isReceiverActive, isTrue);
      expect(service.shouldPauseOnToggle, isTrue);
    });

    test(
      'continued position progress after ignored pause restores playing and notifies',
      () async {
        final service = ChromecastService.forTesting(pauseCommand: () async {})
          ..setTestReceiverState(CastPlaybackState.playing);
        addTearDown(service.dispose);
        var notifications = 0;
        service.addListener(() => notifications++);

        await service.pause();
        final afterPauseNotifications = notifications;
        service.handleTestPosition(const Duration(seconds: 10));
        expect(service.playbackState, CastPlaybackState.paused);
        service.handleTestPosition(const Duration(seconds: 11));

        expect(service.playbackState, CastPlaybackState.playing);
        expect(service.isReceiverActive, isTrue);
        expect(service.shouldPauseOnToggle, isTrue);
        expect(notifications, greaterThan(afterPauseNotifications));
      },
    );

    testWidgets(
      'buffering liveness expiry notifies without another position event',
      (tester) async {
        var now = DateTime.utc(2026, 1, 1, 12);
        final service = ChromecastService.forTesting(now: () => now)
          ..setTestReceiverState(CastPlaybackState.buffering);
        addTearDown(service.dispose);
        var notifications = 0;
        service.addListener(() => notifications++);

        service.handleTestPosition(const Duration(seconds: 10));
        final afterPositionNotifications = notifications;
        expect(service.isReceiverActive, isTrue);

        now = now.add(const Duration(seconds: 31));
        await tester.pump(const Duration(seconds: 31));

        expect(service.isReceiverActive, isFalse);
        expect(notifications, greaterThan(afterPositionNotifications));
      },
    );
  });
}
