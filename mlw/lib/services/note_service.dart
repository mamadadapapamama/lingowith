import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mlw/models/flash_card.dart' as flash_card_model;
import 'package:mlw/models/note.dart';
import 'package:mlw/services/image_processing_service.dart';
import 'package:mlw/services/translator_service.dart';
import 'package:mlw/services/pinyin_service.dart';
import 'package:mlw/repositories/note_repository.dart';

class NoteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImageProcessingService _imageProcessingService;
  final TranslatorService _translatorService;
  final PinyinService _pinyinService;
  final NoteRepository _noteRepository;
  
  NoteService({
    required ImageProcessingService imageProcessingService,
    required TranslatorService translatorService,
    required PinyinService pinyinService,
    required NoteRepository noteRepository,
  }) : 
    _imageProcessingService = imageProcessingService,
    _translatorService = translatorService,
    _pinyinService = pinyinService,
    _noteRepository = noteRepository;
  
  // 노트 생성
  Future<Note> createNote(Note note) async {
    return await _noteRepository.createNote(note);
  }
  
  // 노트 가져오기
  Future<Note?> getNote(String noteId) async {
    return await _noteRepository.getNote(noteId);
  }
  
  // 노트 업데이트
  Future<void> updateNote(Note note) async {
    await _noteRepository.updateNote(note);
  }
  
  // 노트 삭제
  Future<void> deleteNote(String noteId) async {
    await _noteRepository.deleteNote(noteId);
  }
  
  // 하이라이트 추가 및 플래시카드 생성
  Future<Note> addHighlight(Note note, String text) async {
    final translatedText = await _translatorService.translate(text, from: 'ko', to: 'zh');
    final pinyin = await _pinyinService.getPinyin(text);
    
    final newFlashCard = flash_card_model.FlashCard(
      front: text,
      back: translatedText,
      pinyin: pinyin,
      noteId: note.id,
      createdAt: DateTime.now(),
      reviewCount: 0,
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
    
    await _noteRepository.updateNote(updatedNote);
    return updatedNote;
  }
  
  // 플래시카드 삭제
  Future<Note> removeFlashCard(Note note, String front) async {
    final updatedFlashCards = note.flashCards.where((card) => card.front != front).toList();
    final updatedHighlightedTexts = note.highlightedTexts.where((text) => text != front).toSet();
    
    final updatedNote = note.copyWith(
      flashCards: updatedFlashCards,
      highlightedTexts: updatedHighlightedTexts,
      updatedAt: DateTime.now(),
    );
    
    await _noteRepository.updateNote(updatedNote);
    return updatedNote;
  }
  
  // 플래시카드 업데이트
  Future<Note> updateFlashCard(Note note, flash_card_model.FlashCard flashCard) async {
    final updatedFlashCards = note.flashCards.map((card) {
      if (card.front == flashCard.front) {
        return flashCard;
      }
      return card;
    }).toList();
    
    final updatedNote = note.copyWith(
      flashCards: updatedFlashCards,
      updatedAt: DateTime.now(),
    );
    
    await _noteRepository.updateNote(updatedNote);
    return updatedNote;
  }
} 