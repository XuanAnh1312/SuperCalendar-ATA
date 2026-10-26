import 'package:flutter/services.dart';

/// Sets the phone wallpaper to the image exported by Edit Your Screen
/// (FR-04, "Set Wallpaper").
abstract class WallpaperService {
  /// The service in use; tests swap in [FakeWallpaperService].
  static WallpaperService instance = PlatformWallpaperService();

  /// Sets [png] on the lock screen when [lockScreen] is true, otherwise on
  /// the home screen. Resolves to false when the phone refuses.
  Future<bool> setWallpaper(Uint8List png, {required bool lockScreen});
}

/// Android `WallpaperManager` over the `supercalendar/wallpaper` channel.
///
/// Method `setWallpaper`:
///   bytes  Uint8List  PNG image
///   target String     "lock" or "home"
///   → bool            true when the wallpaper was set
class PlatformWallpaperService implements WallpaperService {
  static const _channel = MethodChannel('supercalendar/wallpaper');

  @override
  Future<bool> setWallpaper(Uint8List png, {required bool lockScreen}) async {
    try {
      final ok = await _channel.invokeMethod<bool>('setWallpaper', {
        'bytes': png,
        'target': lockScreen ? 'lock' : 'home',
      });
      return ok ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      // No native side (tests, desktop): report it as not set.
      return false;
    }
  }
}

/// Records calls instead of touching the phone.
class FakeWallpaperService implements WallpaperService {
  FakeWallpaperService({this.result = true});

  final bool result;
  final calls = <bool>[];

  @override
  Future<bool> setWallpaper(Uint8List png, {required bool lockScreen}) async {
    calls.add(lockScreen);
    return result;
  }
}
