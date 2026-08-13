import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_constants.dart';
import 'helpers.dart';

class ManageSubjectsScreen extends StatefulWidget {
  const ManageSubjectsScreen({Key? key}) : super(key: key);

  @override
  _ManageSubjectsScreenState createState() => _ManageSubjectsScreenState();
}

class _ManageSubjectsScreenState extends State<ManageSubjectsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  String? _selectedTeacherUid;
  bool _isSaving = false;

  static const Color woodDark = Color(0xFF4E342E);
  static const Color woodMid = Color(0xFF8D6E45);
  static const Color woodLight = Color(0xFFB08D57);
  static const Color cardBlue = Color(0xFFE8F1FB);
  static const Color accentBrown = Color(0xFF6D4C2E);

  void _addSubject() async {
    if (!_formKey.currentState!.validate() || _selectedTeacherUid == null) {
      UIHelpers.showSnackBar(
        context,
        'Please fill all fields & assign a teacher.',
        isError: true,
      );
      return;
    }
    setState(() => _isSaving = true);

    try {
      await _firestore.collection(AppConstants.collectionSubjects).add({
        'name': _nameController.text.trim(),
        'code': _codeController.text.trim().toUpperCase(),
        'assignedTeacherId': _selectedTeacherUid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        UIHelpers.showSnackBar(context, 'Subject configured successfully!');
        _nameController.clear();
        _codeController.clear();
        _selectedTeacherUid = null;
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        UIHelpers.showSnackBar(context, 'Error: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  void _showAddSubjectSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: 20,
          ),
          decoration: const BoxDecoration(
            color: cardBlue,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection(AppConstants.collectionTeachers)
                .snapshots(),
            builder: (context, teacherSnapshot) {
              List<DropdownMenuItem<String>> teacherItems = [];
              if (teacherSnapshot.hasData) {
                for (var doc in teacherSnapshot.data!.docs) {
                  teacherItems.add(
                    DropdownMenuItem(
                      value: doc.id,
                      child: Text(doc['name'] ?? ''),
                    ),
                  );
                }
              }

              return Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const Text(
                        'Configure New Subject',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _nameController,
                        decoration: _fieldDecoration('Subject Name'),
                        validator: (value) =>
                            value!.isEmpty ? 'Field required' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _codeController,
                        decoration: _fieldDecoration(
                          'Subject Code (e.g. CSE311)',
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Field required' : null,
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        dropdownColor: cardBlue,
                        decoration: _fieldDecoration('Assign Teacher'),
                        items: teacherItems,
                        onChanged: (val) =>
                            setState(() => _selectedTeacherUid = val),
                        validator: (value) =>
                            value == null ? 'Please assign a teacher' : null,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _addSubject,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentBrown,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Create Subject',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Manage Subjects'),
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
            stream: _firestore
                .collection(AppConstants.collectionSubjects)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              var docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return Center(
                  child: Text(
                    'No subjects added yet.',
                    style: TextStyle(color: Colors.white.withOpacity(0.9)),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  var subject = docs[index];
                  String? assignedTeacherId =
                      subject['assignedTeacherId'] as String?;

                  if (assignedTeacherId == null) {
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
                          child: Icon(Icons.book, color: accentBrown),
                        ),
                        title: Text(
                          subject['name'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          'Code: ${subject['code']} • Instructor: Unassigned',
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.55),
                          ),
                        ),
                      ),
                    );
                  }

                  return FutureBuilder<DocumentSnapshot>(
                    future: _firestore
                        .collection(AppConstants.collectionTeachers)
                        .doc(assignedTeacherId)
                        .get(),
                    builder: (context, teacherDoc) {
                      String teacherName =
                          teacherDoc.hasData && teacherDoc.data!.exists
                          ? teacherDoc.data!['name'] ?? 'Unknown'
                          : 'Assigning...';

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
                            child: Icon(Icons.book, color: accentBrown),
                          ),
                          title: Text(
                            subject['name'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            'Code: ${subject['code']} • Instructor: $teacherName',
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.55),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSubjectSheet,
        backgroundColor: accentBrown,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
