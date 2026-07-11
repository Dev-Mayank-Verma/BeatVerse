import 'track.dart';

/// Mirrors the `Playlist` interface from src/contexts/LibraryContext.tsx.
class Playlist {
  final String id;
  final String name;
  final String? cover;
  final List<Track> tracks;
  final int createdAt;

  Playlist({
    required this.id,
    required this.name,
    this.cover,
    List<Track>? tracks,
    int? createdAt,
  })  : tracks = tracks ?? const [],
        createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  factory Playlist.fromJson(Map<String, dynamic> json) => Playlist(
        id: json['id'] as String,
        name: json['name'] as String,
        cover: json['cover'] as String?,
        tracks: (json['tracks'] as List<dynamic>? ?? [])
            .map((t) => Track.fromJson(t as Map<String, dynamic>))
            .toList(),
        createdAt:
            json['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'cover': cover,
        'tracks': tracks.map((t) => t.toJson()).toList(),
        'createdAt': createdAt,
      };

  Playlist copyWith({String? name, String? cover, List<Track>? tracks}) =>
      Playlist(
        id: id,
        name: name ?? this.name,
        cover: cover ?? this.cover,
        tracks: tracks ?? this.tracks,
        createdAt: createdAt,
      );
}
