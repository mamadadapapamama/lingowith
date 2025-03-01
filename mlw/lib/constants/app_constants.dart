/// 앱 전체에서 사용되는 상수 정의
class AppConstants {
  /// 기본 노트 스페이스 이름
  static const defaultSpaceName = 'Chinese book';
  
  /// 기본 언어 설정
  static const defaultLanguage = 'zh';
  
  /// 번역 대상 언어
  static const translationLanguage = 'ko';
  
  /// 플래시카드 관련 상수
  static const int maxFlashcardsPerSession = 20;
  
  /// 이미지 처리 관련 상수
  static const int maxImageWidth = 1200;
  static const int maxImageHeight = 1200;
  static const int imageQuality = 85;
  
  /// API 관련 상수
  static const int apiTimeoutSeconds = 30;
}

// 앱 정보
class AppInfo {
  static const String appName = 'MLW';
  static const String appVersion = '1.0.0';
  static const String appDescription = '언어 학습을 위한 노트 앱';
  static const String appAuthor = 'MLW Team';
  static const String appWebsite = 'https://mlw.app';
  static const String appEmail = 'support@mlw.app';
}

// 라우트 경로
class Routes {
  static const String home = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String onboarding = '/onboarding';
  static const String settings = '/settings';
  static const String noteDetail = '/note-detail';
  static const String createNote = '/create-note';
  static const String noteSpace = '/note-space';
  static const String flashcard = '/flashcard';
  static const String imageViewer = '/image-viewer';
}

// API 관련 상수
class ApiConstants {
  static const String baseUrl = 'https://api.mlw.app';
  static const int timeoutDuration = 30; // 초 단위
  static const int maxRetries = 3;
}

// 파이어베이스 컬렉션 이름
class FirestoreCollections {
  static const String users = 'users';
  static const String notes = 'notes';
  static const String noteSpaces = 'note_spaces';
  static const String flashcards = 'flashcards';
}

// 로컬 저장소 키
class StorageKeys {
  static const String userToken = 'user_token';
  static const String userId = 'user_id';
  static const String userEmail = 'user_email';
  static const String userLanguage = 'user_language';
  static const String lastLoginDate = 'last_login_date';
  static const String onboardingCompleted = 'onboarding_completed';
  static const String darkModeEnabled = 'dark_mode_enabled';
  static const String notificationEnabled = 'notification_enabled';
}

// 앱 설정 기본값
class DefaultSettings {
  static const bool darkMode = false;
  static const bool notifications = true;
  static const String defaultLanguage = 'ko';
  static const int autoSaveInterval = 30; // 초 단위
  static const int maxNoteLength = 10000;
  static const int maxFlashcardsPerNote = 100;
}

// 애니메이션 지속 시간
class AnimationDurations {
  static const Duration short = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 500);
  static const Duration long = Duration(milliseconds: 800);
}

// 오류 메시지
class ErrorMessages {
  static const String networkError = '네트워크 연결을 확인해주세요.';
  static const String serverError = '서버 오류가 발생했습니다. 나중에 다시 시도해주세요.';
  static const String authError = '인증에 실패했습니다. 다시 로그인해주세요.';
  static const String unknownError = '알 수 없는 오류가 발생했습니다.';
  static const String dataLoadError = '데이터를 불러오는 중 오류가 발생했습니다.';
  static const String dataSaveError = '데이터를 저장하는 중 오류가 발생했습니다.';
}

// 지원되는 언어 목록
class SupportedLanguages {
  static const Map<String, String> languages = {
    'ko': '한국어',
    'en': '영어',
    'ja': '일본어',
    'zh-cn': '중국어 (간체)',
    'zh-tw': '중국어 (번체)',
    'es': '스페인어',
    'fr': '프랑스어',
    'de': '독일어',
    'ru': '러시아어',
    'it': '이탈리아어',
    'vi': '베트남어',
    'th': '태국어',
    'id': '인도네시아어',
  };
}

// 앱 내 사용되는 아이콘 이름
class AppIcons {
  static const String note = 'note';
  static const String flashcard = 'flashcard';
  static const String settings = 'settings';
  static const String translate = 'translate';
  static const String camera = 'camera';
  static const String gallery = 'gallery';
  static const String edit = 'edit';
  static const String delete = 'delete';
  static const String share = 'share';
  static const String search = 'search';
  static const String add = 'add';
  static const String back = 'back';
  static const String close = 'close';
  static const String save = 'save';
  static const String user = 'user';
  static const String logout = 'logout';
}

// 앱 내 사용되는 이미지 경로
class AppImages {
  static const String logo = 'assets/images/logo.png';
  static const String onboarding1 = 'assets/images/onboarding1.png';
  static const String onboarding2 = 'assets/images/onboarding2.png';
  static const String onboarding3 = 'assets/images/onboarding3.png';
  static const String placeholder = 'assets/images/placeholder.png';
  static const String emptyState = 'assets/images/empty_state.png';
  static const String errorState = 'assets/images/error_state.png';
} 