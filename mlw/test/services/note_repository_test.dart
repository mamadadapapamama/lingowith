import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mlw/models/note.dart';
import 'package:mlw/repositories/note_repository.dart';

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
        content: 'This is a test note',
        createdAt: now,
        updatedAt: now,
        flashCards: const [],
        pages: const [],
        imageUrl: '',
        extractedText: '',
        translatedText: '',
        isDeleted: false,
        flashcardCount: 0,
        reviewCount: 0,
      );
      
      final createdNote = await repository.createNote(note);
      
      expect(createdNote.id.isNotEmpty, true);
      expect(createdNote.title, 'Test Note');
      expect(createdNote.content, 'This is a test note');
      
      final doc = await firestore.collection('notes').doc(createdNote.id).get();
      expect(doc.exists, true);
      expect(doc.data()?['title'], 'Test Note');
    });
    
    test('should get notes for user', () async {
      final now = DateTime.now();
      final note1 = Note(
        id: '',
        spaceId: 'default_space',
        userId: 'user1',
        title: 'Note 1',
        content: 'Content 1',
        createdAt: now,
        updatedAt: now,
        flashCards: const [],
        pages: const [],
        imageUrl: '',
        extractedText: '',
        translatedText: '',
        isDeleted: false,
        flashcardCount: 0,
        reviewCount: 0,
      );
      
      await repository.createNote(note1);
      
      final notes = await repository.getNotes('user1');
      
      expect(notes.length, 1);
      expect(notes[0].title, 'Note 1');
    });
    
    test('should update note', () async {
      final now = DateTime.now();
      final note = Note(
        id: '',
        spaceId: 'default_space',
        userId: 'user1',
        title: 'Original Title',
        content: 'Original content',
        createdAt: now,
        updatedAt: now,
        flashCards: const [],
        pages: const [],
        imageUrl: '',
        extractedText: '',
        translatedText: '',
        isDeleted: false,
        flashcardCount: 0,
        reviewCount: 0,
      );
      
      final createdNote = await repository.createNote(note);
      
      final updatedNote = createdNote.copyWith(
        title: 'Updated Title',
      );
      
      await repository.updateNote(updatedNote);
      
      final doc = await firestore.collection('notes').doc(createdNote.id).get();
      expect(doc.data()?['title'], 'Updated Title');
    });
    
    test('should delete note', () async {
      final now = DateTime.now();
      final note = Note(
        id: '',
        spaceId: 'default_space',
        userId: 'user1',
        title: 'Test Note',
        content: 'This is a test note',
        createdAt: now,
        updatedAt: now,
        flashCards: const [],
        pages: const [],
        imageUrl: '',
        extractedText: '',
        translatedText: '',
        isDeleted: false,
        flashcardCount: 0,
        reviewCount: 0,
      );
      
      final createdNote = await repository.createNote(note);
      
      await repository.deleteNote(createdNote.id);
      
      final doc = await firestore.collection('notes').doc(createdNote.id).get();
      expect(doc.data()?['isDeleted'], true);
    });
  });
} 