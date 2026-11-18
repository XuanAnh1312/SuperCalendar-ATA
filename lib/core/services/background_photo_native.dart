import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String> storeBackgroundPhoto(XFile photo, String layoutId) async {
  final directory = await getApplicationDocumentsDirectory();
  final name =
      'background_${layoutId}_${DateTime.now().microsecondsSinceEpoch}'
      '${p.extension(photo.path)}';
  final saved = await File(photo.path).copy(p.join(directory.path, name));
  return saved.path;
}

Future<void> deleteBackgroundPhoto(String path) async {
  if (path.startsWith('data:')) return;
  final directory = await getApplicationDocumentsDirectory();
  // Only clean up copies owned by the editor, never original gallery files.
  if (!p.isWithin(directory.path, path) ||
      !p.basename(path).startsWith('background_'))
    return;
  try {
    await File(path).delete();
  } on FileSystemException {
    // Already gone or unavailable; the layout itself can still be saved.
  }
}

ImageProvider backgroundPhotoProvider(String path) => FileImage(File(path));
