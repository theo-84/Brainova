import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/user_model.dart';

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(FirebaseFirestore.instance),
);

class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  Future<void> createUser(UserModel user) async {
    await _usersCollection.doc(user.uid).set(user.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _usersCollection.doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!, uid);
    }
    return null;
  }

  Future<void> updateUser(UserModel user) async {
    await _usersCollection.doc(user.uid).update(user.toMap());
  }

  Future<void> updateLastLogin(String uid) async {
    await _usersCollection.doc(uid).update({
      'lastLoginAt': DateTime.now().toIso8601String(),
    });
  }

  Stream<UserModel?> watchUser(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, uid);
      }
      return null;
    });
  }

  Future<void> deleteUser(String uid) async {
    await _usersCollection.doc(uid).delete();
  }
}
