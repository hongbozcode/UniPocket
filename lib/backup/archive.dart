import 'dart:convert';

import 'package:flutter/foundation.dart';

const backupFileLimit = 50 * 1024 * 1024;

Future<Uint8List> encodeBackup(Map<String, Object?> data) => compute((value) {
  final bytes = Uint8List.fromList(utf8.encode(jsonEncode(value)));
  if (bytes.length > backupFileLimit) {
    throw const FormatException('完整备份超过 50 MB，暂时无法导出');
  }
  return bytes;
}, data);

Future<Map<String, dynamic>> decodeBackup(Uint8List bytes) async {
  if (bytes.isEmpty || bytes.length > backupFileLimit) {
    throw const FormatException('备份为空或超过 50 MB，请选择完整的 UniPocket 备份');
  }
  try {
    return await compute((value) {
      final data = jsonDecode(utf8.decode(value)) as Map<String, dynamic>;
      if (data['format'] != 'unipocket-backup' || data['version'] != 1) {
        throw const FormatException('无法识别备份版本，请使用兼容的 UniPocket 备份');
      }
      DateTime.parse(data['createdAt'] as String);
      return data;
    }, bytes);
  } catch (_) {
    throw const FormatException('文件不是完整、可识别的 UniPocket 备份');
  }
}

/// Only the planner creates a preview after validation. Retains the exact file
/// contents so changing a document after confirmation cannot change the restore.
class BackupPreview {
  BackupPreview({
    required this.createdAt,
    required this.summary,
    required Future<void> Function() restore,
  }) : _restore = restore; // ignore: prefer_initializing_formals
  final DateTime createdAt;
  final String summary;
  final Future<void> Function() _restore;
  Future<void> restore({required bool confirmOverwrite}) async {
    if (!confirmOverwrite) return;
    await _restore();
  }
}
