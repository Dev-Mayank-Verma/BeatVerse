import 'track.dart';

/// Mirrors the `ArtistResult` interface from src/lib/music-api.ts.
class ArtistResult {
  final String name;
  final String? thumbnail;
  final List<Track> topTracks;

  ArtistResult({required this.name, this.thumbnail, List<Track>? topTracks})
      : topTracks = topTracks ?? const [];

  factory ArtistResult.fromJson(String name, Map<String, dynamic> json) => ArtistResult(
        name: name,
        thumbnail: json['thumbnail'] as String?,
        topTracks: (json['topTracks'] as List<dynamic>? ?? [])
            .map((t) => Track.fromJson(t as Map<String, dynamic>))
            .toList(),
      );
}
