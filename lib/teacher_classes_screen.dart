import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'db_service.dart';
import 'qr_generator_screen.dart';
import 'attendance_history_screen.dart';

class TeacherClassesScreen extends StatelessWidget {
  final String teacherUid;

  static const List<String> _batches = ['2021', '2022', '2023', '2024', '2025'];

  static const Color woodDark = Color(0xFF4E342E);
  static const Color woodMid = Color(0xFF8D6E45);
  static const Color woodLight = Color(0xFFB08D57);
  static const Color cardBlue = Color(0xFFE8F1FB);
  static const Color accentBrown = Color(0xFF6D4C2E);

  const TeacherClassesScreen({Key? key, required this.teacherUid})
    : super(key: key);

  void _showBatchSelectionSheet(
    BuildContext context,
    String subjectId,
    String subjectName,
    String subjectCode,
  ) {
    String selectedBatch = _batches.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBlue,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    subjectName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subjectCode,
                    style: TextStyle(color: Colors.black.withOpacity(0.5)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: selectedBatch,
                    decoration: InputDecoration(
                      labelText: 'Select Batch',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: _batches
                        .map(
                          (b) => DropdownMenuItem(
                            value: b,
                            child: Text('Batch $b'),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedBatch = val);
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.qr_code_2),
                    label: const Text('Generate Attendance QR'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: accentBrown,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QrGeneratorScreen(
                            subjectId: subjectId,
                            subjectName: subjectName,
                            subjectCode: subjectCode,
                            teacherUid: teacherUid,
                            batch: selectedBatch,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    icon: Icon(Icons.bar_chart, color: accentBrown),
                    label: Text(
                      'View Attendance Report',
                      style: TextStyle(color: accentBrown),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: accentBrown),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AttendanceHistoryScreen(
                            subjectId: subjectId,
                            subjectName: subjectName,
                            subjectCode: subjectCode,
                            batch: selectedBatch,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final DbService dbService = DbService();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Assigned Courses'),
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
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: StreamBuilder<QuerySnapshot>(
            stream: dbService.streamTeacherSubjects(teacherUid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'You are not currently assigned to teach any subjects.',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var subject = snapshot.data!.docs[index];
                  String subjectName = subject['name'] ?? '';
                  String subjectCode = subject['code'] ?? '';
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
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
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: accentBrown.withOpacity(0.15),
                        child: Icon(Icons.class_, color: accentBrown),
                      ),
                      title: Text(
                        subjectName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        'Subject Code: $subjectCode',
                        style: TextStyle(color: Colors.black.withOpacity(0.55)),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: accentBrown,
                      ),
                      onTap: () => _showBatchSelectionSheet(
                        context,
                        subject.id,
                        subjectName,
                        subjectCode,
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
