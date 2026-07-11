/// Mirrors the `Track` interface from src/lib/music-api.ts.
class Track {
  final String id; // YouTube video id, or "pod-<id>" for podcasts
  final String title;
  final String artist;
  final int duration; // seconds
  final String thumbnail;
  final String? streamOverride; // direct audio URL (used for podcasts)

  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.duration,
    required this.thumbnail,
    this.streamOverride,
  });

  factory Track.fromJson(Map<String, dynamic> json) => Track(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? 'Unknown title',
        artist: json['artist']?.toString() ?? 'Unknown artist',
        duration: (json['duration'] as num?)?.toInt() ?? 0,
        thumbnail: json['thumbnail']?.toString() ?? '',
        streamOverride: json['streamOverride']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'duration': duration,
        'thumbnail': thumbnail,
        if (streamOverride != null) 'streamOverride': streamOverride,
      };

  /// Matches formatDuration() from music-api.ts — e.g. "3:42".
  String get formattedDuration {
    if (duration <= 0) return '0:00';
    final m = duration ~/ 60;
    final s = duration % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  bool operator ==(Object other) => other is Track && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
