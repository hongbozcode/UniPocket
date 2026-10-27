import 'package:flutter/services.dart';

class SchoolFile {
  const SchoolFile(this.name, this.bytes);
  final String name;
  final Uint8List bytes;
}

/// Android's document picker grants access only to the selected document.
Future<SchoolFile?> pickSchoolFile() async {
  final result = await const MethodChannel('unipocket/school-file')
      .invokeMapMethod<String, dynamic>('pick');
  return result == null
      ? null
      : SchoolFile(result['name'] as String, result['bytes'] as Uint8List);
}
