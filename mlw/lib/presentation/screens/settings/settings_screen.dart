import 'package:flutter/material.dart';
import 'package:mlw/core/di/service_locator.dart';
import 'package:mlw/presentation/screens/settings/settings_view_model.dart';
import 'package:mlw/data/models/text_display_mode.dart';
import 'package:mlw/data/models/user_settings.dart';

class SettingsScreen extends StatefulWidget {
  final String userId;
  
  const SettingsScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SettingsViewModel _viewModel;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _viewModel = serviceLocator.get<SettingsViewModel>();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _viewModel.loadUserSettings(widget.userId);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('설정을 불러오는 중 오류가 발생했습니다: $e')),
      );
    }
  }
  
  Future<void> _showLanguageSelectionDialog(
    BuildContext context,
    String title,
    String currentLanguage,
    Function(String) onSelected,
  ) async {
    final languages = ['한국어', '중국어', '영어', '일본어'];
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((language) {
            return ListTile(
              title: Text(language),
              trailing: language == currentLanguage
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                Navigator.pop(context);
                onSelected(language);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _showDisplayModeDialog(
    BuildContext context,
    TextDisplayMode currentMode,
  ) async {
    final modes = [
      {
        'mode': TextDisplayMode.original,
        'title': '원문만 표시',
        'subtitle': '원문 텍스트만 표시합니다',
      },
      {
        'mode': TextDisplayMode.translation,
        'title': '번역만 표시',
        'subtitle': '번역 텍스트만 표시합니다',
      },
      {
        'mode': TextDisplayMode.both,
        'title': '원문과 번역 모두 표시',
        'subtitle': '원문과 번역을 함께 표시합니다',
      },
    ];
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('표시 모드 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: modes.map((modeData) {
            final mode = modeData['mode'] as TextDisplayMode;
            return ListTile(
              title: Text(modeData['title'] as String),
              subtitle: Text(modeData['subtitle'] as String),
              trailing: mode == currentMode
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                Navigator.pop(context);
                _viewModel.updateDisplayMode(widget.userId, mode);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = _viewModel;
    final settings = viewModel.userSettings;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : settings == null
              ? const Center(child: Text('설정을 불러올 수 없습니다'))
              : ListView(
                  children: [
                    const ListTile(
                      title: Text('언어 설정'),
                      enabled: false,
                      dense: true,
                    ),
                    ListTile(
                      title: const Text('기본 언어'),
                      subtitle: Text(settings.preferredLanguage),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        _showLanguageSelectionDialog(
                          context,
                          '기본 언어 선택',
                          settings.preferredLanguage,
                          (language) {
                            viewModel.updateLanguageSettings(
                              widget.userId,
                              language,
                              settings.translationLanguage,
                            );
                          },
                        );
                      },
                    ),
                    ListTile(
                      title: const Text('번역 언어'),
                      subtitle: Text(settings.translationLanguage),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        _showLanguageSelectionDialog(
                          context,
                          '번역 언어 선택',
                          settings.translationLanguage,
                          (language) {
                            viewModel.updateLanguageSettings(
                              widget.userId,
                              settings.preferredLanguage,
                              language,
                            );
                          },
                        );
                      },
                    ),
                    const Divider(),
                    const ListTile(
                      title: Text('표시 설정'),
                      enabled: false,
                      dense: true,
                    ),
                    ListTile(
                      title: const Text('텍스트 표시 모드'),
                      subtitle: Text(_getDisplayModeText(settings.displayMode)),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        _showDisplayModeDialog(
                          context,
                          settings.displayMode,
                        );
                      },
                    ),
                    SwitchListTile(
                      title: const Text('하이라이트 활성화'),
                      subtitle: const Text('중요 단어를 강조 표시합니다'),
                      value: settings.highlightEnabled,
                      onChanged: (value) {
                        viewModel.updateHighlightSettings(
                          widget.userId,
                          value,
                        );
                      },
                    ),
                    const Divider(),
                    const ListTile(
                      title: Text('앱 설정'),
                      enabled: false,
                      dense: true,
                    ),
                    SwitchListTile(
                      title: const Text('다크 모드'),
                      subtitle: const Text('어두운 테마를 사용합니다'),
                      value: settings.darkModeEnabled,
                      onChanged: (value) {
                        viewModel.updateDarkModeSettings(
                          widget.userId,
                          value,
                        );
                      },
                    ),
                    SwitchListTile(
                      title: const Text('알림 활성화'),
                      subtitle: const Text('학습 알림을 받습니다'),
                      value: settings.notificationsEnabled,
                      onChanged: (value) {
                        viewModel.updateNotificationSettings(
                          widget.userId,
                          value,
                        );
                      },
                    ),
                    const Divider(),
                    const ListTile(
                      title: Text('앱 정보'),
                      enabled: false,
                      dense: true,
                    ),
                    const ListTile(
                      title: Text('버전'),
                      subtitle: Text('1.0.0'),
                    ),
                    const ListTile(
                      title: Text('개발자'),
                      subtitle: Text('MLW Team'),
                    ),
                  ],
                ),
    );
  }
  
  String _getDisplayModeText(TextDisplayMode mode) {
    switch (mode) {
      case TextDisplayMode.original:
        return '원문만 표시';
      case TextDisplayMode.translation:
        return '번역만 표시';
      case TextDisplayMode.both:
        return '원문과 번역 모두 표시';
      default:
        return '알 수 없음';
    }
  }
} 