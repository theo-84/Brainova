import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminLogger {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> logAction(String action,
      {Map<String, dynamic>? metadata}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('admin_logs').add({
        'adminUid': user.uid,
        'adminEmail': user.email,
        'action': action,
        'timestamp': FieldValue.serverTimestamp(),
        if (metadata != null) 'metadata': metadata,
      });
    } catch (e) {
      print('Error logging admin action: $e');
    }
  }
}
