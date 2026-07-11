import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../models/track.dart';

/// Wraps just_audio inside audio_service's BaseAudioHandler.
///
/// This is the "Spotify notification panel" part — audio_service registers
/// this handler with Android/iOS so the OS shows a proper media notification
/// with artwork + prev/play-pause/next controls while BeatVerse plays in
/// the background, exactly like Spotify does it.
///
/// Audio source priority (first non-null wins):
///   1. Track.streamOverride — set to the Jamendo full-length MP3 URL by
///      JamendoService, or to a local file:// path for offline downloads,
///      or to a podcast episode URL.
///   2. Nothing — error state shown to the user.
///
/// The old iTunes-preview fallback is gone now that every search/trending
/// result comes from Jamendo (which always provides audio URLs).
class BeatVerseAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  AudioPlayer get player => _player;

  // Callbacks wired up by PlayerProvider so notification button taps
  // (skip-next, skip-prev) drive PlayerProvider's own queue logic.
  void Function()? onNotificationNext;
  void Function()? onNotificationPrev;

  BeatVerseAudioHandler() {
    _player.playbackEventStream.listen(_broadcastState);
    _player.durationStream.listen((d) {
      final item = mediaItem.value;
      if (item == null || d == null) return;
      mediaItem.add(item.copyWith(duration: d));
    });
  }

  // ── Entry point ────────────────────────────────────────────────────────────

  Future<void> playTrack(Track track) async {
    // Push MediaItem → OS notification gets the artwork, title, artist.
    mediaItem.add(MediaItem(
      id: track.id,
      title: track.title,
      artist: track.artist,
      artUri: track.thumbnail.isNotEmpty ? Uri.tryParse(track.thumbnail) : null,
      duration: track.duration > 0 ? Duration(seconds: track.duration) : null,
    ));

    final url = track.streamOverride;
    if (url == null || url.isEmpty) {
      playbackState.add(playbackState.value
          .copyWith(processingState: AudioProcessingState.error));
      return;
    }

    try {
      if (url.startsWith('file://')) {
        await _player.setFilePath(url.replaceFirst('file://', ''));
      } else {
        await _player.setUrl(url);
      }
      await _player.play();
    } catch (_) {
      playbackState.add(playbackState.value
          .copyWith(processingState: AudioProcessingState.error));
    }
  }

  // ── BaseAudioHandler overrides ─────────────────────────────────────────────

  @override Future<void> play()   => _player.play();
  @override Future<void> pause()  => _player.pause();
  @override Future<void> seek(Duration pos) => _player.seek(pos);
  @override Future<void> setSpeed(double s) => _player.setSpeed(s);

  @override
  Future<void> stop() async {
    await _player.stop();
    playbackState.add(playbackState.value
        .copyWith(processingState: AudioProcessingState.idle));
    await super.stop();
  }

  @override
  Future<void> skipToNext() async => onNotificationNext?.call();

  @override
  Future<void> skipToPrevious() async => onNotificationPrev?.call();

  // ── State bridge ───────────────────────────────────────────────────────────

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        playing ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.skipToNext,
        MediaAction.skipToPrevious,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle:      AudioProcessingState.idle,
        ProcessingState.loading:   AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready:     AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: playing,
      updatePosition:   _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
    ));
  }
}
