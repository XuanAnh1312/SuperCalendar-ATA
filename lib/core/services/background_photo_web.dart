import 'package:flutter/painting.dart';
import 'package:image_picker/image_picker.dart';

Future<String> storeBackgroundPhoto(XFile photo, String layoutId) async =>
    Uri.dataFromBytes(
      await photo.readAsBytes(),
      mimeType: photo.mimeType ?? 'application/octet-stream',
    ).toString();

Future<void> deleteBackgroundPhoto(String path) async {}

ImageProvider backgroundPhotoProvider(String path) => NetworkImage(path);
