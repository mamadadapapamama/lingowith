import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';
// firebase_storage 패키지 임시 대체
// import 'package:firebase_storage/firebase_storage.dart';

// 데이터 소스
import 'package:mlw/data/datasources/remote/firebase_data_source.dart';
import 'package:mlw/data/datasources/local/shared_preferences_data_source.dart';

// 리포지토리
import 'package:mlw/data/repositories/user_repository.dart';
import 'package:mlw/data/repositories/note_repository.dart';
import 'package:mlw/data/repositories/note_space_repository.dart';
import 'package:mlw/data/repositories/page_repository.dart';
import 'package:mlw/data/repositories/flash_card_repository.dart';

// 서비스
import 'package:mlw/domain/services/user_service.dart';
import 'package:mlw/domain/services/note_service.dart';
import 'package:mlw/domain/services/note_space_service.dart';
import 'package:mlw/domain/services/page_service.dart';
import 'package:mlw/domain/services/flash_card_service.dart';
import 'package:mlw/domain/services/image_processing_service.dart';
import 'package:mlw/domain/services/tts_service.dart';
import 'package:mlw/services/translator.dart';
import 'package:mlw/services/pinyin_service.dart';
import 'package:mlw/domain/services/notification_service.dart';
import 'package:mlw/domain/services/onboarding_service.dart';
import 'package:mlw/services/vision_api_service.dart';
import 'package:mlw/services/cloud_translation_service.dart';

// 뷰모델
// 존재하지 않는 파일 임포트 제거 또는 주석 처리
// import 'package:mlw/presentation/screens/auth/auth_view_model.dart';
import 'package:mlw/presentation/screens/home/home_view_model.dart';
import 'package:mlw/presentation/screens/note_detail/note_detail_view_model.dart';
import 'package:mlw/presentation/screens/flash_card/flash_card_view_model.dart';
import 'package:mlw/presentation/screens/onboarding/onboarding_view_model.dart';

// main.dart에서 정의된 useEmulator 변수 가져오기
import 'package:mlw/main.dart' show useEmulator;

final serviceLocator = GetIt.instance;

// FirebaseStorage 임시 구현 (실제 패키지 대신 사용)
class FirebaseStorage {
  static final instance = FirebaseStorage._();
  
  FirebaseStorage._();
  
  Reference ref() {
    return Reference();
  }
}

class Reference {
  Reference child(String path) {
    return Reference();
  }
  
  Future<UploadTask> putFile(File file) async {
    return UploadTask();
  }
  
  Future<String> getDownloadURL() async {
    return "https://example.com/image.jpg";
  }
}

class UploadTask {
  Future<TaskSnapshot> get onComplete => Future.value(TaskSnapshot());
}

class TaskSnapshot {
  Reference get ref => Reference();
  
  Future<String> getDownloadURL() async {
    return "https://example.com/image.jpg";
  }
}

// AuthViewModel 임시 구현
class AuthViewModel {
  final UserService userService;
  
  AuthViewModel({required this.userService});
}

