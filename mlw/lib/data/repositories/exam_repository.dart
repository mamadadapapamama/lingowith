import 'package:mlw/data/datasources/remote/firebase_data_source.dart';

class ExamRepository {
  final FirebaseDataSource _remoteDataSource;

  ExamRepository({
    required FirebaseDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  // 임시 메서드 (실제 구현은 필요할 때 추가)
  Future<void> tempMethod() async {
    // 실제 구현은 필요할 때 추가
  }
} 