import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_constants.dart';
import 'prefs_service.dart';
import 'db_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DbService _dbService = DbService();

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      User? user = result.user;
      if (user == null) throw Exception("User not found.");

      DocumentSnapshot userDoc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        await _auth.signOut();
        throw Exception("Your account role is not recognized by this system.");
      }

      var data = userDoc.data() as Map<String, dynamic>;
      String role = data['role'] ?? '';
      String name = data['name'] ?? '';
      String idNumber = data['idNumber'] ?? '';

      if (role.isEmpty) {
        await _auth.signOut();
        throw Exception("Your account role is not recognized by this system.");
      }

      await PrefsService.saveUserSession(
        uid: user.uid,
        role: role,
        name: name,
        id: idNumber,
      );

      await _dbService.writeAuditLog(
        userId: user.uid,
        role: role,
        action: 'USER_LOGIN: Successful login',
      );

      return {'uid': user.uid, 'role': role, 'name': name};
    } catch (e) {
      throw Exception(e.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim());
    }
  }

  Future<void> logout(String userId, String role) async {
    await _dbService.writeAuditLog(
      userId: userId,
      role: role,
      action: 'USER_LOGOUT: Manual signout',
    );
    await _auth.signOut();
    await PrefsService.clearSession();
  }

  Future<void> updateUserPassword(String newPassword) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception("No active session found. Please log in again.");
      }

      await user.updatePassword(newPassword.trim());

      await _dbService.writeAuditLog(
        userId: user.uid,
        role: 'unknown',
        action: 'PASSWORD_CHANGED: User updated their own password',
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception(
          'For security, please log out and log back in before changing your password.',
        );
      } else if (e.code == 'weak-password') {
        throw Exception('Password is too weak. Please choose a stronger one.');
      } else {
        throw Exception(e.message ?? 'Failed to update password.');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}
