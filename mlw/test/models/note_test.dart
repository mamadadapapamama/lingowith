import 'package:flutter_test/flutter_test.dart';
import 'package:mlw/data/models/note.dart';
import 'package:mlw/data/models/page.dart';
import 'package:mlw/data/models/flash_card.dart';
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
      noteSpaceId: 'test_space',
      userId: 'test_user',
      title: 'Test Note',
      content: 'Test Content',
      createdAt: now,
      updatedAt: now,
    );

    test('should create Note instance with required parameters', () {
      final now = DateTime.now();
      final note = Note(
        id: '1',
        noteSpaceId: 'default_space',
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

      expect(note.id, '1');
      expect(note.noteSpaceId, 'default_space');
      expect(note.userId, 'user1');
      expect(note.title, 'Test Note');
      expect(note.content, '');
      expect(note.createdAt, now);
      expect(note.updatedAt, now);
    });

    test('should create copy with updated fields', () {
      final now = DateTime.now();
      final note = Note(
        id: '1',
        noteSpaceId: 'default_space',
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

      final flashCard = FlashCard(
        id: 'test_card_id',
        noteId: 'test_note_id',
        pageId: 'test_page_id',
        userId: 'test_user_id',
        front: '你好',
        back: '안녕하세요',
        pinyin: 'nǐ hǎo',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final page = Page(
        id: 'test_page_id',
        noteId: 'test_note_id',
        userId: 'test_user_id',
        imageUrl: 'test_image.jpg',
        originalText: 'Extracted text',
        translatedText: 'Translated text',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updated = note.copyWith(
        title: 'Updated Note',
        content: 'New content',
        flashCards: [flashCard],
        pages: [page],
      );

      expect(updated.id, '1');  // unchanged
      expect(updated.noteSpaceId, 'default_space');
      expect(updated.userId, 'user1');  // unchanged
      expect(updated.createdAt, now);  // unchanged
      expect(updated.updatedAt, isNot(now));  // should be updated
      expect(updated.flashCards, [flashCard]);
      expect(updated.pages.first.extractedText, 'Extracted text');
      expect(updated.pages.first.translatedText, 'Translated text');
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
        'highlightedTexts': [],
        'knownFlashCards': [],
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
        id: 'test_card_id',
        noteId: 'test_note_id',
        pageId: 'test_page_id',
        userId: 'test_user_id',
        front: '你好',
        back: '안녕하세요',
        pinyin: 'nǐ hǎo',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final page = Page(
        id: 'test_page_id',
        noteId: 'test_note_id',
        userId: 'test_user_id',
        imageUrl: 'test_image.jpg',
        originalText: 'Extracted text',
        translatedText: 'Translated text',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final note = Note(
        id: '1',
        noteSpaceId: 'default_space',
        userId: 'user1',
        title: 'Test Note',
        content: 'Test Content',
        createdAt: now,
        updatedAt: now,
        flashCards: [flashCard],
        pages: [page],
        highlightedTexts: [],
        knownFlashCards: [],
      );

      final data = note.toFirestore();

      expect(data['title'], 'Test Note');
      expect(data['content'], 'Test Content');
      expect(data['userId'], 'user1');
      expect(data['createdAt'], isA<Timestamp>());
      expect(data['updatedAt'], isA<Timestamp>());
      expect(data['flashCards'].length, 1);
      expect(data['flashCards'].first['front'], '你好');
      expect(data['pages'].first['extractedText'], 'Extracted text');
      expect(data['pages'].first['translatedText'], 'Translated text');
    });

    test('toFirestore converts Note to Map correctly', () {
      final map = testNote.toFirestore();
      expect(map['spaceId'], 'test_space');
      expect(map['userId'], 'test_user');
    });
  });
}

