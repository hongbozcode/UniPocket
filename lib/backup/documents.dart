import 'package:flutter/services.dart';

class BackupDocument {
  const BackupDocument(this.name, this.bytes);
  final String name;
  final Uint8List bytes;
}

class BackupDocuments {
  const BackupDocuments();
  static const _channel = MethodChannel('unipocket/backup-file');

  Future<bool> save(Uint8List bytes, String name) async =>
      await _channel.invokeMethod<bool>('save', {
        'bytes': bytes,
        'name': name,
      }) ??
      false;

  Future<BackupDocument?> pick() async {
    final result = await _channel.invokeMapMethod<String, dynamic>('pick');
    return result == null
        ? null
        : BackupDocument(
            result['name'] as String,
            result['bytes'] as Uint8List,
          );
  }
}
