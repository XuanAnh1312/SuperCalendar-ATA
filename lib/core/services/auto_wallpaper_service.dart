import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/services/wallpaper_export.dart';
import 'package:flutter_application/core/utils/date_formatter.dart';
import 'package:flutter_application/core/utils/strings.dart';
import 'package:flutter_application/features/dashboard/domain/screen_layout.dart';

bool get supportsDailyWallpaper =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
const dailyWallpaperExplanation =
    'Update the lock screen after midnight using your chosen design. Background work may use extra battery and Android may delay updates. You can turn this off anytime. This does not update the Home wallpaper.';

class DailyWallpaperStatus {
  const DailyWallpaperStatus({
    this.enabled = false,
    this.asked = false,
    this.hasDesign = false,
    this.updatedAt,
    this.contentRevision,
    this.error,
  });
  factory DailyWallpaperStatus.fromMap(Map<dynamic, dynamic> m) =>
      DailyWallpaperStatus(
        enabled: m['enabled'] == true,
        asked: m['asked'] == true,
        hasDesign: m['hasDesign'] == true,
        updatedAt: (m['updatedAt'] as num?)?.toInt(),
        contentRevision: (m['contentRevision'] as num?)?.toInt(),
        error: m['error'] as String?,
      );
  final bool enabled, asked, hasDesign;
  final int? updatedAt, contentRevision;
  final String? error;
}

class AutoWallpaperService {
  static const channel = MethodChannel('supercalendar/auto_wallpaper');
  static Future<DailyWallpaperStatus> status() async {
    if (!supportsDailyWallpaper) return const DailyWallpaperStatus();
    return DailyWallpaperStatus.fromMap(
      await channel.invokeMapMethod<String, dynamic>('status') ?? {},
    );
  }

  static Future<void> saveDesign(
    ScreenLayout layout,
    WallpaperDimensions dimensions, {
    int? contentRevision,
  }) async {
    if (!supportsDailyWallpaper) return;
    await channel.invokeMethod<void>('saveDesign', {
      'layout': jsonEncode(layout.toJson()),
      'width': dimensions.width,
      'height': dimensions.height,
      'contentRevision': contentRevision,
    });
  }

  /// Stable across the renderer and app isolates. Only the revision is saved
  /// in native preferences, so titles and note text stay in the planner store.
  static int contentRevision(AppState app) {
    final week = app.weekStartOf(app.today);
    final snapshot = jsonEncode([
      dateOnly(app.today).toIso8601String(),
      app.settings.lockScreenHideDetails,
      app.settings.language,
      for (var offset = 0; offset < 7; offset++)
        [
          for (final event in app.visibleCalendarEventsOn(
            DateTime(week.year, week.month, week.day + offset),
          ))
            event.toJson(),
        ],
      [for (final task in app.tasks.dashboard(app.today)) task.toJson()],
      [for (final task in app.tasks.dueOn(app.today)) task.toJson()],
      [
        for (final habit in app.habits.occurrences(app.today))
          [
            habit.toJson(),
            app.habits.isDone(habit, app.today),
            app.habits.isSkipped(habit, app.today),
          ],
      ],
      app.notes.quickText,
    ]);
    var revision = 0;
    for (final code in snapshot.codeUnits) {
      revision = (revision * 31 + code) & 0x7fffffff;
    }
    return revision;
  }

  static Future<void> setEnabled(bool enabled) =>
      channel.invokeMethod<void>('setEnabled', {'enabled': enabled});
  static Future<Uint8List> previewTomorrow() async {
    await channel.invokeMethod<void>('previewTomorrow');
    for (var attempt = 0; attempt < 90; attempt++) {
      await Future<void>.delayed(const Duration(seconds: 1));
      final png = await channel.invokeMethod<Uint8List>('previewResult');
      if (png != null) return png;
    }
    throw StateError('Android has not finished the preview yet');
  }

  static Future<void> updateNow() => channel.invokeMethod<void>('updateNow');
  static Future<void> catchUp() async {
    if (!supportsDailyWallpaper) return;
    try {
      await channel.invokeMethod<void>('catchUp');
    } on PlatformException catch (error) {
      debugPrint('Daily wallpaper: $error');
    } on MissingPluginException {
      /* Existing installs/tests without native side. */
    }
  }
}

/// Ask only after a successful manual lock wallpaper application. Dismissal
/// counts as Later. Merely exporting a PNG never grants background consent.
Future<void> offerDailyWallpaper(
  BuildContext context, {
  required ScreenLayout layout,
  required WallpaperDimensions dimensions,
  int? contentRevision,
}) async {
  if (!supportsDailyWallpaper || layout.id != ScreenLayout.lock) return;
  try {
    await AutoWallpaperService.saveDesign(
      layout,
      dimensions,
      contentRevision: contentRevision,
    );
    final status = await AutoWallpaperService.status();
    if (!context.mounted || status.asked) return;
    final enabled = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('Automatically update your lock screen?')),
        content: Text(tr(dailyWallpaperExplanation)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('Later')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr('Enable auto-update')),
          ),
        ],
      ),
    );
    await AutoWallpaperService.setEnabled(enabled == true);
  } on PlatformException catch (error) {
    if (context.mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'Could not configure daily wallpaper. Try again in Lock Screen settings.',
            ),
          ),
        ),
      );
    debugPrint('Daily wallpaper: $error');
  } on MissingPluginException {
    /* Platform capability unavailable. */
  }
}
