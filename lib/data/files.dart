import 'dart:io';

Future<File> moveFile(File sourceFile, String newPath) async {
  try {
    return await sourceFile.rename(newPath);
  } on FileSystemException catch (_) {
    final newFile = await sourceFile.copy(newPath);
    await sourceFile.delete();
    return newFile;
  }
}
