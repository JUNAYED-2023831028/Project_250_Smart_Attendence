import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'db_service.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  final String subjectId;
  final String subjectName;
  final String subjectCode;
  final String batch;

  const AttendanceHistoryScreen({
    Key? key,
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    required this.batch,
  }) : super(key: key);

  @override
  _AttendanceHistoryScreenState createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  final DbService _dbService = DbService();
  String? _selectedDateKey;

  static const Color woodDark = Color(0xFF4E342E);
  static const Color woodMid = Color(0xFF8D6E45);
  static const Color woodLight = Color(0xFFB08D57);
  static const Color cardBlue = Color(0xFFE8F1FB);
  static const Color accentBrown = Color(0xFF6D4C2E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          _selectedDateKey == null
              ? '${widget.subjectCode} • Batch ${widget.batch}'
              : _selectedDateKey!,
        ),
        backgroundColor: woodDark,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: _selectedDateKey == null
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedDateKey = null),
              ),
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
            stream: _dbService.streamAttendanceRecordsForSubjectBatch(
              widget.subjectId,
              widget.batch,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading records: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    'No attendance records found for this batch yet.',
                    style: TextStyle(color: Colors.white.withOpacity(0.9)),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              var allDocs = snapshot.data!.docs;

              Map<String, List<QueryDocumentSnapshot>> grouped = {};
              for (var doc in allDocs) {
                var data = doc.data() as Map<String, dynamic>;
                String dateKey = data['dateKey'] ?? 'Unknown';
                grouped.putIfAbsent(dateKey, () => []).add(doc);
              }

              List<String> sortedDates = grouped.keys.toList()
                ..sort((a, b) => b.compareTo(a));

              if (_selectedDateKey == null) {
                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: sortedDates.length,
                  itemBuilder: (context, index) {
                    String dateKey = sortedDates[index];
                    int count = grouped[dateKey]!.length;
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
                        leading: CircleAvatar(
                          backgroundColor: accentBrown.withOpacity(0.15),
                          child: Icon(Icons.calendar_today, color: accentBrown),
                        ),
                        title: Text(
                          dateKey,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          '$count student(s) present',
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.55),
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: accentBrown,
                        ),
                        onTap: () => setState(() => _selectedDateKey = dateKey),
                      ),
                    );
                  },
                );
              }

              List<QueryDocumentSnapshot> dayRecords =
                  grouped[_selectedDateKey] ?? [];
              dayRecords.sort((a, b) {
                var dataA = a.data() as Map<String, dynamic>;
                var dataB = b.data() as Map<String, dynamic>;
                String nameA = dataA['studentName'] ?? '';
                String nameB = dataB['studentName'] ?? '';
                return nameA.compareTo(nameB);
              });

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: dayRecords.length,
                itemBuilder: (context, index) {
                  var record = dayRecords[index].data() as Map<String, dynamic>;
                  Timestamp? timestamp = record['timestamp'] as Timestamp?;
                  String formattedTime = timestamp != null
                      ? DateFormat('hh:mm a').format(timestamp.toDate())
                      : 'Syncing...';
                  String studentName = record['studentName'] ?? 'Unknown';
                  String regNo = record['studentIdNumber'] ?? '';

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
                        studentName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        'Reg No: $regNo',
                        style: TextStyle(color: Colors.black.withOpacity(0.55)),
                      ),
                      trailing: Text(
                        formattedTime,
                        style: TextStyle(color: Colors.black.withOpacity(0.55)),
                      ),
                    ),
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
