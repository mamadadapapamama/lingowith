import 'package:flutter_test/flutter_test.dart';
import 'package:mlw/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('User', () {
    test('should create User instance with required parameters', () {
      final now = DateTime.now();
      final user = User(
        id: '1',
        name: 'Test User',
        createdAt: now,
        updatedAt: now,
      );

      expect(user.id, '1');
      expect(user.name, 'Test User');
      expect(user.createdAt, now);
      expect(user.updatedAt, now);
    });

    test('should create User from Firestore data', () {
      final now = Timestamp.now();
      final data = {
        'name': 'Test User',
        'createdAt': now,
        'updatedAt': now,
      };

      final user = User.fromFirestore(data, '1');

      expect(user.id, '1');
      expect(user.name, 'Test User');
      expect(user.createdAt, now.toDate());
      expect(user.updatedAt, now.toDate());
    });

    test('should convert User to Firestore data', () {
      final now = DateTime.now();
      final user = User(
        id: '1',
        name: 'Test User',
        createdAt: now,
        updatedAt: now,
      );

      final data = user.toFirestore();

      expect(data['name'], 'Test User');
      expect(data['createdAt'], now);
      expect(data['updatedAt'], now);
    });

    test('should create copy with updated fields', () {
      final now = DateTime.now();
      final user = User(
        id: '1',
        name: 'Test User',
        createdAt: now,
        updatedAt: now,
      );

      final updated = user.copyWith(
        name: 'Updated User',
      );

      expect(updated.id, '1');  // unchanged
      expect(updated.name, 'Updated User');  // changed
      expect(updated.createdAt, now);  // unchanged
      expect(updated.updatedAt, isNot(now));  // should be updated
    });
  });
} 