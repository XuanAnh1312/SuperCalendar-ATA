import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter_application/app/routes/app_routes.dart';
import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_text.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/utils/date_formatter.dart';
import 'package:flutter_application/core/widgets/app_widgets.dart';
import 'package:flutter_application/features/note/domain/note.dart';
import 'package:flutter_application/features/note/presentation/screens/note_edit_screen.dart';
import 'package:flutter_application/core/utils/strings.dart';

/// All notes: the pinned Quick Note first, then the user's notes.
class NoteListScreen extends StatelessWidget {
  const NoteListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final notes = app.notes.notes;
    final quick = app.notes.quickText;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Row(
              children: [
                RoundIconButton(
                  icon: LucideIcons.arrowLeft,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PageHeader(
                    title: 'Notes',
                    subtitle:
                        trf(notes.length == 1 ? '{n} note · saved on this device' : '{n} notes · saved on this device', {'n': notes.length}),
                    trailing: RoundIconButton(
                      icon: LucideIcons.plus,
                      size: 40,
                      filled: true,
                      onTap: () =>
                          pushFullScreen(context, const NoteEditScreen()),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            AppCard(
              color: AppColors.yellow,
              onTap: () =>
                  pushFullScreen(context, const NoteEditScreen(quick: true)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        LucideIcons.notebookPen,
                        size: 14,
                        color: AppColors.yellowText,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(tr('Quick Note'), style: AppText.cardTitle()),
                      ),
                      Text(tr('Edit'), style: AppText.action()),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr(quick.isEmpty ? 'Tap to write a note' : quick),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.s(11.5, height: 1.35),
                  ),
                  const SizedBox(height: 8),
                  const SavedStatus(),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (notes.isEmpty)
              const EmptyState(
                icon: LucideIcons.notebookPen,
                message: 'No notes yet.\nTap + to write your first one.',
              ),
            for (final note in notes)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _NoteCard(
                  note: note,
                  today: app.today,
                  onTap: () =>
                      pushFullScreen(context, NoteEditScreen(note: note)),
                  onTogglePin: () => app.notes.togglePin(note),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.today,
    required this.onTap,
    required this.onTogglePin,
  });

  final Note note;
  final DateTime today;
  final VoidCallback onTap;
  final VoidCallback onTogglePin;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  tr(note.title.isEmpty ? 'Untitled' : note.title),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.s(12.5, weight: FontWeight.w700),
                ),
              ),
              Text(
                relativeDay(note.updatedAt, today),
                style: AppText.s(9.5, color: AppColors.muted),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTogglePin,
                child: Semantics(
                  button: true,
                  label: note.isPinned ? 'Unpin' : 'Pin',
                  child: SizedBox(
                    width: 36,
                    height: 28,
                    child: Icon(
                      LucideIcons.pin,
                      size: 14,
                      color: note.isPinned
                          ? AppColors.primary
                          : AppColors.faint,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (note.content.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              note.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.s(11, color: AppColors.muted, height: 1.35),
            ),
          ],
        ],
      ),
    );
  }
}
