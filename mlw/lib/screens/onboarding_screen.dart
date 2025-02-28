import 'package:flutter/material.dart';
import 'package:mlw/theme/tokens/color_tokens.dart';
import 'package:mlw/theme/tokens/typography_tokens.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mlw/screens/home/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  // 사용자 정보
  String _userName = '';
  String _targetLanguage = '한국어';
  String _purpose = '본인의 언어 공부';
  
  // 언어 옵션
  final List<String> _languageOptions = ['한국어', '영어'];
  
  // 목적 옵션
  final List<String> _purposeOptions = [
    '본인의 언어 공부',
    '아이의 학습 보조',
    '외국어로 전문분야 공부'
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    print('온보딩 완료 함수 시작');
    final prefs = await SharedPreferences.getInstance();
    
    // 온보딩 완료 상태 저장
    await prefs.setBool('onboarding_completed', true);
    print('온보딩 완료 상태 저장됨: ${await prefs.getBool('onboarding_completed')}');
    
    // 사용자 정보 저장
    await prefs.setString('user_name', _userName);
    await prefs.setString('target_language', _targetLanguage);
    await prefs.setString('app_purpose', _purpose);
    print('사용자 정보 저장됨: $_userName, $_targetLanguage, $_purpose');
    
    if (!mounted) return;
    print('네비게이션 시작');
    
    // 홈 화면으로 이동
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(userId: 'test_user_id'),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTokens.getColor('base.0'),
      body: SafeArea(
        child: Column(
          children: [
            // 진행 상태 표시
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: List.generate(
                  3,
                  (index) => Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: index <= _currentPage
                            ? ColorTokens.getColor('primary.500')
                            : ColorTokens.getColor('neutral.200'),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // 페이지 내용
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  // 1. 이름 입력 페이지
                  _buildNamePage(),
                  
                  // 2. 언어 선택 페이지
                  _buildLanguagePage(),
                  
                  // 3. 목적 선택 페이지
                  _buildPurposePage(),
                ],
              ),
            ),
            
            // 하단 버튼
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _currentPage == 0 && _userName.isEmpty
                      ? null
                      : _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorTokens.getColor('primary.500'),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _currentPage < 2 ? '다음' : '시작하기',
                    style: TypographyTokens.getStyle('button.medium'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 이름 입력 페이지
  Widget _buildNamePage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text(
            '안녕하세요!',
            style: TypographyTokens.getStyle('heading.h1').copyWith(
              color: ColorTokens.getColor('text.heading'),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '중국어 학습을 도와드릴게요.\n먼저 이름을 알려주세요.',
            style: TypographyTokens.getStyle('body.large').copyWith(
              color: ColorTokens.getColor('text.body'),
            ),
          ),
          const SizedBox(height: 40),
          TextField(
            onChanged: (value) {
              setState(() {
                _userName = value;
              });
            },
            decoration: InputDecoration(
              labelText: '이름',
              hintText: '이름을 입력해주세요',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: ColorTokens.getColor('base.0'),
            ),
          ),
        ],
      ),
    );
  }

  // 언어 선택 페이지
  Widget _buildLanguagePage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text(
            '번역 언어 선택',
            style: TypographyTokens.getStyle('heading.h1').copyWith(
              color: ColorTokens.getColor('text.heading'),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '중국어를 어떤 언어로 번역할까요?',
            style: TypographyTokens.getStyle('body.large').copyWith(
              color: ColorTokens.getColor('text.body'),
            ),
          ),
          const SizedBox(height: 40),
          ...List.generate(
            _languageOptions.length,
            (index) => RadioListTile<String>(
              title: Text(
                _languageOptions[index],
                style: TypographyTokens.getStyle('body.medium'),
              ),
              value: _languageOptions[index],
              groupValue: _targetLanguage,
              onChanged: (value) {
                setState(() {
                  _targetLanguage = value!;
                });
              },
              activeColor: ColorTokens.getColor('primary.500'),
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
            ),
          ),
        ],
      ),
    );
  }

  // 목적 선택 페이지
  Widget _buildPurposePage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text(
            '사용 목적',
            style: TypographyTokens.getStyle('heading.h1').copyWith(
              color: ColorTokens.getColor('text.heading'),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '어떤 목적으로 앱을 사용하시나요?',
            style: TypographyTokens.getStyle('body.large').copyWith(
              color: ColorTokens.getColor('text.body'),
            ),
          ),
          const SizedBox(height: 40),
          ...List.generate(
            _purposeOptions.length,
            (index) => RadioListTile<String>(
              title: Text(
                _purposeOptions[index],
                style: TypographyTokens.getStyle('body.medium'),
              ),
              value: _purposeOptions[index],
              groupValue: _purpose,
              onChanged: (value) {
                setState(() {
                  _purpose = value!;
                });
              },
              activeColor: ColorTokens.getColor('primary.500'),
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
            ),
          ),
        ],
      ),
    );
  }
} 