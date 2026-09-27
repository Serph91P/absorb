/// Receiver-state semantics for sender controls and sleep-timer liveness.
///
/// [CastPlaybackState.playing] remains the strict state for listening statistics.
/// A receiver which reports [CastPlaybackState.buffering] can nevertheless keep
/// advancing its position, so controls and the sleep timer use these separate
/// policy functions instead.
enum CastPlaybackState { idle, loading, playing, paused, buffering }

/// Whether the receiver is active enough for the sleep timer to count down.
bool isCastReceiverActive(CastPlaybackState state) =>
    state == CastPlaybackState.playing || state == CastPlaybackState.buffering;

/// Whether a play/pause toggle must send pause rather than play.
bool shouldPauseCastOnToggle(CastPlaybackState state) =>
    state == CastPlaybackState.playing ||
    state == CastPlaybackState.buffering ||
    state == CastPlaybackState.loading;
