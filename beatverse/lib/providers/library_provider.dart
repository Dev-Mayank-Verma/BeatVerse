import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/track.dart';
import '../models/playlist.dart';

/// Ports src/contexts/LibraryContext.tsx — liked songs, recently played,
/// and user playlists. Persisted locally with SharedPreferences (the
/// direct equivalent of the web app's localStorage[KEY] approach).
class LibraryProvider extends ChangeNotifier {
  static const _key = 'beatverse:library:v1';

  List<Track> liked = [];
  List<Track> recent = [];
  List<Playlist> playlists = [];

  bool _ready = false;
  bool get ready => _ready;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        liked = (data['liked'] as List<dynamic>? ?? [])
            .map((t) => Track.fromJson(t as Map<String, dynamic>))
            .toList();
        recent = (data['recent'] as List<dynamic>? ?? [])
            .map((t) => Track.fromJson(t as Map<String, dynamic>))
            .toList();
        playlists = (data['playlists'] as List<dynamic>? ?? [])
            .map((p) => Playlist.fromJson(p as Map<String, dynamic>))
            .toList();
      } catch (_) {
        // Corrupt/old data — start fresh rather than crash.
      }
    }
    _ready = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        'liked': liked.map((t) => t.toJson()).toList(),
        'recent': recent.map((t) => t.toJson()).toList(),
        'playlists': playlists.map((p) => p.toJson()).toList(),
      }),
    );
  }

  bool isLiked(String id) => liked.any((t) => t.id == id);

  void toggleLike(Track track) {
    liked = isLiked(track.id)
        ? liked.where((t) => t.id != track.id).toList()
        : [track, ...liked];
    notifyListeners();
    _persist();
  }

  void addRecent(Track track) {
    recent =
        [track, ...recent.where((t) => t.id != track.id)].take(30).toList();
    notifyListeners();
    _persist();
  }

  Playlist createPlaylist(String name) {
    final pl = Playlist(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
    );
    playlists = [pl, ...playlists];
    notifyListeners();
    _persist();
    return pl;
  }

  void deletePlaylist(String id) {
    playlists = playlists.where((p) => p.id != id).toList();
    notifyListeners();
    _persist();
  }

  void renamePlaylist(String id, String name) {
    playlists =
        playlists.map((p) => p.id == id ? p.copyWith(name: name) : p).toList();
    notifyListeners();
    _persist();
  }

  void addToPlaylist(String id, Track track) {
    playlists = playlists.map((p) {
      if (p.id != id || p.tracks.any((t) => t.id == track.id)) return p;
      return p.copyWith(
        tracks: [...p.tracks, track],
        cover: p.cover ?? track.thumbnail,
      );
    }).toList();
    notifyListeners();
    _persist();
  }

  void removeFromPlaylist(String id, String trackId) {
    playlists = playlists.map((p) {
      if (p.id != id) return p;
      return p.copyWith(tracks: p.tracks.where((t) => t.id != trackId).toList());
    }).toList();
    notifyListeners();
    _persist();
  }
}
