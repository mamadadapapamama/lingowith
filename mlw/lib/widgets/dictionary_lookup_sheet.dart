import 'package:flutter/material.dart';
import 'package:mlw/theme/tokens/color_tokens.dart';
import 'package:mlw/theme/tokens/typography_tokens.dart';
import 'package:mlw/models/dictionary_result.dart';
import 'package:mlw/services/dictionary_service.dart';

class DictionaryLookupSheet extends StatelessWidget {
  final String word;
  final ScrollController scrollController;

  const DictionaryLookupSheet({
    Key? key,
    required this.word,
    required this.scrollController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorTokens.getColor('base.0'),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: FutureBuilder<DictionaryResult>(
        future: DictionaryService().lookup(word),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('검색 중 오류가 발생했습니다'));
          }

          final result = snapshot.data!;
          
          return ListView(
            controller: scrollController,
            padding: EdgeInsets.all(24),
            children: [
              // 단어 (간체)
              Text(
                result.simplified,
                style: TypographyTokens.getStyle('heading.h3').copyWith(
                  color: ColorTokens.getColor('text.body'),
                ),
              ),
              SizedBox(height: 8),
              
              // 병음
              Text(
                result.pinyin,
                style: TypographyTokens.getStyle('body.medium').copyWith(
                  color: ColorTokens.getColor('text.translation'),
                ),
              ),
              SizedBox(height: 16),
              
              // HSK 레벨
              if (result.hskLevel != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: ColorTokens.getColor('tertiary.400'),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'HSK ${result.hskLevel}',
                    style: TypographyTokens.getStyle('button.small').copyWith(
                      color: ColorTokens.getColor('text.body'),
                    ),
                  ),
                ),
              SizedBox(height: 24),
              
              // 뜻 목록
              ...result.meanings.map((meaning) => Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  meaning,
                  style: TypographyTokens.getStyle('body.medium').copyWith(
                    color: ColorTokens.getColor('text.body'),
                  ),
                ),
              )),
              SizedBox(height: 24),
              
              // 예문
              ...result.examples.map((example) => Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  example,
                  style: TypographyTokens.getStyle('body.small').copyWith(
                    color: ColorTokens.getColor('text.body'),
                  ),
                ),
              )),
            ],
          );
        },
      ),
    );
  }
} 