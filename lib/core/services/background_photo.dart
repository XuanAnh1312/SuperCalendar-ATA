import 'package:flutter/painting.dart';

import 'background_photo_native.dart'
    if (dart.library.js_interop) 'background_photo_web.dart'
    as platform;

export 'background_photo_native.dart'
    if (dart.library.js_interop) 'background_photo_web.dart'
    show storeBackgroundPhoto, deleteBackgroundPhoto;

/// Web photos are embedded in the saved layout, rather than temporary blob URLs.
ImageProvider backgroundPhotoProvider(String path) {
  if (path.startsWith('data:')) {
    return MemoryImage(UriData.parse(path).contentAsBytes());
  }
  return platform.backgroundPhotoProvider(path);
}
