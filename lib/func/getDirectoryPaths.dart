import 'dart:io';

Future<List<String>> getDirectoryPaths(String dirPath) async {
  final dir = Directory(dirPath);
  final files = <String>[];

  await for (final entity in dir.list(recursive: true)) {
    if (entity is File) files.add(entity.path);
  }

  return files;
}