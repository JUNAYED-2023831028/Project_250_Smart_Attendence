import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'db_service.dart';
import 'helpers.dart';

class QrGeneratorScreen extends StatefulWidget {
  final String subjectId;
  final String subjectName;
  final String subjectCode;
  final String teacherUid;
  final String batch;

  const QrGeneratorScreen({
    Key? key,
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    required this.teacherUid,
    required this.batch,
  }) : super(key: key);

  @override
  _QrGeneratorScreenState createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends State<QrGeneratorScreen> {
  final DbService _dbService = DbService();

  static const Color woodDark = Color(0xFF4E342E);
  static const Color woodMid = Color(0xFF8D6E45);
  static const Color woodLight = Color(0xFFB08D57);
  static const Color cardBlue = Color(0xFFE8F1FB);
  static const Color accentBrown = Color(0xFF6D4C2E);

  String? _sessionId;
  String _currentPayload = "";
  bool _isSessionActive = false;
  bool _isInitializing = false;

  Timer? _tickTimer;
  DateTime? _sessionExpiresAt;
  DateTime? _lastRotatedAt;

  int _secondsRemaining = 120;
  int _rotationSecondsRemaining = 30;

  String _generateSecurePayload() {
    final random = Random();
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_@';
    String randomSalt = String.fromCharCodes(
      Iterable.generate(
        12,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
    return '${_sessionId ?? "TEMP"}#${DateTime.now().millisecondsSinceEpoch}#$randomSalt';
  }

  void _startAttendanceSession() async {
    setState(() => _isInitializing = true);

    try {
      _sessionId = await _dbService.createAttendanceSession(
        subjectId: widget.subjectId,
        teacherId: widget.teacherUid,
        batch: widget.batch,
        initialPayload: "initializing_session",
      );

      DocumentSnapshot sessionDoc = await FirebaseFirestore.instance
          .collection('sessions')
          .doc(_sessionId!)
          .get();
      Timestamp expiresAt = sessionDoc['expiresAt'];
      _sessionExpiresAt = expiresAt.toDate();
      _lastRotatedAt = DateTime.now();

      _currentPayload = _generateSecurePayload();
      await _dbService.updateSessionPayload(_sessionId!, _currentPayload);

      setState(() {
        _isSessionActive = true;
        _isInitializing = false;
      });

      _runTimers();
    } catch (e) {
      setState(() => _isInitializing = false);
      UIHelpers.showSnackBar(
        context,
        'Failed to initialize session: $e',
        isError: true,
      );
    }
  }

  void _runTimers() {
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _sessionExpiresAt == null || _lastRotatedAt == null)
        return;

      final now = DateTime.now();
      final remainingToExpiry = _sessionExpiresAt!.difference(now).inSeconds;
      final remainingToRotation =
          30 - now.difference(_lastRotatedAt!).inSeconds;

      if (remainingToExpiry <= 0) {
        _endSession();
        return;
      }

      setState(() {
        _secondsRemaining = remainingToExpiry;
        _rotationSecondsRemaining = remainingToRotation > 0
            ? remainingToRotation
            : 0;
      });

      if (remainingToRotation <= 0) {
        _lastRotatedAt = now;
        _rotateQrCode();
      }
    });
  }

  void _rotateQrCode() async {
    if (_sessionId == null) return;
    String freshPayload = _generateSecurePayload();

    setState(() => _currentPayload = freshPayload);
    await _dbService.updateSessionPayload(_sessionId!, freshPayload);
  }

  void _endSession() async {
    _tickTimer?.cancel();

    if (_sessionId != null) {
      await _dbService.closeAttendanceSession(_sessionId!, widget.teacherUid);
    }

    if (mounted) {
      setState(() {
        _isSessionActive = false;
        _secondsRemaining = 0;
        _rotationSecondsRemaining = 0;
      });
      UIHelpers.showSnackBar(context, 'Attendance session closed!');
    }
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    if (_isSessionActive && _sessionId != null) {
      _dbService.closeAttendanceSession(_sessionId!, widget.teacherUid);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('${widget.subjectCode} • Batch ${widget.batch}'),
        backgroundColor: woodDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [woodDark, woodMid, woodLight],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBlue,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.subjectName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      if (!_isSessionActive) ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: accentBrown.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.qr_code_2,
                            size: 80,
                            color: accentBrown,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Generate a rotating secure QR code below. The QR code is active for 2 minutes and rotates every 30 seconds to prevent fraudulent check-ins.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.55),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: _isInitializing
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.qr_code_2),
                            label: Text(
                              _isInitializing
                                  ? 'Starting...'
                                  : 'Generate Attendance QR',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentBrown,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _isInitializing
                                ? null
                                : _startAttendanceSession,
                          ),
                        ),
                      ] else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  'Expires In',
                                  style: TextStyle(
                                    color: Colors.black.withOpacity(0.55),
                                  ),
                                ),
                                Text(
                                  '${_secondsRemaining ~/ 60}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: _secondsRemaining < 20
                                        ? Colors.red.shade700
                                        : accentBrown,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  'Rotates In',
                                  style: TextStyle(
                                    color: Colors.black.withOpacity(0.55),
                                  ),
                                ),
                                Text(
                                  '${_rotationSecondsRemaining}s',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: QrImageView(
                            data: _currentPayload,
                            version: QrVersions.auto,
                            size: 220.0,
                            gapless: false,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          'Keep this screen visible to students',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.black.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            label: const Text(
                              'Force Terminate Session',
                              style: TextStyle(color: Colors.red),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _endSession,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_isSessionActive) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardBlue,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Live Student Check-in Roll',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildLiveAttendanceList(),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveAttendanceList() {
    if (_sessionId == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: _dbService.streamSessionAttendance(_sessionId!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        var docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Waiting for students to scan...',
              style: TextStyle(color: Colors.black.withOpacity(0.5)),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var record = docs[index];
            String studentName = record['studentName'] ?? 'Unknown';
            String studentIdNumber = record['studentIdNumber'] ?? '';

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text(
                  studentName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                subtitle: Text(
                  'ID: $studentIdNumber',
                  style: TextStyle(color: Colors.black.withOpacity(0.55)),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
