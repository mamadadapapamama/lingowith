import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mlw/models/note.dart';
import 'package:mlw/theme/tokens/color_tokens.dart';
import 'package:mlw/theme/tokens/typography_tokens.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mlw/widgets/flash_card.dart' as flash_card_widget;

class FlashCardScreen extends StatefulWidget {
  final List<FlashCard> flashCards;

  const FlashCardScreen({
    super.key,
    required this.flashCards,
  });

  @override
  State<FlashCardScreen> createState() => _FlashCardScreenState();
}

class _FlashCardScreenState extends State<FlashCardScreen> {
  int _currentIndex = 0;
  bool _showFront = true;

  void _nextCard() {
    setState(() {
      if (_currentIndex < widget.flashCards.length - 1) {
        _currentIndex++;
        _showFront = true;
      }
    });
  }

  void _previousCard() {
    setState(() {
      if (_currentIndex > 0) {
        _currentIndex--;
        _showFront = true;
      }
    });
  }

  void _flipCard() {
    setState(() {
      _showFront = !_showFront;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: theme.scaffoldBackgroundColor,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Flash Cards',
            style: theme.textTheme.headlineMedium,
          ),
          centerTitle: true,
        ),
        body: widget.flashCards.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/images/zero_flashcard.svg',
                      width: 48,
                      height: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No flash cards yet',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Highlight text to create flash cards',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_currentIndex + 1} / ${widget.flashCards.length}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                          ),
                        ),
                        TextButton(
                          onPressed: _flipCard,
                          child: Text(
                            'Flip',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: flash_card_widget.FlashCard(
                        front: widget.flashCards[_currentIndex].front,
                        back: widget.flashCards[_currentIndex].back,
                        showFront: _showFront,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: EdgeInsets.only(
                      left: 24,
                      right: 24,
                      bottom: MediaQuery.of(context).padding.bottom + 24,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: _currentIndex > 0 ? _previousCard : null,
                          icon: Icon(
                            Icons.arrow_back_ios,
                            color: _currentIndex > 0
                                ? theme.iconTheme.color
                                : theme.disabledColor,
                          ),
                        ),
                        IconButton(
                          onPressed: _currentIndex < widget.flashCards.length - 1
                              ? _nextCard
                              : null,
                          icon: Icon(
                            Icons.arrow_forward_ios,
                            color: _currentIndex < widget.flashCards.length - 1
                                ? theme.iconTheme.color
                                : theme.disabledColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
} 