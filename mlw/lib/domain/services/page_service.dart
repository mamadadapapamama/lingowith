import 'dart:io';
import 'package:mlw/data/models/page.dart';
import 'package:mlw/data/repositories/page_repository.dart';
import 'package:mlw/data/repositories/note_repository.dart';
import 'package:mlw/domain/services/image_processing_service.dart';

class PageService {
  final PageRepository _pageRepository;
  final NoteRepository _noteRepository;
  final ImageProcessingService _imageProcessingService;
  
  PageService({
    required PageRepository pageRepository,
    required NoteRepository noteRepository,
    required ImageProcessingService imageProcessingService,
  }) : _pageRepository = pageRepository,
       _noteRepository = noteRepository,
       _imageProcessingService = imageProcessingService;
  
  // 이미지로부터 페이지 생성
  Future<Page> createPageFromImage({
    required String userId,
    required String noteId,
    required File imageFile,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    try {
      // 이미지 처리 (OCR, 번역, 핀인)
      final processedData = await _imageProcessingService.processImage(
        imageFile,
        userId,
        sourceLanguage,
        targetLanguage,
      );
      
      final now = DateTime.now();
      
      // 페이지 생성
      final page = Page(
        id: '',
        noteId: noteId,
        userId: userId,
        imageUrl: processedData['imageUrl']!,
        originalText: processedData['originalText']!,
        translatedText: processedData['translatedText']!,
        pinyinText: processedData['pinyinText']!,
        highlightedPositions: [],
        createdAt: now,
        updatedAt: now,
      );
      
      // 페이지 저장
      final createdPage = await _pageRepository.createPage(page);
      
      // 노트에 페이지 추가
      await _noteRepository.addPageToNote(noteId, createdPage.id);
      
      return createdPage;
    } catch (e) {
      throw Exception('이미지로부터 페이지를 생성하는 중 오류가 발생했습니다: $e');
    }
  }
  
  // 노트별 페이지 목록 조회
  Future<List<Page>> getPagesByNoteId(String noteId) async {
    return await _pageRepository.getPagesByNoteId(noteId);
  }
  
  // 페이지 상세 조회
  Future<Page?> getPageById(String id) async {
    return await _pageRepository.getPageById(id);
  }
  
  // 페이지 업데이트
  Future<void> updatePage(Page page) async {
    await _pageRepository.updatePage(page.copyWith(
      updatedAt: DateTime.now(),
    ));
  }
  
  // 페이지 삭제
  Future<void> deletePage(String id) async {
    final page = await _pageRepository.getPageById(id);
    if (page != null) {
      // 노트에서 페이지 제거
      await _noteRepository.removePageFromNote(page.noteId, id);
      
      // 페이지 삭제
      await _pageRepository.deletePage(id);
    }
  }
  
  // 하이라이트 위치 업데이트
  Future<void> updateHighlightPositions(String pageId, List<int> positions) async {
    await _pageRepository.updateHighlightPositions(pageId, positions);
  }
  
  // 텍스트 번역
  Future<String> translateText(String text, String from, String to) async {
    return await _imageProcessingService.translateText(
      text,
      from: from,
      to: to
    );
  }
  
  // 핀인 추가
  Future<String> addPinyinToText(String text) async {
    return await _imageProcessingService.addPinyinToText(text);
  }
} 