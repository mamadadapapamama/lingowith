import 'package:flutter_test/flutter_test.dart';
import 'package:mlw/models/note.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
  });

  group('Note', () {
    final now = DateTime.now();
    final testNote = Note(
      id: 'test_id',
      spaceId: 'test_space',
      userId: 'test_user',
      title: 'Test Note',
      content: 'Test content',
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

    test('should create Note instance with required parameters', () {
      final now = DateTime.now();
      final note = Note(
        id: '1',
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

      expect(note.id, '1');
      expect(note.title, 'Test Note');
      expect(note.content, 'This is a test note');
    });

    test('should create copy with updated fields', () {
      final now = DateTime.now();
      final note = Note(
        id: '1',
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

      final flashCard = FlashCard(
        id: '1',
        front: '你好',
        back: '안녕하세요',
        pinyin: 'nǐ hǎo',
        createdAt: now,
      );

      final updatedNote = note.copyWith(
        title: 'Updated Title',
        flashCards: [flashCard],
      );

      expect(updatedNote.id, '1');
      expect(updatedNote.title, 'Updated Title');
      expect(updatedNote.content, 'Original content');
      expect(updatedNote.flashCards.length, 1);
      expect(updatedNote.flashCards.first.front, '你好');
    });

    test('should create Note from Firestore document', () async {
      final now = Timestamp.now();
      final data = {
        'spaceId': 'default_space',
        'title': 'Test Note',
        'content': 'Test Content',
        'userId': 'user1',
        'createdAt': now,
        'updatedAt': now,
        'pages': [
          {
            'imageUrl': 'test_image.jpg',
            'extractedText': 'Extracted Text',
            'translatedText': 'Translated Text',
          }
        ],
        'flashCards': [],
      };

      // fake_cloud_firestore를 사용하여 실제 문서 생성
      final docRef = await fakeFirestore.collection('notes').add(data);
      final doc = await docRef.get();
      
      final note = Note.fromFirestore(doc);

      expect(note.title, 'Test Note');
      expect(note.content, 'Test Content');
      expect(note.userId, 'user1');
      expect(note.createdAt, now.toDate());
      expect(note.updatedAt, now.toDate());
      expect(note.flashCards.length, 0);
      expect(note.pages.first.extractedText, 'Extracted Text');
      expect(note.pages.first.translatedText, 'Translated Text');
    });

    test('should convert Note to Firestore data', () {
      final now = DateTime.now();
      final flashCard = FlashCard(
        id: '1',
        front: '你好',
        back: '안녕하세요',
        pinyin: 'nǐ hǎo',
        createdAt: now,
      );

      final note = Note(
        id: '1',
        spaceId: 'default_space',
        userId: 'user1',
        title: 'Test Note',
        content: 'This is a test note',
        createdAt: now,
        updatedAt: now,
        flashCards: [flashCard],
        pages: const [],
        imageUrl: '',
        extractedText: '',
        translatedText: '',
        isDeleted: false,
        flashcardCount: 0,
        reviewCount: 0,
      );

      final data = note.toFirestore();

      expect(data['id'], '1');
      expect(data['title'], 'Test Note');
      expect(data['content'], 'This is a test note');
      expect(data['flashCards'].length, 1);
      expect(data['flashCards'][0]['front'], '你好');
    });

    test('toFirestore converts Note to Map correctly', () {
      final map = testNote.toJson();
      expect(map['spaceId'], 'test_space');
      expect(map['userId'], 'test_user');
    });
  });
}

