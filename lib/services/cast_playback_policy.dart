/// Receiver-state semantics for sender controls and sleep-timer liveness.
///
/// [CastPlaybackState.playing] remains the strict state for listening statistics.
/// A receiver which reports [CastPlaybackState.buffering] can nevertheless keep
/// advancing its position, so controls and the sleep timer use these separate
/// policy functions instead.
enum CastPlaybackState { idle, loading, playing, paused, buffering }

/// The receiver position must keep moving while a misleading buffering state
/// is used as playback evidence. A status event alone is not enough.
const staleCastBufferingGrace = Duration(seconds: 30);

/// Whether the receiver is active enough for the sleep timer to count down.
bool isCastReceiverActive(
  CastPlaybackState state, {
  DateTime? lastPositionAdvance,
  DateTime? now,
  bool isPauseRequested = false,
}) {
  if (isPauseRequested) return false;
  if (state == CastPlaybackState.playing) return true;
  if (state != CastPlaybackState.buffering || lastPositionAdvance == null)
    return false;
  return (now ?? DateTime.now()).difference(lastPositionAdvance) <=
      staleCastBufferingGrace;
}

/// The deadline at which a buffering receiver must cause a controls rebuild.
/// Null means that the current state has no position-based liveness window.
DateTime? castBufferingLivenessDeadline(
  CastPlaybackState state, {
  DateTime? lastPositionAdvance,
  bool isPauseRequested = false,
}) {
  if (state != CastPlaybackState.buffering ||
      isPauseRequested ||
      lastPositionAdvance == null) {
    return null;
  }
  return lastPositionAdvance.add(staleCastBufferingGrace);
}

/// A position packet is not playback confirmation: it may have been queued
/// before a successful pause command. Only playing / an acknowledged resume
/// may clear the sender's pause intent.
bool shouldClearCastPauseIntent(CastPlaybackState receiverState) =>
    receiverState == CastPlaybackState.playing;

/// Whether a play/pause toggle must send pause rather than play.
///
/// Loading can still be cancelled. Buffering follows the same liveness evidence
/// as the sleep timer when it is available; callers without it retain the
/// receiver-status default.
bool shouldPauseCastOnToggle(CastPlaybackState state, {bool? receiverActive}) =>
    state == CastPlaybackState.playing ||
    state == CastPlaybackState.loading ||
    (state == CastPlaybackState.buffering && (receiverActive ?? true));
