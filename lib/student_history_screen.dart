import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'db_service.dart';

class StudentHistoryScreen extends StatelessWidget {
  final String studentUid;

  static const Color woodDark = Color(0xFF4E342E);
  static const Color woodMid = Color(0xFF8D6E45);
  static const Color woodLight = Color(0xFFB08D57);
  static const Color cardBlue = Color(0xFFE8F1FB);
  static const Color accentBrown = Color(0xFF6D4C2E);

  const StudentHistoryScreen({Key? key, required this.studentUid})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final DbService dbService = DbService();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Attendance History'),
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
          child: StreamBuilder<QuerySnapshot>(
            stream: dbService.streamStudentAttendanceRecords(studentUid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Error loading history: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    'No attendance records found yet.',
                    style: TextStyle(color: Colors.white.withOpacity(0.9)),
                  ),
                );
              }

              var records = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: records.length,
                itemBuilder: (context, index) {
                  var record = records[index];
                  Timestamp? timestamp = record['timestamp'] as Timestamp?;
                  String formattedDate = timestamp != null
                      ? DateFormat(
                          'yyyy-MM-dd • hh:mm a',
                        ).format(timestamp.toDate())
                      : 'Syncing...';

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('subjects')
                        .doc(record['subjectId'])
                        .get(),
                    builder: (context, subjectSnapshot) {
                      String subjectName = "Loading...";
                      String subjectCode = "";
                      if (subjectSnapshot.hasData &&
                          subjectSnapshot.data!.exists) {
                        subjectName =
                            subjectSnapshot.data!['name'] ?? 'Unknown';
                        subjectCode = subjectSnapshot.data!['code'] ?? '';
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: cardBlue,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          leading: const CircleAvatar(
                            backgroundColor: Colors.green,
                            child: Icon(Icons.check, color: Colors.white),
                          ),
                          title: Text(
                            '$subjectCode - $subjectName',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            formattedDate,
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.55),
                            ),
                          ),
                          trailing: const Text(
                            'PRESENT',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
