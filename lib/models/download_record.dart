import 'track.dart';

/// Mirrors the `DownloadRecord` shape from src/lib/downloads-db.ts, minus
/// the device-id field (not needed — SharedPreferences is already
/// per-device/per-install here).
class DownloadRecord {
  final String id; // track id
  final Track track; // metadata snapshot
  final String filePath; // local audio file on disk
  final int size; // bytes
  final int savedAt;

  DownloadRecord({
    required this.id,
    required this.track,
    required this.filePath,
    required this.size,
    required this.savedAt,
  });

  factory DownloadRecord.fromJson(Map<String, dynamic> json) => DownloadRecord(
        id: json['id'] as String,
        track: Track.fromJson(json['track'] as Map<String, dynamic>),
        filePath: json['filePath'] as String,
        size: json['size'] as int? ?? 0,
        savedAt: json['savedAt'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'track': track.toJson(),
        'filePath': filePath,
        'size': size,
        'savedAt': savedAt,
      };

  static String formatBytes(int b) {
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / 1024 / 1024).toStringAsFixed(1)} MB';
  }
}
