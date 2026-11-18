import 'package:device_frame/device_frame.dart';
import 'package:device_info_plus/device_info_plus.dart' as hardware;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

@immutable
class DeviceFrameIdentity {
  const DeviceFrameIdentity({
    required this.platform,
    required this.model,
    this.manufacturer = '',
  });

  final TargetPlatform platform;
  final String model;
  final String manufacturer;
}

/// Detects hardware once. Display geometry is supplied by the real Flutter view,
/// never by the simulated MediaQuery inside DeviceFrame.
class DeviceFrameService {
  DeviceFrameService({
    Future<DeviceFrameIdentity> Function()? detector,
    this.isWeb = kIsWeb,
  }) : _detector = detector ?? _detect;

  static DeviceFrameService instance = DeviceFrameService();

  final bool isWeb;
  final Future<DeviceFrameIdentity> Function() _detector;
  Future<void>? _initialization;
  DeviceFrameIdentity? _identity;
  DeviceInfo? _catalogFrame;
  final _genericFrames = <(TargetPlatform, Size), DeviceInfo>{};

  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    if (isWeb) return;
    try {
      _identity = await _detector().timeout(const Duration(seconds: 2));
      _catalogFrame = _match(_identity!);
    } catch (_) {
      // Missing plugin, unsupported platform, or an unavailable hardware API:
      // the editor still works with the package's generic frame.
      _identity = DeviceFrameIdentity(
        platform: defaultTargetPlatform,
        model: '',
      );
    }
  }

  DeviceInfo? frameFor(Size displaySize) {
    if (isWeb) return null;
    final platform = _identity?.platform ?? defaultTargetPlatform;
    if (platform != TargetPlatform.iOS && platform != TargetPlatform.android) {
      return null;
    }
    if (_catalogFrame != null) return _catalogFrame;
    final valid =
        displaySize.width.isFinite &&
        displaySize.height.isFinite &&
        displaySize.width > 0 &&
        displaySize.height > 0;
    final size = valid ? displaySize : const Size(390, 844);
    return _genericFrames.putIfAbsent((platform, size), () {
      return DeviceInfo.genericPhone(
        platform: platform,
        id: 'supercalendar-${platform.name}-${size.width}-${size.height}',
        name: platform == TargetPlatform.iOS ? 'iPhone' : 'Android phone',
        screenSize: Size(390, 390 * size.height / size.width),
      );
    });
  }

  static Future<DeviceFrameIdentity> _detect() async {
    final plugin = hardware.DeviceInfoPlugin();
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final info = await plugin.iosInfo;
      return DeviceFrameIdentity(
        platform: TargetPlatform.iOS,
        model: info.utsname.machine,
      );
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      final info = await plugin.androidInfo;
      return DeviceFrameIdentity(
        platform: TargetPlatform.android,
        model: info.model,
        manufacturer: info.manufacturer,
      );
    }
    return DeviceFrameIdentity(platform: defaultTargetPlatform, model: '');
  }

  static DeviceInfo? _match(DeviceFrameIdentity device) {
    if (device.platform == TargetPlatform.iOS) {
      final ios = Devices.ios;
      final exact = <String, DeviceInfo>{
        'iPhone12,5': ios.iPhone11ProMax,
        'iPhone12,8': ios.iPhoneSE,
        'iPhone13,1': ios.iPhone12Mini,
        'iPhone13,2': ios.iPhone12,
        'iPhone13,4': ios.iPhone12ProMax,
        'iPhone14,3': ios.iPhone13ProMax,
        'iPhone14,4': ios.iPhone13Mini,
        'iPhone14,5': ios.iPhone13,
        'iPhone14,6': ios.iPhoneSE,
        'iPhone16,1': ios.iPhone15Pro,
        'iPhone16,2': ios.iPhone15ProMax,
        'iPhone17,1': ios.iPhone16Pro,
        'iPhone17,2': ios.iPhone16ProMax,
        'iPhone17,3': ios.iPhone16,
        'iPhone17,4': ios.iPhone16Plus,
      };
      final frame = exact[device.model];
      if (frame != null) return frame;
      // Models absent from the catalog use the closest available screen family.
      final related = <String, DeviceInfo>{
        'iPhone13,3': ios.iPhone12,
        'iPhone14,2': ios.iPhone13,
        'iPhone14,7': ios.iPhone13,
        'iPhone14,8': ios.iPhone13ProMax,
        'iPhone15,2': ios.iPhone15Pro,
        'iPhone15,3': ios.iPhone15ProMax,
        'iPhone15,4': ios.iPhone15Pro,
        'iPhone15,5': ios.iPhone15ProMax,
        'iPhone17,5': ios.iPhone13, // 16e has a notch, not Dynamic Island.
      };
      return related[device.model];
    }
    if (device.platform != TargetPlatform.android) return null;
    final android = Devices.android;
    final model = device.model.trim().toLowerCase();
    final maker = device.manufacturer.trim().toLowerCase();
    if (maker == 'samsung' || model.startsWith('sm-')) {
      final exactPrefixes = <String, DeviceInfo>{
        'sm-s931': android.samsungGalaxyS25,
        'sm-g980': android.samsungGalaxyS20,
        'sm-g981': android.samsungGalaxyS20,
        'sm-n980': android.samsungGalaxyNote20,
        'sm-n981': android.samsungGalaxyNote20,
        'sm-n985': android.samsungGalaxyNote20Ultra,
        'sm-n986': android.samsungGalaxyNote20Ultra,
        'sm-a505': android.samsungGalaxyA50,
      };
      for (final entry in exactPrefixes.entries) {
        if (model.startsWith(entry.key)) return entry.value;
      }
      if (model == 'galaxy s25') return android.samsungGalaxyS25;
      if (model == 'galaxy s20') return android.samsungGalaxyS20;
      if (model.startsWith('sm-s9') ||
          model.startsWith('sm-g99') ||
          model.startsWith('sm-g98') ||
          model.startsWith('galaxy s')) {
        return android.samsungGalaxyS25;
      }
      if (model.startsWith('galaxy note')) {
        return android.samsungGalaxyNote20Ultra;
      }
    }
    if ((maker == 'google' || maker.isEmpty) && model.startsWith('pixel')) {
      if (model == 'pixel 9 pro xl') return android.googlePixel9ProXL;
      return android.googlePixel9;
    }
    if (model == 'oneplus 8 pro' || RegExp(r'^in202[0135]$').hasMatch(model)) {
      return android.onePlus8Pro;
    }
    if (model == 'xperia 1 ii' || model == 'xq-at51' || model == 'xq-at52') {
      return android.sonyXperia1II;
    }
    return null;
  }
}
