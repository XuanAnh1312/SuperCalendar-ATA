import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_application/core/data/document_store.dart';
import 'package:flutter_application/core/data/repository.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/services/planner_backup.dart';
import 'package:flutter_application/core/utils/strings.dart';
import 'package:flutter_application/core/widgets/app_widgets.dart';
import 'package:flutter_application/features/settings_screen/presentation/screens/widget_style_screen.dart';

class PlannerBackupScreen extends StatefulWidget {
  const PlannerBackupScreen({super.key});

  @override
  State<PlannerBackupScreen> createState() => _PlannerBackupScreenState();
}

class _PlannerBackupScreenState extends State<PlannerBackupScreen> {
  bool _busy = false;

  Future<void> _run(
    Future<void> Function(AppState, PlannerBackupStore) run,
  ) async {
    if (_busy) return;
    final app = AppScope.read(context);
    final store = app.store;
    if (store is! PlannerBackupStore) return;
    setState(() => _busy = true);
    try {
      await app.flush();
      await run(app, store);
    } catch (_) {
      if (mounted)
        showAppSnack(
          context,
          'Could not complete the planner backup operation',
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export() => _run((app, store) async {
    final bytes = Uint8List.fromList(
      utf8.encode(await PlannerBackup.export(store)),
    );
    if (bytes.length > PlannerBackup.maxBytes)
      throw const FormatException('Backup too large');
    if (!mounted) return;
    final file = await FilePicker.platform.saveFile(
      fileName: 'SuperCalendar-${dayKey(app.today)}.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: bytes,
    );
    if (mounted && (file != null || kIsWeb)) {
      showAppSnack(
        context,
        kIsWeb ? 'Planner backup download started' : 'Planner backup saved',
      );
    }
  });

  Future<void> _restore() => _run((app, store) async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (picked == null) return;
    final file = picked.files.single;
    if (file.size > PlannerBackup.maxBytes)
      throw const FormatException('Backup too large');
    final data = PlannerBackup.parse(await file.xFile.readAsString());
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('Restore planner backup?')),
        content: Text(
          tr(
            'Existing items will be kept. The backup only adds missing items.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr('Restore backup')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final count = await app.restorePlannerBackup(store, data);
    if (mounted)
      showAppSnack(context, trf('{n} planner items restored', {'n': count}));
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          StudioHeader(
            title: 'Planner backup',
            onBack: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 12),
          Text(
            tr(
              'Back up your events, tasks, notes, habits and goals as a file. Keep the file somewhere private.',
            ),
          ),
          const SizedBox(height: 16),
          if (_busy) const LinearProgressIndicator(),
          FilledButton(
            onPressed: _busy ? null : _export,
            child: Text(tr('Save backup file')),
          ),
          OutlinedButton(
            onPressed: _busy ? null : _restore,
            child: Text(tr('Restore backup')),
          ),
        ],
      ),
    ),
  );
}
