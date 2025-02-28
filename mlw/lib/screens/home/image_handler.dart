import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mlw/services/image_processing_service.dart';
import 'package:mlw/services/translator_service.dart';
import 'package:mlw/models/note.dart' as note_model;
import 'package:mlw/repositories/note_repository.dart';
import 'package:mlw/screens/note_detail_screen.dart';

class ImageHandler {
  final BuildContext context;
  final String spaceId;
  final String userId;
  final Function(note_model.Note) onNoteCreated;
  final NoteRepository _noteRepository = NoteRepository();
  
  late ImageProcessingService _imageProcessingService;
  
  ImageHandler({
    required this.context,
    required this.spaceId,
    required this.userId,
    required this.onNoteCreated,
  }) {
    _imageProcessingService = ImageProcessingService(
      translatorService: TranslatorService(),
    );
  }
  
  // 이미지 소스 선택 액션 시트 표시
  void showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('카메라로 촬영'),
                onTap: () {
                  Navigator.pop(context);
                  processImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('갤러리에서 선택'),
                onTap: () {
                  Navigator.pop(context);
                  processMultipleImages();
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  // 이미지 처리 및 노트 자동 생성
  Future<void> processImage(ImageSource source) async {
    try {
      // 로딩 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      final ImageProcessingResult? result = await _imageProcessingService.processImage(source);
      
      // 로딩 다이얼로그 닫기
      if (context.mounted) {
        Navigator.pop(context);
      }
      
      if (result != null) {
        // 노트 번호 생성 (현재 시간 기반)
        final noteNumber = DateTime.now().millisecondsSinceEpoch % 10000;
        final title = "#$noteNumber";
        
        // 노트 자동 생성
        final newNote = note_model.Note(
          id: '',
          spaceId: spaceId,
          userId: userId,
          title: title,
          content: '',
          imageUrl: result.imageUrl,
          extractedText: result.extractedText,
          translatedText: result.translatedText,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isDeleted: false,
          flashcardCount: 0,
          reviewCount: 0,
          lastReviewedAt: null,
        );
        
        // Firestore에 저장
        final createdNote = await _noteRepository.createNote(newNote);
        
        // 콜백 호출
        onNoteCreated(createdNote);
        
        // 노트 상세 화면으로 바로 이동
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteDetailScreen(note: createdNote),
            ),
          );
        }
      } else {
        print('이미지 처리 결과가 없습니다.');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이미지 처리 중 오류가 발생했습니다.')),
          );
        }
      }
    } catch (e) {
      print('이미지 처리 오류: $e');
      if (context.mounted) {
        // 로딩 다이얼로그가 열려있으면 닫기
        Navigator.of(context).popUntil((route) => route.isFirst);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 처리 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }
  
  // 다중 이미지 처리
  Future<void> processMultipleImages() async {
    try {
      // 로딩 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      final List<ImageProcessingResult> results = 
          await _imageProcessingService.processMultipleImages();
      
      // 로딩 다이얼로그 닫기
      if (context.mounted) {
        Navigator.pop(context);
      }
      
      if (results.isNotEmpty) {
        note_model.Note? lastCreatedNote;
        
        for (var i = 0; i < results.length; i++) {
          final result = results[i];
          
          // 노트 번호 생성 (현재 시간 + 인덱스 기반)
          final noteNumber = DateTime.now().millisecondsSinceEpoch % 10000 + i;
          final title = "#$noteNumber";
          
          // 노트 자동 생성
          final newNote = note_model.Note(
            id: '',
            spaceId: spaceId,
            userId: userId,
            title: title,
            content: '',
            imageUrl: result.imageUrl,
            extractedText: result.extractedText,
            translatedText: result.translatedText,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isDeleted: false,
            flashcardCount: 0,
            reviewCount: 0,
            lastReviewedAt: null,
          );
          
          // Firestore에 저장
          final createdNote = await _noteRepository.createNote(newNote);
          lastCreatedNote = createdNote;
          
          // 콜백 호출
          onNoteCreated(createdNote);
        }
        
        // 마지막 노트의 상세 화면으로 이동
        if (lastCreatedNote != null && context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteDetailScreen(note: lastCreatedNote!),
            ),
          );
        }
      } else {
        print('선택된 이미지가 없습니다.');
      }
    } catch (e) {
      print('다중 이미지 처리 오류: $e');
      if (context.mounted) {
        // 로딩 다이얼로그가 열려있으면 닫기
        Navigator.of(context).popUntil((route) => route.isFirst);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 처리 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }
} 