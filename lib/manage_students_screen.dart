import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_constants.dart';
import 'helpers.dart';

class ManageStudentsScreen extends StatefulWidget {
  const ManageStudentsScreen({Key? key}) : super(key: key);

  @override
  _ManageStudentsScreenState createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _regNoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _deptController = TextEditingController();
  final TextEditingController _sessionController = TextEditingController();
  bool _isSaving = false;

  static const String _studentEmailDomain = '@student.qrattendance.app';
  static const List<String> _batches = ['2021', '2022', '2023', '2024', '2025'];
  String? _selectedBatch;

  static const Color woodDark = Color(0xFF4E342E);
  static const Color woodMid = Color(0xFF8D6E45);
  static const Color woodLight = Color(0xFFB08D57);
  static const Color cardBlue = Color(0xFFE8F1FB);
  static const Color accentBrown = Color(0xFF6D4C2E);

  String _buildPseudoEmail(String regNo) {
    return '${regNo.trim().toLowerCase()}$_studentEmailDomain';
  }

  void _addStudent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBatch == null) {
      UIHelpers.showSnackBar(context, 'Please select a batch.', isError: true);
      return;
    }
    setState(() => _isSaving = true);

    try {
      String regNo = _regNoController.text.trim();
      String pseudoEmail = _buildPseudoEmail(regNo);
      String name = _nameController.text.trim();
      String batch = _selectedBatch!;
      String dept = _deptController.text.trim();
      String session = _sessionController.text.trim();

      FirebaseApp tempApp = await Firebase.initializeApp(
        name: 'TempStudentApp_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );
      FirebaseAuth tempAuth = FirebaseAuth.instanceFor(app: tempApp);

      UserCredential credential = await tempAuth.createUserWithEmailAndPassword(
        email: pseudoEmail,
        password: _passwordController.text.trim(),
      );

      String uid = credential.user!.uid;

      await _firestore.collection(AppConstants.collectionUsers).doc(uid).set({
        'role': 'student',
        'name': name,
        'idNumber': regNo,
        'batch': batch,
        'dept': dept,
        'session': session,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _firestore
          .collection(AppConstants.collectionStudents)
          .doc(uid)
          .set({
            'uid': uid,
            'name': name,
            'studentId': regNo,
            'batch': batch,
            'dept': dept,
            'session': session,
            'role': 'student',
            'createdAt': FieldValue.serverTimestamp(),
          });

      await tempApp.delete();

      if (mounted) {
        UIHelpers.showSnackBar(
          context,
          'Student registered successfully! Reg No: $regNo (Batch $batch)',
        );
        _nameController.clear();
        _regNoController.clear();
        _passwordController.clear();
        _deptController.clear();
        _sessionController.clear();
        setState(() => _selectedBatch = null);
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

  InputDecoration _fieldDecoration(String label, {String? helperText}) {
    return InputDecoration(
      labelText: label,
      helperText: helperText,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  void _showAddStudentSheet() {
    String? sheetSelectedBatch = _selectedBatch;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
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
                child: Form(
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
                          'Register New Student',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _nameController,
                          decoration: _fieldDecoration('Full Name'),
                          validator: (value) =>
                              value!.isEmpty ? 'Field required' : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _regNoController,
                          decoration: _fieldDecoration(
                            'Registration Number (used as Login ID)',
                            helperText:
                                'Student will log in using this exact value.',
                          ),
                          validator: (value) =>
                              value!.isEmpty ? 'Field required' : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _deptController,
                          decoration: _fieldDecoration('Department (e.g. CSE)'),
                          validator: (value) =>
                              value!.isEmpty ? 'Field required' : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _sessionController,
                          decoration: _fieldDecoration(
                            'Session (e.g. 2023-2024)',
                          ),
                          validator: (value) =>
                              value!.isEmpty ? 'Field required' : null,
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: sheetSelectedBatch,
                          dropdownColor: cardBlue,
                          decoration: _fieldDecoration('Batch'),
                          items: _batches
                              .map(
                                (b) => DropdownMenuItem(
                                  value: b,
                                  child: Text('Batch $b'),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            setModalState(() => sheetSelectedBatch = val);
                            setState(() => _selectedBatch = val);
                          },
                          validator: (value) =>
                              value == null ? 'Please select a batch' : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _passwordController,
                          decoration: _fieldDecoration('Default Password'),
                          validator: (value) =>
                              value!.length < 6 ? 'Min 6 characters' : null,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _addStudent,
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
                                    'Save Student',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Manage Students'),
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
                .collection(AppConstants.collectionStudents)
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
                    'No students registered yet.',
                    style: TextStyle(color: Colors.white.withOpacity(0.9)),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  var student = docs[index];
                  String batch = student['batch'] ?? 'N/A';
                  String dept = student['dept'] ?? 'N/A';
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
                        child: Icon(Icons.school, color: accentBrown),
                      ),
                      title: Text(
                        student['name'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        'Reg No: ${student['studentId']} • Batch: $batch • Dept: $dept',
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStudentSheet,
        backgroundColor: accentBrown,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
