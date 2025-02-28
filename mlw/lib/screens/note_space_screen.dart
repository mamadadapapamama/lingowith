import 'package:flutter/material.dart';
import 'package:mlw/models/note.dart';
import 'package:mlw/repositories/note_repository.dart';
import 'dart:async';

class NoteSpaceScreen extends StatefulWidget {
  final String spaceId;

  const NoteSpaceScreen({Key? key, required this.spaceId}) : super(key: key);

  @override
  _NoteSpaceScreenState createState() => _NoteSpaceScreenState();
}

class _NoteSpaceScreenState extends State<NoteSpaceScreen> {
  late NoteRepository _noteRepository;
  late StreamSubscription<List<Note>> _notesSubscription;
  List<Note> _notes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _noteRepository = NoteRepository();
    _loadNotes();
  }

  @override
  void dispose() {
    _notesSubscription.cancel();
    super.dispose();
  }

  void _loadNotes() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final notesStream = _noteRepository.getNotes(widget.spaceId);
      
      _notesSubscription = notesStream.listen((notes) {
        setState(() {
          _notes = notes;
          _isLoading = false;
        });
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('노트 로딩 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('노트 스페이스'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _notes.isEmpty
              ? Center(child: Text('노트가 없습니다'))
              : ListView.builder(
                  itemCount: _notes.length,
                  itemBuilder: (context, index) {
                    final note = _notes[index];
                    return ListTile(
                      title: Text(note.title),
                      subtitle: Text('${note.pages.length} 페이지'),
                      onTap: () {
                        // 노트 상세 화면으로 이동
                      },
                    );
                  },
                ),
    );
  }
} 