import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mlw/models/note.dart';
import 'package:mlw/services/note_repository.dart';

void main() {
  late FirebaseFirestore firestore;
  late NoteRepository repository;
  
  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = NoteRepository(firestore: firestore);
  });
  
  group('NoteRepository', () {
    test('should create note', () async {
      final now = DateTime.now();
      final note = Note(
        id: '',
        spaceId: 'default_space',
        userId: 'user1',
        title: 'Test Note',
        content: '',
        createdAt: now,
        updatedAt: now,
      );
      
      final createdNote = await repository.createNote(note);
      
      expect(createdNote.id.isNotEmpty, true);
      expect(createdNote.title, note.title);
      expect(createdNote.userId, note.userId);
    });
    
    test('should get notes for user', () async {
      final now = DateTime.now();
      final note1 = Note(
        id: '',
        spaceId: 'default_space',
        userId: 'user1',
        title: 'Note 1',
        content: '',
        createdAt: now,
        updatedAt: now,
      );
      
      await repository.createNote(note1);
      
      final notes = await repository.getNotes('user1', 'default_space').first;
      
      expect(notes.length, 1);
      expect(notes.first.title, 'Note 1');
    });
    
    test('should update note', () async {
      final now = DateTime.now();
      final note = Note(
        id: '',
        spaceId: 'default_space',
        userId: 'user1',
        title: 'Original Title',
        content: '',
        createdAt: now,
        updatedAt: now,
      );
      
      final createdNote = await repository.createNote(note);
      final updatedNote = createdNote.copyWith(title: 'Updated Title');
      
      await repository.updateNote(updatedNote);
      final fetchedNote = await repository.getNote(createdNote.id);
      
      expect(fetchedNote?.title, 'Updated Title');
    });
    
    test('should delete note', () async {
      final now = DateTime.now();
      final note = Note(
        id: '',
        spaceId: 'default_space',
        userId: 'user1',
        title: 'Test Note',
        content: '',
        createdAt: now,
        updatedAt: now,
      );
      
      final createdNote = await repository.createNote(note);
      await repository.deleteNote(createdNote.id);
      
      final fetchedNote = await repository.getNote(createdNote.id);
      expect(fetchedNote, null);
    });
  });
} 