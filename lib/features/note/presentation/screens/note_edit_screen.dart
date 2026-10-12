import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_text.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/widgets/app_widgets.dart';
import 'package:flutter_application/features/note/domain/note.dart';

/// Creates a note, edits [note], or edits the Quick Note when [quick] is set.
class NoteEditScreen extends StatefulWidget {
  const NoteEditScreen({super.key, this.note, this.quick = false});

  final Note? note;
  final bool quick;

  @override
  State<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  late final _title = TextEditingController(text: widget.note?.title);
  TextEditingController? _content;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _content ??= TextEditingController(
      text: widget.quick
          ? AppScope.read(context).notes.quickText
          : widget.note?.content,
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _content?.dispose();
    super.dispose();
  }

  void _save() {
    final app = AppScope.read(context);
    final title = _title.text.trim();
    final content = _content!.text.trim();
    if (widget.quick) {
      app.notes.setQuick(content);
    } else if (title.isEmpty && content.isEmpty) {
      showAppSnack(context, 'Write something first');
      return;
    } else if (widget.note case final note?) {
      note
        ..title = title
        ..content = content;
      app.notes.save(note);
    } else {
      app.notes.add(title: title, content: content);
    }
    Navigator.of(context).pop();
    showAppSnack(context, 'Note saved');
  }

  Future<void> _delete() async {
    final note = widget.note;
    if (note == null) return;
    final ok = await confirm(
      context,
      title: 'Delete note?',
      message: 'This note will be removed from this device.',
    );
    if (!ok || !mounted) return;
    AppScope.read(context).notes.delete(note);
    Navigator.of(context).pop();
    showAppSnack(context, 'Note deleted');
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.quick
        ? 'Quick Note'
        : widget.note == null
        ? 'New note'
        : 'Edit note';
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
          children: [
            TopBar(
              title: title,
              trailing: widget.note == null
                  ? TopBarAction(label: 'Save', onTap: _save)
                  : GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _delete,
                      child: const SizedBox(
                        width: 38,
                        height: 38,
                        child: Icon(
                          LucideIcons.trash2,
                          size: 18,
                          color: AppColors.danger,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            AppCard(
              color: widget.quick ? AppColors.note : null,
              borderColor: AppColors.primary,
              borderWidth: 1.5,
              shadow: false,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!widget.quick) ...[
                    Text(
                      'TITLE',
                      style: AppText.s(10, color: AppColors.primary),
                    ),
                    TextField(
                      controller: _title,
                      style: AppText.s(16, weight: FontWeight.w600),
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 6),
                        hintText: 'Note title',
                        hintStyle: AppText.s(16, color: AppColors.faint),
                      ),
                    ),
                    Divider(height: 16, color: AppColors.border),
                  ],
                  Text(
                    widget.quick ? 'QUICK NOTE' : 'CONTENT',
                    style: AppText.s(10, color: AppColors.primary),
                  ),
                  TextField(
                    controller: _content,
                    autofocus: widget.note == null,
                    minLines: 6,
                    maxLines: null,
                    maxLength: widget.quick ? 500 : null,
                    style: AppText.s(13, height: 1.45),
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 6),
                      hintText: 'Start writing…',
                      hintStyle: AppText.s(13, color: AppColors.faint),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            PrimaryButton(
              label: 'Save note',
              icon: LucideIcons.check,
              onTap: _save,
            ),
          ],
        ),
      ),
    );
  }
}
