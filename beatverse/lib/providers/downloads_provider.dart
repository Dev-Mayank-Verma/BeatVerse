import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/download_record.dart';
import '../models/track.dart';

/// Ports src/contexts/DownloadsContext.tsx + downloads-db.ts — save a
/// track for offline playback, list/remove saved tracks.
///
/// The original saves whatever `getDownloadUrl()` returns, which is the
/// Supabase edge function's /download route — the same YouTube-extraction
/// mechanism flagged elsewhere in this project's doc comments, except here it
/// writes a **permanent local file**, which is an even more direct case
/// of reproducing copyrighted audio without authorization than streaming
/// is. So this provider saves the same legal iTunes preview clip
/// PlayerProvider streams, to the app's private storage (not the phone's
/// public gallery/Downloads folder — that would let the saved file be
/// freely copied/shared outside the app). Point `resolveItunesPreview` at
/// a licensed source later and offline saving upgrades automatically.
class DownloadsProvider extends ChangeNotifier {
  static const _key = 'beatverse:downloads:v1';

  List<DownloadRecord> downloads = [];
  final Map<String, int> inProgress = {}; // trackId -> percent
  bool ready = false;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        downloads = list
            .map((d) => DownloadRecord.fromJson(d as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
      } catch (_) {
        downloads = [];
      }
    }
    ready = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(downloads.map((d) => d.toJson()).toList()),
    );
  }

  bool isDownloaded(String id) => downloads.any((d) => d.id == id);

  Future<void> downloadTrack(Track track) async {
    if (isDownloaded(track.id)) return;
    inProgress[track.id] = 0;
    notifyListeners();
    try {
      final url = track.streamOverride;
      if (url == null || url.isEmpty) throw Exception('No stream URL for this track');

      final req = http.Request('GET', Uri.parse(url));
      final res = await http.Client().send(req);
      if (res.statusCode != 200) throw Exception('Download failed');

      final total = res.contentLength ?? 0;
      final bytes = <int>[];
      var received = 0;
      await for (final chunk in res.stream) {
        bytes.addAll(chunk);
        received += chunk.length;
        if (total > 0) {
          inProgress[track.id] = ((received / total) * 100).round();
          notifyListeners();
        }
      }
      if (bytes.length < 1024) throw Exception('Empty file');

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/beatverse_offline_${track.id}.m4a');
      await file.writeAsBytes(bytes);

      downloads = [
        DownloadRecord(
          id: track.id,
          track: track,
          filePath: file.path,
          size: bytes.length,
          savedAt: DateTime.now().millisecondsSinceEpoch,
        ),
        ...downloads,
      ];
      await _persist();
    } finally {
      inProgress.remove(track.id);
      notifyListeners();
    }
  }

  Future<void> removeDownload(String id) async {
    DownloadRecord? rec;
    for (final d in downloads) {
      if (d.id == id) {
        rec = d;
        break;
      }
    }
    if (rec != null) {
      final f = File(rec.filePath);
      if (await f.exists()) await f.delete();
    }
    downloads = downloads.where((d) => d.id != id).toList();
    notifyListeners();
    await _persist();
  }

  int get totalBytes => downloads.fold(0, (s, d) => s + d.size);
}
