import 'package:flutter/material.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/services/auto_wallpaper_service.dart';
import 'package:flutter_application/core/utils/date_formatter.dart';
import 'package:flutter_application/core/utils/strings.dart';

class DailyWallpaperSettings extends StatefulWidget {
  const DailyWallpaperSettings({super.key});
  @override
  State<DailyWallpaperSettings> createState() => _DailyWallpaperSettingsState();
}

class _DailyWallpaperSettingsState extends State<DailyWallpaperSettings>
    with WidgetsBindingObserver {
  DailyWallpaperStatus? _status;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    try {
      final status = await AutoWallpaperService.status();
      if (mounted) setState(() => _status = status);
    } catch (_) {
      if (mounted)
        setState(() => _error = tr('Could not load daily wallpaper settings.'));
    }
  }

  Future<void> _change(bool enabled) async {
    if (_busy) return;
    if (enabled && _status?.hasDesign != true) {
      setState(
        () => _error = tr(
          'Set a lock screen wallpaper in Edit Your Screen first.',
        ),
      );
      return;
    }
    if (enabled) {
      final accepted = await showDialog<bool>(
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
      if (accepted != true) return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AutoWallpaperService.setEnabled(enabled);
      await _load();
    } catch (_) {
      if (mounted)
        setState(
          () => _error = tr(
            'Could not configure daily wallpaper. Try again in Lock Screen settings.',
          ),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!supportsDailyWallpaper) return const SizedBox.shrink();
    final app = AppScope.of(context);
    final status = _status;
    final updatedAt = status?.updatedAt;
    final revision = status?.contentRevision;
    final outdated =
        updatedAt != null &&
        status?.error != 'wallpaper_changed' &&
        (!sameDay(DateTime.fromMillisecondsSinceEpoch(updatedAt), app.today) ||
            (revision != null &&
                revision != AutoWallpaperService.contentRevision(app)));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  tr('Daily lock screen wallpaper'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Switch(
                value: _status?.enabled ?? false,
                onChanged: _busy || _status == null ? null : _change,
              ),
            ],
          ),
          Text(
            tr(dailyWallpaperExplanation),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (_status?.hasDesign == true)
            TextButton(
              onPressed: _busy
                  ? null
                  : () async {
                      setState(() {
                        _busy = true;
                        _error = null;
                      });
                      try {
                        final png =
                            await AutoWallpaperService.previewTomorrow();
                        if (mounted)
                          await showDialog<void>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(tr("Tomorrow's lock screen preview")),
                              content: SizedBox(
                                width: 280,
                                child: Image.memory(png, fit: BoxFit.contain),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(tr('Close')),
                                ),
                              ],
                            ),
                          );
                      } catch (_) {
                        if (mounted)
                          setState(
                            () => _error = tr(
                              'Could not create the preview. Please try again.',
                            ),
                          );
                      } finally {
                        if (mounted) setState(() => _busy = false);
                      }
                    },
              child: Text(tr('Preview tomorrow')),
            ),
          if (_busy) const LinearProgressIndicator(),
          if (_status?.enabled == true)
            TextButton(
              onPressed: _busy
                  ? null
                  : () async {
                      setState(() {
                        _busy = true;
                        _error = null;
                      });
                      try {
                        await AutoWallpaperService.updateNow();
                        await _load();
                        if (mounted)
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                tr(
                                  'Wallpaper update queued. Android may delay background work.',
                                ),
                              ),
                            ),
                          );
                      } catch (_) {
                        if (mounted)
                          setState(
                            () => _error = tr(
                              'Could not queue wallpaper update.',
                            ),
                          );
                      } finally {
                        if (mounted) setState(() => _busy = false);
                      }
                    },
              child: Text(tr('Update wallpaper now')),
            ),
          if (_status?.updatedAt case final int time)
            Text(
              '${tr('Last wallpaper update')}: ${DateTime.fromMillisecondsSinceEpoch(time).toLocal()}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (outdated)
            Text(
              tr(
                'Planner data has changed since you applied the lock screen wallpaper.',
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (_error != null || _status?.error != null)
            Text(
              _error ??
                  tr(
                    _status?.error == 'wallpaper_changed'
                        ? 'You changed the wallpaper outside SuperCalendar. Auto-update was turned off.'
                        : 'The last wallpaper update failed. Your current wallpaper was kept.',
                  ),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    );
  }
}
