import 'package:flutter_application/core/data/document_store.dart';
import 'package:flutter_application/core/data/repository.dart';
import 'package:flutter_application/features/note/domain/note.dart';

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

  /// Text of the Quick Note; empty when it has never been written.
  String get quickText {
    for (final note in items) {
      if (note.isQuick) return note.content;
    }
    return '';
  }

  /// Regular notes, most recently edited first.
  List<Note> get notes {
    final list = items.where((n) => !n.isQuick).toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  void setQuick(String text) {
    final now = _clock();
    var note = items.where((n) => n.isQuick).firstOrNull;
    if (note == null) {
      note = Note(id: Note.quickId, title: 'Quick Note', createdAt: now);
      items.add(note);
    }
    note
      ..content = text.trim()
      ..updatedAt = now;
    persist(note);
    notifyListeners();
  }

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

  void delete(Note note) {
    if (!items.remove(note)) return;
    erase(note);
    notifyListeners();
  }
}
