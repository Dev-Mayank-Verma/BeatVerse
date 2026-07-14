class Track {
  final String id;       // yt-<videoId>
  final String title;
  final String artist;
  final int    duration;
  final String thumbnail;

  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.duration,
    required this.thumbnail,
  });

  String get videoId => id.replaceFirst('yt-', '');

  String get formattedDuration {
    if (duration <= 0) return '';
    final m = duration ~/ 60;
    final s = duration % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  factory Track.fromJson(Map<String, dynamic> j) => Track(
    id: j['id'] as String,
    title: j['title'] as String,
    artist: j['artist'] as String,
    duration: (j['duration'] as num?)?.toInt() ?? 0,
    thumbnail: j['thumbnail'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'artist': artist,
    'duration': duration, 'thumbnail': thumbnail,
  };

  @override bool operator ==(Object o) => o is Track && o.id == id;
  @override int get hashCode => id.hashCode;
}
