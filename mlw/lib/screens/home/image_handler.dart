import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mlw/models/note.dart' as note_model;
import 'package:mlw/repositories/note_repository.dart';
import 'package:mlw/screens/note_detail_screen.dart';
import 'dart:io';

class ImageHandler {
  final BuildContext context;
  final String spaceId;
  final String userId;
  final Function(note_model.Note) onNoteCreated;
  final NoteRepository _noteRepository = NoteRepository();
  
  ImageHandler({
    required this.context,
    required this.spaceId,
    required this.userId,
    required this.onNoteCreated,
  });
  
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
                  createNoteFromImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('갤러리에서 선택'),
                onTap: () {
                  Navigator.pop(context);
                  createNotesFromGallery();
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  // 이미지에서 노트 생성 (OCR 없이)
  Future<void> createNoteFromImage(ImageSource source) async {
    try {
      // 로딩 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      // 이미지 선택
      final pickedFile = await ImagePicker().pickImage(source: source);
      
      // 로딩 다이얼로그 닫기
      if (context.mounted) {
        Navigator.pop(context);
      }
      
      if (pickedFile != null) {
        final imageFile = File(pickedFile.path);
        
        // 노트 번호 생성 (현재 시간 기반)
        final noteNumber = DateTime.now().millisecondsSinceEpoch % 10000;
        final title = "#$noteNumber";
        
        // 노트 생성 (OCR 없이)
        final newNote = note_model.Note(
          id: '',
          spaceId: spaceId,
          userId: userId,
          title: title,
          content: '',
          imageUrl: imageFile.path, // 로컬 경로 저장
          extractedText: '', // OCR 없이 빈 텍스트
          translatedText: '', // 번역 없이 빈 텍스트
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
  
  // 갤러리에서 여러 이미지 선택하여 노트 생성
  Future<void> createNotesFromGallery() async {
    try {
      // 로딩 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      // 여러 이미지 선택
      final pickedFiles = await ImagePicker().pickMultiImage();
      
      // 로딩 다이얼로그 닫기
      if (context.mounted) {
        Navigator.pop(context);
      }
      
      if (pickedFiles.isNotEmpty) {
        note_model.Note? lastCreatedNote;
        
        for (var i = 0; i < pickedFiles.length; i++) {
          final imageFile = File(pickedFiles[i].path);
          
          // 노트 번호 생성 (현재 시간 + 인덱스 기반)
          final noteNumber = DateTime.now().millisecondsSinceEpoch % 10000 + i;
          final title = "#$noteNumber";
          
          // 노트 생성 (OCR 없이)
          final newNote = note_model.Note(
            id: '',
            spaceId: spaceId,
            userId: userId,
            title: title,
            content: '',
            imageUrl: imageFile.path, // 로컬 경로 저장
            extractedText: '', // OCR 없이 빈 텍스트
            translatedText: '', // 번역 없이 빈 텍스트
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