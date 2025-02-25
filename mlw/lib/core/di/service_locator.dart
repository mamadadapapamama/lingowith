import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 데이터 소스
import 'package:mlw/data/datasources/remote/firebase_data_source.dart';
import 'package:mlw/data/datasources/local/shared_preferences_data_source.dart';

// 리포지토리
import 'package:mlw/data/repositories/user_repository.dart';
import 'package:mlw/data/repositories/note_repository.dart';
import 'package:mlw/data/repositories/flash_card_repository.dart';
import 'package:mlw/data/repositories/exam_repository.dart';

// 서비스
import 'package:mlw/domain/services/user_service.dart';
import 'package:mlw/domain/services/note_service.dart';
import 'package:mlw/domain/services/flash_card_service.dart';
import 'package:mlw/domain/services/exam_service.dart';
import 'package:mlw/domain/services/notification_service.dart';
import 'package:mlw/domain/services/image_processing_service.dart';
import 'package:mlw/services/translator.dart';
import 'package:mlw/services/pinyin_service.dart';

// 뷰모델
import 'package:mlw/presentation/screens/home/home_view_model.dart';
import 'package:mlw/presentation/screens/note_detail/note_detail_view_model.dart';
import 'package:mlw/presentation/screens/flash_card/flash_card_view_model.dart';
import 'package:mlw/presentation/screens/settings/settings_view_model.dart';
import 'package:mlw/presentation/screens/onboarding/onboarding_view_model.dart';

// GetIt 대신 간단한 서비스 로케이터 구현
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  final Map<Type, dynamic> _services = {};

  T get<T>() {
    if (!_services.containsKey(T)) {
      throw Exception('Service of type $T not registered');
    }
    return _services[T] as T;
  }

  void registerSingleton<T>(T service) {
    _services[T] = service;
  }

  void registerLazySingleton<T>(T Function() factory) {
    _services[T] = factory();
  }

  void registerFactory<T>(T Function() factory) {
    _services[T] = factory;
  }

  T getFactory<T>() {
    if (!_services.containsKey(T)) {
      throw Exception('Factory of type $T not registered');
    }
    final factory = _services[T] as T Function();
    return factory();
  }
}

final serviceLocator = ServiceLocator();

Future<void> setupServiceLocator() async {
  // 외부 의존성
  final firestore = FirebaseFirestore.instance;
  final preferences = await SharedPreferences.getInstance();
  
  // 데이터 소스
  serviceLocator.registerSingleton<FirebaseDataSource>(
    FirebaseDataSource(firestore: firestore),
  );
  
  serviceLocator.registerSingleton<SharedPreferencesDataSource>(
    SharedPreferencesDataSource(preferences: preferences),
  );
  
  // 리포지토리
  serviceLocator.registerLazySingleton<UserRepository>(
    () => UserRepository(
      remoteDataSource: serviceLocator.get<FirebaseDataSource>(),
      localDataSource: serviceLocator.get<SharedPreferencesDataSource>(),
    ),
  );
  
  serviceLocator.registerLazySingleton<NoteRepository>(
    () => NoteRepository(
      remoteDataSource: serviceLocator.get<FirebaseDataSource>(),
    ),
  );
  
  serviceLocator.registerLazySingleton<FlashCardRepository>(
    () => FlashCardRepository(
      remoteDataSource: serviceLocator.get<FirebaseDataSource>(),
    ),
  );
  
  serviceLocator.registerLazySingleton<ExamRepository>(
    () => ExamRepository(
      remoteDataSource: serviceLocator.get<FirebaseDataSource>(),
    ),
  );
  
  // 서비스
  serviceLocator.registerLazySingleton<TranslatorService>(
    () => TranslatorService(),
  );
  
  serviceLocator.registerLazySingleton<PinyinService>(
    () => PinyinService(),
  );
  
  serviceLocator.registerLazySingleton<UserService>(
    () => UserService(
      repository: serviceLocator.get<UserRepository>(),
    ),
  );
  
  serviceLocator.registerLazySingleton<NoteService>(
    () => NoteService(
      repository: serviceLocator.get<NoteRepository>(),
      imageProcessingService: serviceLocator.get<ImageProcessingService>(),
      translatorService: serviceLocator.get<TranslatorService>(),
      pinyinService: serviceLocator.get<PinyinService>(),
    ),
  );
  
  serviceLocator.registerLazySingleton<FlashCardService>(
    () => FlashCardService(
      repository: serviceLocator.get<FlashCardRepository>(),
      translatorService: serviceLocator.get<TranslatorService>(),
      pinyinService: serviceLocator.get<PinyinService>(),
    ),
  );
  
  serviceLocator.registerLazySingleton<ExamService>(
    () => ExamService(
      repository: serviceLocator.get<ExamRepository>(),
    ),
  );
  
  serviceLocator.registerLazySingleton<NotificationService>(
    () => NotificationService(
      notificationsPlugin: Object(), // 더미 객체 전달
    ),
  );
  
  serviceLocator.registerLazySingleton<ImageProcessingService>(
    () => ImageProcessingService(
      translatorService: serviceLocator.get<TranslatorService>(),
    ),
  );
  
  // 뷰모델
  serviceLocator.registerFactory<HomeViewModel>(
    () => HomeViewModel(
      noteService: serviceLocator.get<NoteService>(),
      userService: serviceLocator.get<UserService>(),
    ),
  );
  
  serviceLocator.registerFactory<NoteDetailViewModel>(
    () => NoteDetailViewModel(
      noteService: serviceLocator.get<NoteService>(),
      flashCardService: serviceLocator.get<FlashCardService>(),
      translatorService: serviceLocator.get<TranslatorService>(),
    ),
  );
  
  serviceLocator.registerFactory<FlashCardViewModel>(
    () => FlashCardViewModel(
      flashCardService: serviceLocator.get<FlashCardService>(),
    ),
  );
  
  serviceLocator.registerFactory<SettingsViewModel>(
    () => SettingsViewModel(
      userService: serviceLocator.get<UserService>(),
      notificationService: serviceLocator.get<NotificationService>(),
    ),
  );
  
  serviceLocator.registerFactory<OnboardingViewModel>(
    () => OnboardingViewModel(
      userService: serviceLocator.get<UserService>(),
    ),
  );
} 