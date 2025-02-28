import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mlw/models/note.dart';
import 'package:mlw/services/image_processing_service.dart';
import 'package:mlw/services/translator.dart';
import 'package:mlw/services/pinyin_service.dart';

class NoteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImageProcessingService _imageProcessingService;
  final TranslatorService _translatorService;
  final PinyinService _pinyinService;
  
  NoteService({
    required ImageProcessingService imageProcessingService,
    required TranslatorService translatorService,
    required PinyinService pinyinService,
  }) : 
    _imageProcessingService = imageProcessingService,
    _translatorService = translatorService,
    _pinyinService = pinyinService;
  
  // 노트 업데이트 메서드
  Future<Note> updateNote(Note note) async {
    await _firestore.collection('notes').doc(note.id).update(note.toJson());
    return note;
  }
  
  // 플래시카드 추가 메서드
  Future<Note> addFlashCard(Note note, String text) async {
    final translatedText = await _translatorService.translate(text, 'zh', 'ko');
    final pinyin = await _pinyinService.getPinyin(text);
    
    final newFlashCard = FlashCard(
      front: text,
      back: translatedText,
      pinyin: pinyin,
    );
    
    final updatedFlashCards = [
      ...note.flashCards.where((card) => card.front != text),
      newFlashCard,
    ];
    
    final updatedNote = note.copyWith(
      flashCards: updatedFlashCards,
      highlightedTexts: {...note.highlightedTexts, text},
      updatedAt: DateTime.now(),
    );
    
    return await updateNote(updatedNote);
  }
  
  // 하이라이트 제거 메서드
  Future<Note> removeHighlight(Note note, String text) async {
    final updatedNote = note.copyWith(
      highlightedTexts: Set<String>.from(note.highlightedTexts)..remove(text),
      updatedAt: DateTime.now(),
    );
    
    return await updateNote(updatedNote);
  }
} 