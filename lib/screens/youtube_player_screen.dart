import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/track.dart';
import '../providers/library_provider.dart';
import '../theme/app_theme.dart';

class YoutubePlayerScreen extends StatefulWidget {
  final Track       track;
  final List<Track> queue;
  final int         initialIndex;
  const YoutubePlayerScreen({
    super.key,
    required this.track,
    required this.queue,
    required this.initialIndex,
  });
  @override State<YoutubePlayerScreen> createState() => _State();
}

class _State extends State<YoutubePlayerScreen>
    with SingleTickerProviderStateMixin {
  late YoutubePlayerController _yt;
  late Track _current;
  late int   _idx;
  bool _showVideo = false; // false = album art (Spotify style), true = video
  late AnimationController _animCtrl;
  late Animation<double>   _scaleAnim;

  @override
  void initState() {
    super.initState();
    _current = widget.track;
    _idx     = widget.initialIndex;
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _initYT(_current.videoId);
    context.read<LibraryProvider>().addRecent(_current);
    _animCtrl.forward();
  }

  void _initYT(String id) {
    _yt = YoutubePlayerController(
      initialVideoId: id,
      flags: const YoutubePlayerFlags(
        autoPlay: true, mute: false,
        disableDragSeek: false, loop: false,
        hideControls: true, enableCaption: false,
      ),
    )..addListener(_ytListener);
  }

  void _ytListener() {
    if (_yt.value.playerState == PlayerState.ended) _next();
    if (mounted) setState(() {});
  }

  void _loadTrack(Track t, int i) {
    _current = t; _idx = i;
    _yt.load(t.videoId);
    context.read<LibraryProvider>().addRecent(t);
    _animCtrl.reset(); _animCtrl.forward();
    setState(() {});
  }

  void _next() {
    if (_idx + 1 < widget.queue.length) _loadTrack(widget.queue[_idx + 1], _idx + 1);
  }

  void _prev() {
    if (_idx > 0) _loadTrack(widget.queue[_idx - 1], _idx - 1);
  }

  bool get _playing => _yt.value.playerState == PlayerState.playing;

  @override
  void dispose() {
    _yt.removeListener(_ytListener);
    _yt.dispose();
    _animCtrl.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final liked = context.watch<LibraryProvider>().isLiked(_current.id);

    return YoutubePlayerBuilder(
      onExitFullScreen: () =>
          SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
      player: YoutubePlayer(
        controller: _yt,
        showVideoProgressIndicator: false,
      ),
      builder: (ctx, ytWidget) => Scaffold(
        backgroundColor: AppColors.background,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF404040), AppColors.background],
            ),
          ),
          child: SafeArea(
            child: Column(children: [
              // ── Top bar ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Row(children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down, size: 28),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                  Expanded(
                    child: Column(children: [
                      const Text('PLAYING FROM BEATVERSE',
                          style: TextStyle(fontSize: 10, letterSpacing: 1.5,
                              color: AppColors.muted, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(_current.artist, maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13,
                              fontWeight: FontWeight.w700)),
                    ]),
                  ),
                  IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
                ]),
              ),

              const SizedBox(height: 16),

              // ── Album art / Video toggle ─────────────────────────────
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showVideo = !_showVideo),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _showVideo
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: ytWidget)
                        : ScaleTransition(
                            scale: _scaleAnim,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: CachedNetworkImage(
                                  imageUrl: _current.thumbnail,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Container(
                                    color: AppColors.card,
                                    child: const Icon(Icons.music_note,
                                        size: 64, color: AppColors.muted),
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ),

              // ── Info + like ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
                child: Row(children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_current.title, maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 22,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(_current.artist, maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.muted,
                              fontSize: 14)),
                    ],
                  )),
                  IconButton(
                    icon: Icon(
                      liked ? Icons.favorite : Icons.favorite_border,
                      color: liked ? AppColors.primary : AppColors.foreground,
                      size: 26,
                    ),
                    onPressed: () =>
                        context.read<LibraryProvider>().toggleLike(_current),
                  ),
                ]),
              ),

              // ── Progress bar (YouTube controls via listener) ─────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: SliderComponentShape.noOverlay,
                    activeTrackColor: AppColors.foreground,
                    inactiveTrackColor: AppColors.muted.withOpacity(0.4),
                    thumbColor: AppColors.foreground,
                  ),
                  child: Slider(
                    value: (_yt.value.position.inSeconds /
                        ((_yt.value.metaData.duration.inSeconds > 0)
                            ? _yt.value.metaData.duration.inSeconds
                            : 1)).clamp(0.0, 1.0),
                    onChanged: (v) {
                      final target = Duration(seconds:
                          (v * _yt.value.metaData.duration.inSeconds).round());
                      _yt.seekTo(target);
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_fmt(_yt.value.position),
                        style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                    Text(_fmt(_yt.value.metaData.duration),
                        style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                  ],
                ),
              ),

              // ── Transport controls ───────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shuffle_rounded, size: 22),
                      color: AppColors.muted, onPressed: () {},
                    ),
                    IconButton(
                      iconSize: 36,
                      icon: const Icon(Icons.skip_previous_rounded),
                      color: _idx > 0 ? AppColors.foreground : AppColors.muted,
                      onPressed: _idx > 0 ? _prev : null,
                    ),
                    GestureDetector(
                      onTap: () {
                        _playing ? _yt.pause() : _yt.play();
                        setState(() {});
                      },
                      child: Container(
                        width: 64, height: 64,
                        decoration: const BoxDecoration(
                          color: AppColors.foreground,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: AppColors.background, size: 36,
                        ),
                      ),
                    ),
                    IconButton(
                      iconSize: 36,
                      icon: const Icon(Icons.skip_next_rounded),
                      color: _idx < widget.queue.length - 1
                          ? AppColors.foreground : AppColors.muted,
                      onPressed: _idx < widget.queue.length - 1 ? _next : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.repeat_rounded, size: 22),
                      color: AppColors.muted, onPressed: () {},
                    ),
                  ],
                ),
              ),

              // ── Bottom actions ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.devices, size: 20, color: AppColors.muted),
                      onPressed: () {},
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _showVideo = !_showVideo),
                      child: Text(
                        _showVideo ? 'Show art' : 'Show video',
                        style: const TextStyle(fontSize: 12,
                            color: AppColors.muted,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.muted),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.queue_music, size: 20, color: AppColors.muted),
                      onPressed: () => _showQueueSheet(ctx),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  void _showQueueSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Column(children: [
        Container(margin: const EdgeInsets.all(8),
            width: 36, height: 4,
            decoration: BoxDecoration(color: AppColors.muted,
                borderRadius: BorderRadius.circular(2))),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Align(alignment: Alignment.centerLeft,
              child: Text('Next in queue',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: widget.queue.length,
            itemBuilder: (_, i) {
              final t = widget.queue[i];
              final active = i == _idx;
              return ListTile(
                tileColor: active ? AppColors.primary.withOpacity(0.1) : null,
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(imageUrl: t.thumbnail,
                      width: 40, height: 40, fit: BoxFit.cover),
                ),
                title: Text(t.title, maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: active ? AppColors.primary : AppColors.foreground)),
                subtitle: Text(t.artist, maxLines: 1,
                    style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                trailing: active
                    ? const Icon(Icons.equalizer, color: AppColors.primary, size: 18)
                    : null,
                onTap: () { Navigator.pop(ctx); _loadTrack(t, i); },
              );
            },
          ),
        ),
      ]),
    );
  }
}
