import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mlw/core/di/service_locator.dart';
import 'package:mlw/presentation/screens/onboarding/onboarding_view_model.dart';
import 'package:mlw/presentation/theme/color_tokens.dart';
import 'package:mlw/presentation/widgets/custom_button.dart';
import 'package:mlw/presentation/theme/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _viewModel = serviceLocator<OnboardingViewModel>();
  final _pageController = PageController();
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _viewModel.setCurrentPage(index);
                  });
                },
                children: [
                  _buildWelcomePage(),
                  _buildLanguagePage(),
                  _buildPreferencesPage(),
                ],
              ),
            ),
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Pikabook에 오신 것을 환영합니다!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          const Text(
            '이 앱은 중국어 학습을 도와주는 다양한 기능을 제공합니다.',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            '시작하기 전에 몇 가지 설정이 필요합니다.',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          TextField(
            decoration: const InputDecoration(
              labelText: '이름',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _viewModel.setUserName(value);
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildLanguagePage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '언어 설정',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          const Text(
            '선호하는 언어와 학습하려는 언어를 선택해주세요.',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: '선호하는 언어',
              border: OutlineInputBorder(),
            ),
            value: '한국어',
            items: const [
              DropdownMenuItem(value: '한국어', child: Text('한국어')),
              DropdownMenuItem(value: '영어', child: Text('영어')),
            ],
            onChanged: (value) {
              if (value != null) {
                _viewModel.setPreferredLanguage(value);
              }
            },
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: '학습 언어',
              border: OutlineInputBorder(),
            ),
            value: '중국어',
            items: const [
              DropdownMenuItem(value: '중국어', child: Text('중국어')),
              DropdownMenuItem(value: '일본어', child: Text('일본어')),
              DropdownMenuItem(value: '영어', child: Text('영어')),
            ],
            onChanged: (value) {
              if (value != null) {
                _viewModel.setLearningLanguage(value);
              }
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildPreferencesPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '앱 설정',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          const Text(
            '앱 사용 경험을 개선하기 위한 설정을 선택해주세요.',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          SwitchListTile(
            title: const Text('하이라이트 기능 사용'),
            subtitle: const Text('텍스트에서 중요한 부분을 하이라이트합니다.'),
            value: _viewModel.data.highlightEnabled,
            onChanged: (value) {
              setState(() {
                _viewModel.data = _viewModel.data.copyWith(highlightEnabled: value);
              });
            },
          ),
          SwitchListTile(
            title: const Text('알림 받기'),
            subtitle: const Text('학습 알림을 받습니다.'),
            value: _viewModel.data.notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _viewModel.data = _viewModel.data.copyWith(notificationsEnabled: value);
              });
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _viewModel.currentPage > 0
              ? TextButton(
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: const Text('이전'),
                )
              : const SizedBox(width: 80),
          _buildPageIndicator(),
          _viewModel.currentPage < 2
              ? TextButton(
                  onPressed: () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: const Text('다음'),
                )
              : TextButton(
                  onPressed: _completeOnboarding,
                  child: const Text('완료'),
                ),
        ],
      ),
    );
  }
  
  Widget _buildPageIndicator() {
    return Row(
      children: List.generate(3, (index) {
        return Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _viewModel.currentPage == index
                ? AppColors.primary
                : Colors.grey.shade300,
          ),
        );
      }),
    );
  }
  
  void _completeOnboarding() async {
    final success = await _viewModel.completeOnboarding();
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('온보딩을 완료하는 중 오류가 발생했습니다: ${_viewModel.error}')),
      );
    }
  }
} 