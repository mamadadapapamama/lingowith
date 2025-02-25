import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mlw/data/models/note.dart';
import 'package:mlw/data/repositories/note_repository.dart';
import 'package:mlw/data/datasources/remote/firebase_data_source.dart';

void main() {
  late FirebaseDataSource dataSource;
  late NoteRepository repository;
  
  setUp(() {
    final firestore = FakeFirebaseFirestore();
    dataSource = FirebaseDataSource(firestore: firestore);
    repository = NoteRepository(remoteDataSource: dataSource);
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
        pages: [],
        flashCards: [],
        highlightedTexts: [],
        knownFlashCards: [],
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
        pages: [],
        flashCards: [],
        highlightedTexts: [],
        knownFlashCards: [],
        createdAt: now,
        updatedAt: now,
      );
      
      await repository.createNote(note1);
      
      final notes = await repository.getNotesByUserId('user1');
      
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
        pages: [],
        flashCards: [],
        highlightedTexts: [],
        knownFlashCards: [],
        createdAt: now,
        updatedAt: now,
      );
      
      final createdNote = await repository.createNote(note);
      final updatedNote = createdNote.copyWith(title: 'Updated Title');
      
      await repository.updateNote(updatedNote);
      final fetchedNote = await repository.getNoteById(createdNote.id);
      
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
        pages: [],
        flashCards: [],
        highlightedTexts: [],
        knownFlashCards: [],
        createdAt: now,
        updatedAt: now,
      );
      
      final createdNote = await repository.createNote(note);
      await repository.deleteNote(createdNote.id);
      
      final fetchedNote = await repository.getNoteById(createdNote.id);
      expect(fetchedNote, null);
    });
  });
} 