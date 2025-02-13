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
      content: 'Test Content',
      imageUrl: 'test_image.jpg',
      extractedText: '测试文本',
      translatedText: '테스트 텍스트',
      pinyin: 'ceshi wenben',
      flashCards: [],
      highlightedTexts: [],
      createdAt: now,
      updatedAt: now,
    );

    test('should create Note instance with required parameters', () {
      final now = DateTime.now();
      final note = Note(
        id: '1',
        spaceId: 'default_space',
        userId: 'user1',
        title: 'Test Note',
        content: '',
        createdAt: now,
        updatedAt: now,
      );

      expect(note.id, '1');
      expect(note.title, 'Test Note');
      expect(note.userId, 'user1');
      expect(note.createdAt, now);
      expect(note.updatedAt, now);
      expect(note.content, '');
      expect(note.flashCards, isEmpty);
      expect(note.extractedText, null);
      expect(note.translatedText, null);
      expect(note.pinyin, null);
    });

    test('should create copy with updated fields', () {
      final now = DateTime.now();
      final note = Note(
        id: '1',
        spaceId: 'default_space',
        userId: 'user1',
        title: 'Test Note',
        content: '',
        createdAt: now,
        updatedAt: now,
      );

      final flashCard = FlashCard(
        id: '1',
        text: '你好',
        translation: '안녕하세요',
        noteId: '1',
        createdAt: now,
      );

      final updated = note.copyWith(
        title: 'Updated Note',
        content: 'New content',
        flashCards: [flashCard],
        extractedText: 'Extracted text',
        translatedText: 'Translated text',
        pinyin: 'Pin yin',
      );

      expect(updated.id, '1');  // unchanged
      expect(updated.title, 'Updated Note');
      expect(updated.content, 'New content');
      expect(updated.userId, 'user1');  // unchanged
      expect(updated.createdAt, now);  // unchanged
      expect(updated.updatedAt, isNot(now));  // should be updated
      expect(updated.flashCards, [flashCard]);
      expect(updated.extractedText, 'Extracted text');
      expect(updated.translatedText, 'Translated text');
      expect(updated.pinyin, 'Pin yin');
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
        'flashCards': [],
        'highlightedTexts': [],
        'extractedText': 'Extracted Text',
        'translatedText': 'Translated Text',
        'pinyin': 'Pin Yin',
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
      expect(note.extractedText, 'Extracted Text');
      expect(note.translatedText, 'Translated Text');
      expect(note.pinyin, 'Pin Yin');
    });

    test('should convert Note to Firestore data', () {
      final now = DateTime.now();
      final flashCard = FlashCard(
        id: '1',
        text: '你好',
        translation: '안녕하세요',
        pinyin: 'nǐ hǎo',
        noteId: 'note1',
        createdAt: now,
      );

      final note = Note(
        id: '1',
        spaceId: 'default_space',
        userId: 'user1',
        title: 'Test Note',
        content: 'Test Content',
        createdAt: now,
        updatedAt: now,
        flashCards: [flashCard],
        extractedText: 'Extracted Text',
        translatedText: 'Translated Text',
        pinyin: 'Pin Yin',
      );

      final data = note.toFirestore();

      expect(data['title'], 'Test Note');
      expect(data['content'], 'Test Content');
      expect(data['userId'], 'user1');
      expect(data['createdAt'], isA<Timestamp>());
      expect(data['updatedAt'], isA<Timestamp>());
      expect(data['flashCards'].length, 1);
      expect(data['flashCards'].first['text'], '你好');
      expect(data['extractedText'], 'Extracted Text');
      expect(data['translatedText'], 'Translated Text');
      expect(data['pinyin'], 'Pin Yin');
    });

    test('toFirestore converts Note to Map correctly', () {
      final map = testNote.toFirestore();
      expect(map['spaceId'], 'test_space');
      expect(map['userId'], 'test_user');
      // ... 다른 필드들도 테스트
    });
  });
}

