enum UserPurpose {
  supportingOthers,
  learningSelf,
  learningInForeignLanguage,
}

class OnboardingData {
  final UserPurpose? userPurpose;
  final String userName;
  final String preferredLanguage;
  final String learningLanguage;
  final bool completed;
  final bool highlightEnabled;
  final bool notificationsEnabled;
  
  OnboardingData({
    this.userPurpose,
    this.userName = '',
    this.preferredLanguage = '한국어',
    this.learningLanguage = '중국어',
    this.completed = false,
    this.highlightEnabled = true,
    this.notificationsEnabled = true,
  });
  
  OnboardingData copyWith({
    UserPurpose? userPurpose,
    String? userName,
    String? preferredLanguage,
    String? learningLanguage,
    bool? completed,
    bool? highlightEnabled,
    bool? notificationsEnabled,
  }) {
    return OnboardingData(
      userPurpose: userPurpose ?? this.userPurpose,
      userName: userName ?? this.userName,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      learningLanguage: learningLanguage ?? this.learningLanguage,
      completed: completed ?? this.completed,
      highlightEnabled: highlightEnabled ?? this.highlightEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'userPurpose': userPurpose?.index,
      'userName': userName,
      'preferredLanguage': preferredLanguage,
      'learningLanguage': learningLanguage,
      'completed': completed,
      'highlightEnabled': highlightEnabled,
      'notificationsEnabled': notificationsEnabled,
    };
  }
  
  factory OnboardingData.fromMap(Map<String, dynamic> map) {
    return OnboardingData(
      userPurpose: map['userPurpose'] != null 
          ? UserPurpose.values[map['userPurpose']] 
          : null,
      userName: map['userName'],
      preferredLanguage: map['preferredLanguage'],
      learningLanguage: map['learningLanguage'],
      completed: map['completed'] ?? false,
      highlightEnabled: map['highlightEnabled'] ?? true,
      notificationsEnabled: map['notificationsEnabled'] ?? true,
    );
  }
} 