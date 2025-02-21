import 'package:flutter/material.dart';
import 'package:mlw/models/note.dart' as note_model;
import 'package:mlw/widgets/text_highlighter.dart';
import 'package:mlw/theme/tokens/color_tokens.dart';
import 'package:mlw/theme/tokens/typography_tokens.dart';
import 'dart:io';
import 'dart:math';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mlw/screens/image_viewer_screen.dart';

class NotePage extends StatefulWidget {
  final note_model.Page page;
  final Function(String) onEditText;
  final VoidCallback onDeletePage;

  const NotePage({
    Key? key,
    required this.page,
    required this.onEditText,
    required this.onDeletePage,
  }) : super(key: key);

  @override
  State<NotePage> createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  bool _showOriginalText = true;
  bool _showTranslation = true;
  bool _showHighlight = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              _buildImageContent(),
              Positioned(
                top: 8,
                right: 8,
                child: _buildToggleButtons(),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: _buildMoreOptionsButton(),
              ),
            ],
          ),
          if (widget.page.textBlocks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildTextBlocks(),
            ),
        ],
      ),
    );
  }

  Widget _buildTextBlocks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.page.textBlocks.map((block) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_showOriginalText)
                Text(
                  block.text,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.5,
                  ),
                ),
              if (_showTranslation)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    block.translation,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                      height: 1.5,
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildImageContent() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageViewerScreen(
              imageUrl: widget.page.imageUrl,
            ),
          ),
        );
      },
      child: AspectRatio(
        aspectRatio: 4/3,
        child: Hero(
          tag: widget.page.imageUrl,
          child: Image.file(
            File(widget.page.imageUrl),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButtons() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ToggleButtons(
        borderRadius: BorderRadius.circular(8),
        selectedColor: Theme.of(context).colorScheme.primary,
        fillColor: Theme.of(context).colorScheme.secondary,
        color: Theme.of(context).colorScheme.onSurface,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        isSelected: [_showOriginalText, _showTranslation, _showHighlight],
        onPressed: (index) {
          setState(() {
            if (index == 0) _showOriginalText = !_showOriginalText;
            if (index == 1) _showTranslation = !_showTranslation;
            if (index == 2) _showHighlight = !_showHighlight;
          });
        },
        children: [
          SvgPicture.asset(
            'assets/icon/original.svg',
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              _showOriginalText
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
              BlendMode.srcIn,
            ),
          ),
          SvgPicture.asset(
            'assets/icon/translate.svg',
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              _showTranslation
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
              BlendMode.srcIn,
            ),
          ),
          Icon(Icons.highlight_alt),
        ],
      ),
    );
  }

  Widget _buildMoreOptionsButton() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: const Icon(Icons.more_vert),
        onPressed: _showMoreOptions,
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('텍스트 수정'),
            onTap: () {
              Navigator.pop(context);
              _showEditDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('페이지 삭제'),
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmation();
            },
          ),
        ],
      ),
    );
  }

  void _showEditDialog() {
    final textController = TextEditingController(
      text: widget.page.textBlocks.map((block) => block.text).join('\n'),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('텍스트 수정'),
        content: TextField(
          controller: textController,
          maxLines: null,
          decoration: const InputDecoration(
            hintText: '텍스트를 수정하세요',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              widget.onEditText(textController.text);
              Navigator.pop(context);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('페이지 삭제'),
        content: const Text('이 페이지를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              widget.onDeletePage();
              Navigator.pop(context);
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
} 