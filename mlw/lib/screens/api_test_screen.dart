import 'package:flutter/material.dart';
import 'package:googleapis/vision/v1.dart' as vision;
import 'package:googleapis/translate/v3.dart' as translate;
import 'package:googleapis/texttospeech/v1.dart' as tts;
import 'package:googleapis_auth/auth_io.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({super.key});

  @override
  State<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  String _result = '';

  Future<void> _testVision() async {
    try {
      final keyJson = await rootBundle.loadString('assets/service-account-key.json');
      final credentials = ServiceAccountCredentials.fromJson(
        json.decode(keyJson)
      );
      
      final client = await clientViaServiceAccount(
        credentials, 
        [vision.VisionApi.cloudVisionScope]
      );

      final api = vision.VisionApi(client);
      
      // 테스트 이미지 (base64로 인코딩된 이미지 데이터)
      const testImage = 'YOUR_BASE64_IMAGE';
      
      final request = vision.AnnotateImageRequest(
        image: vision.Image(content: testImage),
        features: [vision.Feature(type: 'TEXT_DETECTION')],
      );

      final response = await api.images.annotate(
        vision.BatchAnnotateImagesRequest(requests: [request])
      );

      setState(() {
        _result = 'Vision API 응답: ${response.responses?.first.textAnnotations?.first.description}';
      });

      client.close();
    } catch (e) {
      setState(() {
        _result = '에러 발생: $e';
      });
    }
  }

  Future<void> _testTranslate() async {
    try {
      final keyJson = await rootBundle.loadString('assets/service-account-key.json');
      final projectId = json.decode(keyJson)['project_id'] as String;
      
      final credentials = ServiceAccountCredentials.fromJson(
        json.decode(keyJson)
      );
      final client = await clientViaServiceAccount(
        credentials, 
        [translate.TranslateApi.cloudTranslationScope]
      );

      final api = translate.TranslateApi(client);
      
      final request = translate.TranslateTextRequest(
        contents: ['안녕하세요'],
        targetLanguageCode: 'en',
        sourceLanguageCode: 'ko',
      );

      final response = await api.projects.locations.translateText(
        request,
        'projects/$projectId/locations/global'
      );

      setState(() {
        _result = '번역 결과: ${response.translations?.first.translatedText}';
      });

      client.close();
    } catch (e) {
      setState(() {
        _result = '에러 발생: $e';
      });
    }
  }

  Future<void> _testTTS() async {
    try {
      final keyJson = await rootBundle.loadString('assets/service-account-key.json');
      final credentials = ServiceAccountCredentials.fromJson(
        json.decode(keyJson)
      );
      
      final client = await clientViaServiceAccount(
        credentials, 
        [tts.TexttospeechApi.cloudPlatformScope]
      );

      final api = tts.TexttospeechApi(client);
      
      final request = tts.SynthesizeSpeechRequest()
        ..input = (tts.SynthesisInput()..text = 'Hello, World!')
        ..voice = (tts.VoiceSelectionParams()
          ..languageCode = 'en-US'
          ..name = 'en-US-Standard-A')
        ..audioConfig = (tts.AudioConfig()..audioEncoding = 'MP3');

      final response = await api.text.synthesize(request);

      if (response.audioContent != null) {
        // 오디오 데이터를 파일로 저장하거나 재생
        setState(() {
          _result = 'TTS 성공: ${response.audioContent?.length} bytes';
        });
      }

      client.close();
    } catch (e) {
      setState(() {
        _result = '에러 발생: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API 테스트'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _testVision,
              child: const Text('Vision API 테스트'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _testTranslate,
              child: const Text('Translate API 테스트'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _testTTS,
              child: const Text('TTS API 테스트'),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(_result),
            ),
          ],
        ),
      ),
    );
  }
} 