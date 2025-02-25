import 'package:mlw/data/repositories/exam_repository.dart';

class ExamService {
  final ExamRepository _repository;

  ExamService({
    required ExamRepository repository,
  }) : _repository = repository;

  // 임시 메서드 (실제 구현은 필요할 때 추가)
  Future<void> tempMethod() async {
    await _repository.tempMethod();
  }
} 