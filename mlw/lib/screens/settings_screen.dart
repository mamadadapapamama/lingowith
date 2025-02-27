import 'package:flutter/material.dart';
import 'package:mlw/theme/tokens/color_tokens.dart';
import 'package:mlw/theme/tokens/typography_tokens.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String _userName = '';
  String _targetLanguage = '한국어';
  String _purpose = '본인의 언어 공부';
  bool _isLoading = true;
  
  // 언어 옵션
  final List<String> _languageOptions = ['한국어', '영어'];
  
  // 목적 옵션
  final List<String> _purposeOptions = [
    '본인의 언어 공부',
    '아이의 학습 보조',
    '외국어로 전문분야 공부'
  ];
  
  @override
  void initState() {
    super.initState();
    _loadUserSettings();
  }
  
  Future<void> _loadUserSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      _userName = prefs.getString('user_name') ?? '';
      _targetLanguage = prefs.getString('target_language') ?? '한국어';
      _purpose = prefs.getString('app_purpose') ?? '본인의 언어 공부';
      _isLoading = false;
    });
  }
  
  Future<void> _saveUserSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString('user_name', _userName);
    await prefs.setString('target_language', _targetLanguage);
    await prefs.setString('app_purpose', _purpose);
    
    setState(() {
      _isLoading = false;
    });
    
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('설정이 저장되었습니다'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  Future<void> _resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', false);
    
    if (!mounted) return;
    
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '설정',
          style: TypographyTokens.getStyle('heading.h4'),
        ),
        backgroundColor: ColorTokens.getColor('base.0'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 사용자 정보 섹션
                  Text(
                    '사용자 정보',
                    style: TypographyTokens.getStyle('heading.h5').copyWith(
                      color: ColorTokens.getColor('text.heading'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 이름 입력
                  TextField(
                    controller: TextEditingController(text: _userName),
                    onChanged: (value) {
                      _userName = value;
                    },
                    decoration: InputDecoration(
                      labelText: '이름',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: ColorTokens.getColor('base.0'),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // 앱 설정 섹션
                  Text(
                    '앱 설정',
                    style: TypographyTokens.getStyle('heading.h5').copyWith(
                      color: ColorTokens.getColor('text.heading'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 언어 선택
                  Text(
                    '번역 언어',
                    style: TypographyTokens.getStyle('body.medium').copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(
                    _languageOptions.length,
                    (index) => RadioListTile<String>(
                      title: Text(_languageOptions[index]),
                      value: _languageOptions[index],
                      groupValue: _targetLanguage,
                      onChanged: (value) {
                        setState(() {
                          _targetLanguage = value!;
                        });
                      },
                      activeColor: ColorTokens.getColor('primary.500'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // 목적 선택
                  Text(
                    '사용 목적',
                    style: TypographyTokens.getStyle('body.medium').copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(
                    _purposeOptions.length,
                    (index) => RadioListTile<String>(
                      title: Text(_purposeOptions[index]),
                      value: _purposeOptions[index],
                      groupValue: _purpose,
                      onChanged: (value) {
                        setState(() {
                          _purpose = value!;
                        });
                      },
                      activeColor: ColorTokens.getColor('primary.500'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // 저장 버튼
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveUserSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorTokens.getColor('primary.500'),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        '저장하기',
                        style: TypographyTokens.getStyle('button.medium'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 온보딩 다시 보기 버튼
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('온보딩 다시 보기'),
                            content: const Text('온보딩 화면을 다시 보시겠습니까?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('취소'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _resetOnboarding();
                                },
                                child: const Text('확인'),
                              ),
                            ],
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: ColorTokens.getColor('text.body'),
                      ),
                      child: Text(
                        '온보딩 다시 보기',
                        style: TypographyTokens.getStyle('button.medium'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
} 