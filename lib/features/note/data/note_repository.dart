import 'package:flutter_application/core/data/document_store.dart';
import 'package:flutter_application/core/data/repository.dart';
import 'package:flutter_application/features/note/domain/note.dart';

/// Maximum length of Quick Note content (FR-11.02, AC-26).
const quickNoteMaxChars = 500;

class NoteRepository extends Repository<Note> {
  NoteRepository(DocumentStore store, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now,
      super(store, Collections.notes);

  final DateTime Function() _clock;

  @override
  Note decode(Map<String, dynamic> json) => Note.fromJson(json);

  @override
  Map<String, dynamic> encode(Note item) => item.toJson();

  @override
  String idOf(Note item) => item.id;

  // ── Quick Note ────────────────────────────────────────────────────────────

  /// Text of the Quick Note; empty when it has never been written.
  String get quickText {
    for (final note in items) {
      if (note.isQuick) return note.content;
    }
    return '';
  }

  /// The single active Quick Note, or null when none exists yet (BR-09).
  Note? get quickNote {
    for (final note in items) {
      if (note.isQuick) return note;
    }
    return null;
  }

  /// Sets the Quick Note content, enforcing the 500-character limit
  /// (FR-11.02, AC-26).  Text longer than [quickNoteMaxChars] is truncated.
  void setQuick(String text) {
    final now = _clock();
    var note = items.where((n) => n.isQuick).firstOrNull;
    if (note == null) {
      note = Note(id: Note.quickId, title: 'Quick Note', createdAt: now);
      items.add(note);
    }
    note
      ..content = _clampQuick(text)
      ..updatedAt = now;
    persist(note);
    notifyListeners();
  }

  // ── Notes list (AC-26: pinned first) ──────────────────────────────────────

  /// Regular notes with pinned notes at the top, then most recently edited
  /// first within each group (AC-26).
  List<Note> get notes {
    final list = items.where((n) => !n.isQuick).toList();
    list.sort((a, b) {
      // Pinned notes first
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      // Within the same pin state, most recently edited first
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return list;
  }

  // ── Pin / unpin (AC-26) ────────────────────────────────────────────────────

  /// Pins [note] to the top of the notes list.
  void pin(Note note) {
    note.isPinned = true;
    save(note);
  }

  /// Removes the pin from [note].
  void unpin(Note note) {
    note.isPinned = false;
    save(note);
  }

  /// Toggles the pin state of [note].
  void togglePin(Note note) {
    note.isPinned = !note.isPinned;
    save(note);
  }

  // ── CRUD ───────────────────────────────────────────────────────────────────

  Note add({required String title, required String content}) {
    final note = Note(
      id: newId('note'),
      title: title.trim(),
      content: content.trim(),
      createdAt: _clock(),
    );
    items.add(note);
    persist(note);
    notifyListeners();
    return note;
  }

  /// Persists edits made to [note] in place.
  void save(Note note) {
    note.updatedAt = _clock();
    persist(note);
    notifyListeners();
  }

  /// Removes [note] from the repository and storage.
  ///
  /// Returns the deleted note so the caller can offer an undo (BR-13);
  /// null when the note was not in the list.
  Note? delete(Note note) {
    // Never delete the Quick Note through this method.
    if (note.isQuick) return null;
    if (!items.remove(note)) return null;
    erase(note);
    notifyListeners();
    return note;
  }

  /// Restores a previously [delete]d [note] (BR-13 undo).
  void restore(Note note) {
    items.add(note);
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Trims and clamps [text] to [quickNoteMaxChars] characters.
  static String _clampQuick(String text) {
    final trimmed = text.trim();
    if (trimmed.length <= quickNoteMaxChars) return trimmed;
    return trimmed.substring(0, quickNoteMaxChars);
  }
}
