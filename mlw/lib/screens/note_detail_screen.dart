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
  final FlutterTts _tts = FlutterTts();
  final TranslatorService _translator = TranslatorService();
  final NoteRepository _repository = NoteRepository();
  
  bool _showTranslation = false;
  bool _showPinyin = false;
  bool _isHighlightMode = false;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _note = widget.note;
    _initTts();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _initTts() async {
    try {
      if (Platform.isIOS) {
        await _tts.setSharedInstance(true);
        await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.ambient,
          [IosTextToSpeechAudioCategoryOptions.mixWithOthers],
        );
      }

      await _tts.setLanguage("zh-CN");
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      _tts.setCompletionHandler(() {
        if (mounted) setState(() => _isSpeaking = false);
      });
    } catch (e) {
      debugPrint('TTS initialization error: $e');
    }
  }

  Future<void> _speak(String text) async {
    if (_isSpeaking) {
      await _stop();
      return;
    }

    try {
      setState(() => _isSpeaking = true);
      await _tts.speak(text);
    } catch (e) {
      debugPrint('TTS speak error: $e');
      if (mounted) setState(() => _isSpeaking = false);
    }
  }

  Future<void> _stop() async {
    try {
      await _tts.stop();
      if (mounted) setState(() => _isSpeaking = false);
    } catch (e) {
      debugPrint('TTS stop error: $e');
    }
  }

  Future<void> _addFlashCard(String text) async {
    try {
      final translation = await _translator.translate(text, from: 'zh', to: 'ko');
      
      final flashCard = FlashCard(
        id: DateTime.now().toString(),
        noteId: _note.id,
        text: text,
        translation: translation,
        createdAt: DateTime.now(),
      );

      final updatedNote = _note.copyWith(
        flashCards: [..._note.flashCards, flashCard],
      );

      await _repository.updateNote(updatedNote);
      
      if (mounted) {
        setState(() => _note = updatedNote);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('플래시카드가 저장되었습니다')),
        );
      }
    } catch (e) {
      debugPrint('Add flashcard error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('플래시카드 저장 실패: $e')),
        );
      }
    }
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
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FlashCardScreen(flashCards: _note.flashCards),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    if (_note.imageUrl == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.neonGreen.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildImageViewer(),
          if (_note.extractedText != null) _buildExtractedTextSection(),
        ],
      ),
    );
  }

  Widget _buildImageViewer() {
    return Stack(
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
                  errorBuilder: (_, error, __) {
                    debugPrint('Error loading image: $error');
                    return const SizedBox(
                      height: 150,
                      child: Center(child: Text('이미지를 불러올 수 없습니다.')),
                    );
                  },
                );
              }
              
              return const SizedBox(
                height: 150,
                child: Center(child: Text('이미지 파일이 존재하지 않습니다.')),
              );
            },
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: IconButton.filled(
            icon: const Icon(Icons.fullscreen),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ImageViewerScreen(imageUrl: _note.imageUrl!),
              ),
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withOpacity(0.5),
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExtractedTextSection() {
    final extractedTexts = _note.extractedText!
        .split('\n')
        .where((s) => s.trim().isNotEmpty)
        .toList();
    final translations = _note.translatedText?.split('\n')
        .where((s) => s.trim().isNotEmpty)
        .toList() ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildControlButtons(),
          ...extractedTexts.asMap().entries.map((entry) {
            final index = entry.key;
            final text = entry.value;
            final translation = index < translations.length ? translations[index] : '';
            return _buildTextItem(text, translation);
          }),
        ],
      ),
    );
  }

  Widget _buildTextItem(String text, String translation) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.volume_up, size: 20),
            onPressed: () => _speak(text),
            color: AppColors.deepGreen,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextHighlighter(
                  text: text,
                  isHighlightMode: _isHighlightMode,
                  onHighlighted: _addFlashCard,
                ),
                if (_showTranslation) ...[
                  const SizedBox(height: 4),
                  Text(
                    translation,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
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
            _buildImageSection(),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
} 
