import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

/// One geometry shared by the editor preview and its full-screen PNG.
class WallpaperDimensions {
  WallpaperDimensions(ui.Size physicalSize) {
    if (!physicalSize.width.isFinite ||
        !physicalSize.height.isFinite ||
        physicalSize.width < 1 ||
        physicalSize.height < 1) {
      throw ArgumentError.value(physicalSize, 'physicalSize');
    }
    width = physicalSize.width.round();
    height = physicalSize.height.round();
  }

  late final int width;
  late final int height;

  double canvasHeight(double canvasWidth) => canvasWidth * height / width;

  /// Keeps rounding at fractional pixel ratios from changing PNG dimensions.
  Future<Uint8List> capture(RenderRepaintBoundary boundary) async {
    final source = await boundary.toImage(
      pixelRatio: width / boundary.size.width,
    );
    ui.Image? resized;
    try {
      var image = source;
      if (source.width != width || source.height != height) {
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        // toImage rounds up. Trim that extra fractional edge instead of
        // stretching its transparent last row/column into the wallpaper.
        canvas.drawImage(source, ui.Offset.zero, ui.Paint());
        final picture = recorder.endRecording();
        try {
          resized = await picture.toImage(width, height);
          image = resized;
        } finally {
          picture.dispose();
        }
      }
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('Could not encode wallpaper');
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } finally {
      resized?.dispose();
      source.dispose();
    }
  }
}
