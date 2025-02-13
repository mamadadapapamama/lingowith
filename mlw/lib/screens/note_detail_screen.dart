import 'package:flutter/material.dart';
import 'package:mlw/models/note.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:mlw/styles/app_colors.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mlw/screens/image_viewer_screen.dart';
import 'package:mlw/services/translator.dart';
import 'package:mlw/services/note_repository.dart';
import 'package:mlw/widgets/text_highlighter.dart';
import 'package:mlw/screens/flashcard_screen.dart';

class NoteDetailScreen extends StatefulWidget {
  final Note note;

  const NoteDetailScreen({
    super.key,
    required this.note,
  });

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late Note _note;
  final FlutterTts flutterTts = FlutterTts();
  final TranslatorService translatorService = TranslatorService();
  bool _showTranslation = false;  // 번역 표시 여부
  bool _showPinyin = false;      // 병음 표시 여부
  bool _isHighlightMode = false;

  @override
  void initState() {
    super.initState();
    _note = widget.note;
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      // iOS에서는 공유 인스턴스 먼저 설정
      if (Platform.isIOS) {
        await flutterTts.setSharedInstance(true);
        await flutterTts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          ],
        );
      }

      // 기본 설정
      await Future.wait([
        flutterTts.setLanguage("zh-CN"),
        flutterTts.setSpeechRate(0.5),
        flutterTts.setVolume(1.0),
        flutterTts.setPitch(1.0),
      ]);

    } catch (e) {
      debugPrint('TTS 초기화 에러: $e');
      // TTS 초기화 실패해도 앱은 계속 실행
    }
  }

  Future<void> _speak(String text) async {
    try {
      await flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS 실행 에러: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('음성 재생 중 오류가 발생했습니다')),
      );
    }
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Text(
            _formatDate(_note.createdAt),
            style: GoogleFonts.poppins(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            icon: const Icon(Icons.style),
            label: Text(
              '${_note.flashCards.length} cards',
              style: GoogleFonts.poppins(
                color: AppColors.neonGreen,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FlashCardScreen(
                    flashCards: _note.flashCards,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImageViewer() {
    return Column(
      children: [
        if (_note.imageUrl != null)
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.neonGreen.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 이미지 섹션
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      child: FutureBuilder<bool>(
                        future: File(_note.imageUrl!).exists(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const SizedBox(
                              height: 150,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          
                          if (snapshot.data == true) {
                            return Image.file(
                              File(_note.imageUrl!),
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                debugPrint('Error loading image: $error');
                                return const SizedBox(
                                  height: 150,
                                  child: Center(
                                    child: Text('이미지를 불러올 수 없습니다.'),
                                  ),
                                );
                              },
                            );
                          } else {
                            return const SizedBox(
                              height: 150,
                              child: Center(
                                child: Text('이미지 파일이 존재하지 않습니다.'),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton.filled(
                        icon: const Icon(Icons.fullscreen),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ImageViewerScreen(
                                imageUrl: _note.imageUrl!,
                              ),
                            ),
                          );
                        },
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withOpacity(0.5),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                // OCR 텍스트 섹션 with TTS
                if (_note.extractedText != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(8),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildToggleButtons(),  // 토글 버튼 추가
                        ..._note.extractedText!
                            .split('\n')
                            .where((s) => s.trim().isNotEmpty)
                            .map((sentence) {
                          final index = _note.extractedText!
                              .split('\n')
                              .indexOf(sentence);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.volume_up, size: 20),
                                  onPressed: () => _speak(sentence),
                                  color: AppColors.deepGreen,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildTextContent(sentence, index),  // 수정된 부분
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTextContent(String sentence, int index) {
    // 번역 텍스트 가져오기
    final translations = _note.translatedText?.split('\n').where((s) => s.trim().isNotEmpty).toList() ?? [];
    final translation = index < translations.length ? translations[index] : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextHighlighter(
          text: sentence,
          isHighlightMode: _isHighlightMode,
          onHighlighted: (selectedText) async {
            if (selectedText.isNotEmpty) {
              final translation = await translatorService.translate(
                selectedText,
                from: 'zh',
                to: 'ko',
              );
              
              final flashCard = FlashCard(
                id: DateTime.now().toString(),
                noteId: _note.id,
                text: selectedText,
                translation: translation,
                createdAt: DateTime.now(),
              );

              final updatedNote = _note.copyWith(
                flashCards: [..._note.flashCards, flashCard],
              );

              await NoteRepository().updateNote(updatedNote);
              setState(() {
                _note = updatedNote;
              });

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('플래시카드가 저장되었습니다')),
                );
              }
            }
          },
        ),
        // 번역 (토글 시)
        if (_showTranslation) ...[
          const SizedBox(height: 4),
          Text(
            translation,  // 위에서 정의한 translation 변수 사용
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[800],
            ),
          ),
        ],
        // 병음 (토글 시)
        if (_showPinyin) ...[
          const SizedBox(height: 4),
          Text(
            'TODO: 병음',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  // 토글 버튼 UI
  Widget _buildToggleButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          icon: Icon(
            Icons.g_translate,
            color: _showTranslation ? AppColors.neonGreen : Colors.grey,
          ),
          onPressed: () => setState(() => _showTranslation = !_showTranslation),
        ),
        IconButton(
          icon: Text(
            '拼',
            style: TextStyle(
              color: _showPinyin ? AppColors.neonGreen : Colors.grey,
            ),
          ),
          onPressed: () => setState(() => _showPinyin = !_showPinyin),
        ),
        IconButton(
          icon: Icon(
            Icons.highlight,
            color: _isHighlightMode ? AppColors.neonGreen : Colors.grey,
          ),
          onPressed: () => setState(() => _isHighlightMode = !_isHighlightMode),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _note.title,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.deepGreen,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildImageViewer(),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
} 