Future<void> setupServiceLocator() async {
  // Firebase (테스트 모드에 따라 다르게 등록)
  if (useEmulator) {
    // 테스트 모드: 가짜 Firestore 사용
    serviceLocator.registerLazySingleton<FirebaseFirestore>(
      () => FakeFirebaseFirestore(),
    );
  } else {
    // 실제 모드: 실제 Firestore 사용
    serviceLocator.registerLazySingleton<FirebaseFirestore>(
      () => FirebaseFirestore.instance,
    );
  }
  
  // FirebaseAuth 등록
  serviceLocator.registerLazySingleton<FirebaseAuth>(
    () => FirebaseAuth.instance,
  );
  
  // FirebaseStorage 등록
  serviceLocator.registerLazySingleton<FirebaseStorage>(
    () => FirebaseStorage.instance,
  );
  
  // SharedPreferences 등록
  final sharedPreferences = await SharedPreferences.getInstance();
  serviceLocator.registerLazySingleton<SharedPreferences>(
    () => sharedPreferences,
  );
  
  // FlutterLocalNotificationsPlugin 등록
  serviceLocator.registerLazySingleton<FlutterLocalNotificationsPlugin>(
    () => FlutterLocalNotificationsPlugin(),
  );
  
  // 데이터 소스 등록
  serviceLocator.registerLazySingleton<FirebaseDataSource>(
    () => FirebaseDataSource(
      firestore: serviceLocator<FirebaseFirestore>(),
    ),
  );
  
  serviceLocator.registerLazySingleton<SharedPreferencesDataSource>(
    () => SharedPreferencesDataSource(
      sharedPreferences: serviceLocator<SharedPreferences>(),
    ),
  );
  
  // 리포지토리 등록
  serviceLocator.registerLazySingleton<UserRepository>(
    () => UserRepository(
      remoteDataSource: serviceLocator<FirebaseDataSource>(),
      localDataSource: serviceLocator<SharedPreferencesDataSource>(),
    ),
  );
  
  serviceLocator.registerLazySingleton<NoteRepository>(
    () => NoteRepository(
      remoteDataSource: serviceLocator<FirebaseDataSource>(),
    ),
  );
  
  serviceLocator.registerLazySingleton<NoteSpaceRepository>(
    () => NoteSpaceRepository(
      remoteDataSource: serviceLocator<FirebaseDataSource>(),
    ),
  );
  
  serviceLocator.registerLazySingleton<PageRepository>(
    () => PageRepository(
      remoteDataSource: serviceLocator<FirebaseDataSource>(),
    ),
  );
  
  serviceLocator.registerLazySingleton<FlashCardRepository>(
    () => FlashCardRepository(
      remoteDataSource: serviceLocator<FirebaseDataSource>(),
    ),
  );
  
  // 서비스 등록
  serviceLocator.registerLazySingleton<TranslatorService>(
    () => TranslatorService(),
  );
  
  serviceLocator.registerLazySingleton<PinyinService>(
    () => PinyinService(),
  );
  
  serviceLocator.registerLazySingleton<UserService>(
    () => UserService(
      repository: serviceLocator<UserRepository>(),
    ),
  );
  
  serviceLocator.registerLazySingleton<ImageProcessingService>(
    () => ImageProcessingService(
      translatorService: serviceLocator<TranslatorService>(),
      pinyinService: serviceLocator<PinyinService>(),
      storage: serviceLocator<FirebaseStorage>(),
      visionApiService: serviceLocator<VisionApiService>(),
    ),
  );
  
  serviceLocator.registerLazySingleton<NoteService>(
    () => NoteService(
      repository: serviceLocator<NoteRepository>(),
      imageProcessingService: serviceLocator<ImageProcessingService>(),
      translatorService: serviceLocator<TranslatorService>(),
      pinyinService: serviceLocator<PinyinService>(),
    ),
  );
  
  serviceLocator.registerLazySingleton<NoteSpaceService>(
    () => NoteSpaceService(
      repository: serviceLocator<NoteSpaceRepository>(),
    ),
  );
  
  serviceLocator.registerLazySingleton<PageService>(
    () => PageService(
      pageRepository: serviceLocator<PageRepository>(),
      noteRepository: serviceLocator<NoteRepository>(),
      imageProcessingService: serviceLocator<ImageProcessingService>(),
    ),
  );
  
  serviceLocator.registerLazySingleton<FlashCardService>(
    () => FlashCardService(
      repository: serviceLocator<FlashCardRepository>(),
      translatorService: serviceLocator<TranslatorService>(),
      pinyinService: serviceLocator<PinyinService>(),
    ),
  );
  
  serviceLocator.registerLazySingleton<TtsService>(
    () => TtsService(),
  );
  
  serviceLocator.registerLazySingleton<NotificationService>(
    () => NotificationService(
      notificationsPlugin: serviceLocator<FlutterLocalNotificationsPlugin>(),
    ),
  );
  
  serviceLocator.registerLazySingleton<OnboardingService>(
    () => OnboardingService(
      repository: serviceLocator<UserRepository>(),
    ),
  );
  
  serviceLocator.registerLazySingleton<VisionApiService>(
    () => VisionApiService(),
  );
  
  serviceLocator.registerLazySingleton<CloudTranslationService>(
    () => CloudTranslationService(),
  );
  
  // ViewModels 등록
  serviceLocator.registerFactory<AuthViewModel>(
    () => AuthViewModel(
      userService: serviceLocator<UserService>(),
    ),
  );
  
  serviceLocator.registerFactory<HomeViewModel>(
    () => HomeViewModel(
      userService: serviceLocator<UserService>(),
      noteService: serviceLocator<NoteService>(),
    ),
  );
  
  serviceLocator.registerFactory<NoteDetailViewModel>(
    () => NoteDetailViewModel(
      noteService: serviceLocator<NoteService>(),
      flashCardService: serviceLocator<FlashCardService>(),
      translatorService: serviceLocator<TranslatorService>(),
    ),
  );
  
  serviceLocator.registerFactory<FlashCardViewModel>(
    () => FlashCardViewModel(
      flashCardService: serviceLocator<FlashCardService>(),
      ttsService: serviceLocator<TtsService>(),
    ),
  );
  
  serviceLocator.registerFactory<OnboardingViewModel>(
    () => OnboardingViewModel(
      userService: serviceLocator<UserService>(),
      onboardingService: serviceLocator<OnboardingService>(),
    ),
  );
} 