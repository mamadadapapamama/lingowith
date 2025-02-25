import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mlw/presentation/screens/home/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: '중국어 학습을 더 쉽게',
      description: 'MLW와 함께 효율적으로 중국어를 학습하세요.',
      image: 'assets/images/onboarding1.png',
    ),
    OnboardingPage(
      title: '노트 작성 및 번역',
      description: '중국어 텍스트를 쉽게 번역하고 노트로 저장하세요.',
      image: 'assets/images/onboarding2.png',
    ),
    OnboardingPage(
      title: '플래시카드로 학습',
      description: '자동 생성된 플래시카드로 단어와 문장을 효과적으로 암기하세요.',
      image: 'assets/images/onboarding3.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPageIndicator(),
                  _buildButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            page.image,
            height: 240,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 240,
                width: 240,
                color: Colors.grey[300],
                child: const Icon(Icons.image, size: 80),
              );
            },
          ),
          const SizedBox(height: 32),
          Text(
            page.title,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildPageIndicator() {
    return Row(
      children: List.generate(
        _pages.length,
        (index) => Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == index
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
          ),
        ),
      ),
    );
  }
  
  Widget _buildButton() {
    return ElevatedButton(
      onPressed: () {
        if (_currentPage < _pages.length - 1) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else {
          _completeOnboarding();
        }
      },
      child: Text(_currentPage < _pages.length - 1 ? '다음' : '시작하기'),
    );
  }
  
  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    
    if (!mounted) return;
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const HomeScreen(userId: 'test_user_id'),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final String image;
  
  OnboardingPage({
    required this.title,
    required this.description,
    required this.image,
  });
} 