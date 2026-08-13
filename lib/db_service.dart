import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:intl/intl.dart';
import 'dart:io' show Platform;
import 'app_constants.dart';

class DbService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown_ios_device';
      }
    } catch (e) {
      return 'unknown_device';
    }
    return 'unknown_device';
  }

  Future<void> writeAuditLog({
    required String userId,
    required String role,
    required String action,
  }) async {
    try {
      await _firestore.collection(AppConstants.collectionLogs).add({
        'userId': userId,
        'role': role,
        'action': action,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Failed to write audit log: $e');
    }
  }

  Stream<QuerySnapshot> streamTeacherSubjects(String teacherUid) {
    return _firestore
        .collection(AppConstants.collectionSubjects)
        .where('assignedTeacherId', isEqualTo: teacherUid)
        .snapshots();
  }

  Future<String> createAttendanceSession({
    required String subjectId,
    required String teacherId,
    required String batch,
    required String initialPayload,
  }) async {
    try {
      DocumentReference docRef = await _firestore
          .collection(AppConstants.collectionSessions)
          .add({
            'subjectId': subjectId,
            'teacherId': teacherId,
            'batch': batch,
            'startTime': FieldValue.serverTimestamp(),
            'expiresAt': null,
            'status': 'active',
            'currentQrPayload': initialPayload,
          });

      DocumentSnapshot confirmed = await docRef.get(
        const GetOptions(source: Source.server),
      );
      Timestamp serverStart = confirmed['startTime'];
      Timestamp expiresAt = Timestamp.fromDate(
        serverStart.toDate().add(const Duration(minutes: 2)),
      );
      await docRef.update({'expiresAt': expiresAt});

      await writeAuditLog(
        userId: teacherId,
        role: 'teacher',
        action: 'CREATED_SESSION: Subject $subjectId Batch $batch',
      );

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to start session: $e');
    }
  }

  Future<void> updateSessionPayload(String sessionId, String newPayload) async {
    try {
      await _firestore
          .collection(AppConstants.collectionSessions)
          .doc(sessionId)
          .update({'currentQrPayload': newPayload});
    } catch (e) {
      print('Failed to rotate QR payload: $e');
    }
  }

  Future<void> closeAttendanceSession(
    String sessionId,
    String teacherId,
  ) async {
    try {
      await _firestore
          .collection(AppConstants.collectionSessions)
          .doc(sessionId)
          .update({'status': 'closed'});

      await writeAuditLog(
        userId: teacherId,
        role: 'teacher',
        action: 'CLOSED_SESSION: $sessionId',
      );
    } catch (e) {
      throw Exception('Failed to close session: $e');
    }
  }

  Stream<QuerySnapshot> streamSessionAttendance(String sessionId) {
    return _firestore
        .collection(AppConstants.collectionRecords)
        .where('sessionId', isEqualTo: sessionId)
        .snapshots();
  }

  Stream<QuerySnapshot> streamAttendanceRecordsForSubjectBatch(
    String subjectId,
    String batch,
  ) {
    return _firestore
        .collection(AppConstants.collectionRecords)
        .where('subjectId', isEqualTo: subjectId)
        .where('batch', isEqualTo: batch)
        .snapshots();
  }

  Future<void> markStudentAttendance({
    required String scannedPayload,
    required String studentUid,
  }) async {
    try {
      List<String> parts = scannedPayload.split('#');
      if (parts.length < 3) {
        throw Exception('Invalid QR Code structure.');
      }

      String sessionId = parts[0];
      String deviceId = await _getDeviceId();

      DocumentSnapshot sessionDoc = await _firestore
          .collection(AppConstants.collectionSessions)
          .doc(sessionId)
          .get();

      if (!sessionDoc.exists) {
        throw Exception('Attendance session does not exist.');
      }

      var sessionData = sessionDoc.data() as Map<String, dynamic>;
      String status = sessionData['status'] ?? 'closed';
      Timestamp expiresAt = sessionData['expiresAt'];
      String currentQrPayloadInDb = sessionData['currentQrPayload'] ?? '';
      String subjectId = sessionData['subjectId'] ?? '';
      String sessionBatch = sessionData['batch'] ?? '';

      if (status != 'active') {
        throw Exception('This attendance session has already been closed.');
      }

      if (DateTime.now().isAfter(expiresAt.toDate())) {
        await _firestore
            .collection(AppConstants.collectionSessions)
            .doc(sessionId)
            .update({'status': 'closed'});
        throw Exception(
          'This attendance session has expired (2-minute limit).',
        );
      }

      if (scannedPayload.trim() != currentQrPayloadInDb.trim()) {
        throw Exception(
          'QR Code has expired! Please scan the freshly updated QR code.',
        );
      }

      DocumentSnapshot studentDoc = await _firestore
          .collection(AppConstants.collectionStudents)
          .doc(studentUid)
          .get();

      if (!studentDoc.exists) {
        throw Exception('Student profile not found.');
      }

      var studentData = studentDoc.data() as Map<String, dynamic>;
      String studentBatch = studentData['batch'] ?? '';
      String studentName = studentData['name'] ?? 'Unknown';
      String studentIdNumber = studentData['studentId'] ?? '';

      if (studentBatch.isEmpty ||
          sessionBatch.isEmpty ||
          studentBatch != sessionBatch) {
        throw Exception('This session is not open for your batch.');
      }

      QuerySnapshot duplicateCheck = await _firestore
          .collection(AppConstants.collectionRecords)
          .where('sessionId', isEqualTo: sessionId)
          .where('studentId', isEqualTo: studentUid)
          .limit(1)
          .get();

      if (duplicateCheck.docs.isNotEmpty) {
        throw Exception(
          'Duplicate Attendance! You have already marked attendance for this class.',
        );
      }

      QuerySnapshot deviceCheck = await _firestore
          .collection(AppConstants.collectionRecords)
          .where('sessionId', isEqualTo: sessionId)
          .where('deviceId', isEqualTo: deviceId)
          .limit(1)
          .get();

      if (deviceCheck.docs.isNotEmpty) {
        var existing = deviceCheck.docs.first.data() as Map<String, dynamic>;
        if (existing['studentId'] != studentUid) {
          throw Exception(
            'This device has already marked attendance for a different student in this session.',
          );
        }
      }

      String recordId = '${sessionId}_$studentUid';
      String dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

      await _firestore
          .collection(AppConstants.collectionRecords)
          .doc(recordId)
          .set({
            'sessionId': sessionId,
            'studentId': studentUid,
            'studentName': studentName,
            'studentIdNumber': studentIdNumber,
            'subjectId': subjectId,
            'batch': sessionBatch,
            'deviceId': deviceId,
            'submittedPayload': scannedPayload.trim(),
            'dateKey': dateKey,
            'timestamp': FieldValue.serverTimestamp(),
            'status': 'Present',
          });

      await writeAuditLog(
        userId: studentUid,
        role: 'student',
        action:
            'MARK_ATTENDANCE: Present in subject $subjectId batch $sessionBatch',
      );
    } catch (e) {
      throw Exception(e.toString().replaceAll("Exception: ", ""));
    }
  }

  Stream<QuerySnapshot> streamStudentAttendanceRecords(String studentUid) {
    return _firestore
        .collection(AppConstants.collectionRecords)
        .where('studentId', isEqualTo: studentUid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> streamAllSubjects() {
    return _firestore.collection(AppConstants.collectionSubjects).snapshots();
  }
}
