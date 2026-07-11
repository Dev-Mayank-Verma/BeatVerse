import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/track.dart';
import '../services/audio_handler.dart';

enum RepeatMode { off, all, one }

/// Reactive playback state + transport controls consumed by the UI.
/// All audio operations delegate to BeatVerseAudioHandler so audio_service
/// drives the OS notification/lock-screen player.
class PlayerProvider extends ChangeNotifier {
  final BeatVerseAudioHandler _handler;

  Track?        current;
  List<Track>   queue      = [];
  int           queueIndex = -1;
  bool          isPlaying  = false;
  bool          isBuffering= false;
  Duration      position   = Duration.zero;
  Duration      total      = Duration.zero;
  bool          shuffle    = false;
  RepeatMode    repeat     = RepeatMode.off;
  double        playbackRate = 1.0;
  String?       lastError;

  PlayerProvider(this._handler) {
    // Wire notification prev/next → our queue logic
    _handler.onNotificationNext = next;
    _handler.onNotificationPrev = previous;

    _handler.player.playerStateStream.listen((s) {
      isPlaying   = s.playing;
      isBuffering = s.processingState == ProcessingState.loading ||
                   s.processingState == ProcessingState.buffering;
      if (s.processingState == ProcessingState.completed) _onCompleted();
      notifyListeners();
    });
    _handler.player.positionStream.listen((p) { position = p; notifyListeners(); });
    _handler.player.durationStream.listen((d) { total = d ?? Duration.zero; notifyListeners(); });
  }

  void _onCompleted() {
    if (repeat == RepeatMode.one) { seek(Duration.zero); _handler.play(); return; }
    next();
  }

  Future<void> playTrack(Track track, {List<Track>? queueList}) async {
    current    = track;
    queue      = queueList ?? [track];
    queueIndex = queue.indexWhere((t) => t.id == track.id);
    if (queueIndex == -1) { queue = [track, ...queue]; queueIndex = 0; }
    lastError  = null;
    isBuffering= true;
    notifyListeners();

    await _handler.playTrack(track);

    // Check for error after the handler returns
    final ps = _handler.player.processingState;
    if (ps == ProcessingState.idle && !_handler.player.playing) {
      lastError = 'Could not play — no stream URL for this track';
    }
    isBuffering = false;
    notifyListeners();
  }

  void togglePlay()   => isPlaying ? _handler.pause() : _handler.play();
  void pause()        => _handler.pause();
  void toggleShuffle(){ shuffle = !shuffle; notifyListeners(); }

  void cycleRepeat() {
    repeat = RepeatMode.values[(repeat.index + 1) % RepeatMode.values.length];
    notifyListeners();
  }

  Future<void> setPlaybackRate(double rate) async {
    playbackRate = rate;
    await _handler.setSpeed(rate);
    notifyListeners();
  }

  void addToQueue(Track t) { queue = [...queue, t]; notifyListeners(); }

  void clearQueue() {
    queue      = current != null ? [current!] : [];
    queueIndex = current != null ? 0 : -1;
    notifyListeners();
  }

  void removeFromQueue(int i) {
    if (i < 0 || i >= queue.length) return;
    queue = [...queue]..removeAt(i);
    if (i < queueIndex) queueIndex--;
    notifyListeners();
  }

  Future<void> next() async {
    if (queue.isEmpty || queueIndex == -1) return;
    if (shuffle && queue.length > 1) {
      final r = Random();
      int ni;
      do { ni = r.nextInt(queue.length); } while (ni == queueIndex);
      await playTrack(queue[ni], queueList: queue);
      return;
    }
    final ni = queueIndex + 1;
    if (ni >= queue.length) {
      if (repeat == RepeatMode.all) await playTrack(queue[0], queueList: queue);
      return;
    }
    await playTrack(queue[ni], queueList: queue);
  }

  Future<void> previous() async {
    if (position.inSeconds > 3) { await seek(Duration.zero); return; }
    if (queue.isEmpty || queueIndex <= 0) return;
    await playTrack(queue[queueIndex - 1], queueList: queue);
  }

  Future<void> stop() async {
    await _handler.stop();
    current = null; queue = []; queueIndex = -1;
    notifyListeners();
  }

  Future<void> seek(Duration to) => _handler.seek(to);

  @override
  void dispose() { _handler.player.dispose(); super.dispose(); }
}
