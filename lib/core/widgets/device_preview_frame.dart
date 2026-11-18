import 'dart:math' as math;

import 'package:device_frame/device_frame.dart';
import 'package:flutter/material.dart';

/// Visual-only frame. The child keeps its original layout dimensions, theme
/// and MediaQuery so editor hit testing and PNG export remain independent.
class DevicePreviewFrame extends StatelessWidget {
  const DevicePreviewFrame({
    super.key,
    required this.device,
    required this.screenSize,
    required this.child,
  });

  final DeviceInfo? device;
  final Size screenSize;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final info = device;
    Widget preview = SizedBox.fromSize(size: screenSize, child: child);
    var outerSize = screenSize;
    if (info != null) {
      final bounds = info.screenPath.getBounds().size;
      final rotate =
          info.canRotate &&
          (screenSize.width > screenSize.height) !=
              (bounds.width > bounds.height);
      // Some catalog entries (notably iPhone 12) have screenSize metadata
      // inconsistent with their own screen path. Match that path to avoid the
      // package's internal FittedBox letterboxing or distorting the canvas.
      final previewInfo = info.copyWith(screenSize: bounds / info.pixelRatio);
      final screenBounds = rotate ? Size(bounds.height, bounds.width) : bounds;
      final nativeFrame = rotate
          ? Size(info.frameSize.height, info.frameSize.width)
          : info.frameSize;
      // Scale the catalog art to the real display aspect ratio, including for
      // a same-series fallback. The inverse screen scaling preserves the child.
      outerSize = Size(
        nativeFrame.width * screenSize.width / screenBounds.width,
        nativeFrame.height * screenSize.height / screenBounds.height,
      );
      preview = SizedBox.fromSize(
        size: outerSize,
        child: FittedBox(
          fit: BoxFit.fill,
          child: SizedBox.fromSize(
            size: nativeFrame,
            child: DeviceFrame(
              device: previewInfo,
              orientation: rotate
                  ? Orientation.landscape
                  : Orientation.portrait,
              screen: FittedBox(
                fit: BoxFit.fill,
                child: MediaQuery(
                  data: MediaQuery.of(context),
                  child: Theme(data: Theme.of(context), child: preview),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.min(screenSize.width, constraints.maxWidth);
        return Center(
          child: SizedBox(
            width: width,
            height: width * outerSize.height / outerSize.width,
            child: FittedBox(child: preview),
          ),
        );
      },
    );
  }
}
