import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mlw/data/datasources/remote/firebase_data_source.dart';
import 'package:mlw/data/models/page.dart';

class PageRepository {
  final FirebaseDataSource remoteDataSource;
  static const String _collection = 'pages';
  
  PageRepository({required this.remoteDataSource});
  
  // 페이지 생성
  Future<Page> createPage(Page page) async {
    try {
      final docRef = await remoteDataSource.addDocument(_collection, page.toMap());
      return page.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('페이지를 생성하는 중 오류가 발생했습니다: $e');
    }
  }
  
  // 노트별 페이지 목록 조회
  Future<List<Page>> getPagesByNoteId(String noteId) async {
    try {
      final snapshot = await remoteDataSource.getDocuments(
        _collection,
        [
          ['noteId', '==', noteId],
        ],
      );
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Page.fromMap({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      throw Exception('노트의 페이지 목록을 가져오는 중 오류가 발생했습니다: $e');
    }
  }
  
  // 페이지 상세 조회
  Future<Page?> getPageById(String id) async {
    try {
      final doc = await remoteDataSource.getDocument(_collection, id);
      if (!doc.exists) {
        return null;
      }
      
      final data = doc.data() as Map<String, dynamic>;
      return Page.fromMap({...data, 'id': doc.id});
    } catch (e) {
      throw Exception('페이지를 가져오는 중 오류가 발생했습니다: $e');
    }
  }
  
  // 페이지 업데이트
  Future<void> updatePage(Page page) async {
    try {
      await remoteDataSource.updateDocument(
        _collection,
        page.id,
        page.toMap(),
      );
    } catch (e) {
      throw Exception('페이지를 업데이트하는 중 오류가 발생했습니다: $e');
    }
  }
  
  // 페이지 삭제
  Future<void> deletePage(String id) async {
    try {
      await remoteDataSource.deleteDocument(_collection, id);
    } catch (e) {
      throw Exception('페이지를 삭제하는 중 오류가 발생했습니다: $e');
    }
  }
  
  // 하이라이트 위치 업데이트
  Future<void> updateHighlightPositions(String pageId, List<int> positions) async {
    try {
      final page = await getPageById(pageId);
      if (page == null) {
        throw Exception('페이지를 찾을 수 없습니다');
      }
      
      await updatePage(page.copyWith(
        highlightedPositions: positions,
        updatedAt: DateTime.now(),
      ));
    } catch (e) {
      throw Exception('하이라이트 위치를 업데이트하는 중 오류가 발생했습니다: $e');
    }
  }
} 