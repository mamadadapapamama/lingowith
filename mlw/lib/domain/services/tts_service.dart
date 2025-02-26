import 'package:flutter_tts/flutter_tts.dart';

enum TtsState { playing, stopped, paused, continued }

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  TtsState _ttsState = TtsState.stopped;
  String _currentLanguage = 'zh-CN'; // 기본 언어 설정
  
  TtsService() {
    _initTts();
  }
  
  // TTS 초기화
  Future<void> _initTts() async {
    await _flutterTts.setLanguage('zh-CN'); // 기본 언어 설정
    await _flutterTts.setSpeechRate(0.5); // 말하기 속도 설정
    await _flutterTts.setVolume(1.0); // 볼륨 설정
    await _flutterTts.setPitch(1.0); // 음높이 설정
    
    _flutterTts.setStartHandler(() {
      _ttsState = TtsState.playing;
    });
    
    _flutterTts.setCompletionHandler(() {
      _ttsState = TtsState.stopped;
    });
    
    _flutterTts.setCancelHandler(() {
      _ttsState = TtsState.stopped;
    });
    
    _flutterTts.setPauseHandler(() {
      _ttsState = TtsState.paused;
    });
    
    _flutterTts.setContinueHandler(() {
      _ttsState = TtsState.continued;
    });
    
    _flutterTts.setErrorHandler((message) {
      print('TTS 오류: $message');
      _ttsState = TtsState.stopped;
    });
  }
  
  // 언어 설정
  Future<void> setLanguage(String language) async {
    if (_currentLanguage != language) {
      _currentLanguage = language;
      await _flutterTts.setLanguage(language);
    }
  }
  
  // 텍스트 읽기
  Future<void> speak(String text, {String language = 'zh-CN'}) async {
    await _flutterTts.setLanguage(language);
    await _flutterTts.speak(text);
  }
  
  // 읽기 중지
  Future<void> stop() async {
    await _flutterTts.stop();
    _ttsState = TtsState.stopped;
  }
  
  // 읽기 일시 중지
  Future<void> pause() async {
    await _flutterTts.pause();
    _ttsState = TtsState.paused;
  }
  
  // 현재 상태 확인
  TtsState get state => _ttsState;
  
  // 사용 가능한 언어 목록 가져오기
  Future<List<String>> getAvailableLanguages() async {
    final languages = await _flutterTts.getLanguages;
    return languages.cast<String>();
  }
  
  // 음성 속도 설정 (0.0 ~ 1.0)
  Future<void> setSpeechRate(double rate) async {
    await _flutterTts.setSpeechRate(rate);
  }
  
  // 음성 볼륨 설정 (0.0 ~ 1.0)
  Future<void> setVolume(double volume) async {
    await _flutterTts.setVolume(volume);
  }
  
  // 음성 피치 설정 (0.0 ~ 1.0)
  Future<void> setPitch(double pitch) async {
    await _flutterTts.setPitch(pitch);
  }
  
  // 리소스 해제
  void dispose() {
    _flutterTts.stop();
  }
} 