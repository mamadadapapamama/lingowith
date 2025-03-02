import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/note_space.dart';
import '../theme/tokens/color_tokens.dart';
import '../theme/tokens/typography_tokens.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../repositories/note_repository.dart';

class NoteSpaceSettingsScreen extends StatefulWidget {
  final NoteSpace noteSpace;

  const NoteSpaceSettingsScreen({
    super.key,
    required this.noteSpace,
  });

  @override
  State<NoteSpaceSettingsScreen> createState() => _NoteSpaceSettingsScreenState();
}

class _NoteSpaceSettingsScreenState extends State<NoteSpaceSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _spaceRepository = NoteRepository();
  String _selectedLanguage = 'zh';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.noteSpace.name;
    _selectedLanguage = widget.noteSpace.language;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() {
          _isSaving = true;
        });
        
        final updatedSpace = widget.noteSpace.copyWith(
          name: _nameController.text,
          language: _selectedLanguage,
          updatedAt: DateTime.now(),
        );
        
        await _spaceRepository.updateNoteSpace(updatedSpace);
        
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('노트 스페이스가 업데이트되었습니다.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('업데이트 실패: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: ColorTokens.getColor('background'),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: ColorTokens.getColor('background'),
        appBar: AppBar(
          backgroundColor: ColorTokens.getColor('background'),
          elevation: 0,
          leading: IconButton(
            icon: SvgPicture.asset(
              'assets/icon/back.svg',
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                ColorTokens.getColor('text'),
                BlendMode.srcIn,
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Note Space Settings',
            style: TypographyTokens.getStyle('heading.h2'),
          ),
          centerTitle: true,
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Name',
                style: TypographyTokens.getStyle('body.medium').copyWith(
                  color: ColorTokens.getColor('text'),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Enter note space name',
                  hintStyle: TypographyTokens.getStyle('body.medium').copyWith(
                    color: ColorTokens.getColor('disabled'),
                  ),
                  filled: true,
                  fillColor: ColorTokens.getColor('surface'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Language',
                style: TypographyTokens.getStyle('body.medium').copyWith(
                  color: ColorTokens.getColor('text'),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: ColorTokens.getColor('surface'),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedLanguage,
                    isExpanded: true,
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: ColorTokens.getColor('text'),
                    ),
                    style: TypographyTokens.getStyle('body.medium').copyWith(
                      color: ColorTokens.getColor('text'),
                    ),
                    dropdownColor: ColorTokens.getColor('surface'),
                    items: const [
                      DropdownMenuItem(
                        value: 'zh',
                        child: Text('Chinese'),
                      ),
                      DropdownMenuItem(
                        value: 'ja',
                        child: Text('Japanese'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedLanguage = value;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorTokens.getColor('button-primary'),
                  foregroundColor: ColorTokens.getColor('surface'),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator()
                    : Text(
                        'Save Changes',
                        style: TypographyTokens.getStyle('button.medium'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 