import 'package:flutter/material.dart';
import '../models/note_space.dart';
import '../repositories/note_space_repository.dart';
import '../styles/app_colors.dart';

class NoteSpaceSettingsScreen extends StatefulWidget {
  final NoteSpace noteSpace;

  const NoteSpaceSettingsScreen({
    Key? key,
    required this.noteSpace,
  }) : super(key: key);

  @override
  State<NoteSpaceSettingsScreen> createState() => _NoteSpaceSettingsScreenState();
}

class _NoteSpaceSettingsScreenState extends State<NoteSpaceSettingsScreen> {
  late NoteSpace _noteSpace;
  final _repository = NoteSpaceRepository();

  @override
  void initState() {
    super.initState();
    _noteSpace = widget.noteSpace;
  }

  Future<void> _updateSettings(NoteSpace updatedSpace) async {
    try {
      await _repository.updateNoteSpace(updatedSpace);
      setState(() {
        _noteSpace = updatedSpace;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('설정이 저장되었습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('설정 저장 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_noteSpace.name} 설정'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('플래시카드'),
            subtitle: const Text('텍스트를 선택하여 플래시카드를 만들 수 있습니다'),
            value: _noteSpace.isFlashcardEnabled,
            onChanged: (value) {
              final updated = _noteSpace.copyWith(isFlashcardEnabled: value);
              _updateSettings(updated);
            },
          ),
          SwitchListTile(
            title: const Text('음성 읽기 (TTS)'),
            subtitle: const Text('텍스트를 음성으로 읽어줍니다'),
            value: _noteSpace.isTTSEnabled,
            onChanged: (value) {
              final updated = _noteSpace.copyWith(isTTSEnabled: value);
              _updateSettings(updated);
            },
          ),
          SwitchListTile(
            title: const Text('병음 (Pinyin)'),
            subtitle: const Text('중국어 텍스트의 병음을 표시합니다'),
            value: _noteSpace.isPinyinEnabled,
            onChanged: (value) {
              final updated = _noteSpace.copyWith(isPinyinEnabled: value);
              _updateSettings(updated);
            },
          ),
        ],
      ),
    );
  }
} 