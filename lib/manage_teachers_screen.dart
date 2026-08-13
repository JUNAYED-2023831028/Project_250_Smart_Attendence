import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_constants.dart';
import 'helpers.dart';

class ManageTeachersScreen extends StatefulWidget {
  const ManageTeachersScreen({Key? key}) : super(key: key);

  @override
  _ManageTeachersScreenState createState() => _ManageTeachersScreenState();
}

class _ManageTeachersScreenState extends State<ManageTeachersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _deptController = TextEditingController();
  final TextEditingController _designationController = TextEditingController();
  bool _isSaving = false;

  static const Color woodDark = Color(0xFF4E342E);
  static const Color woodMid = Color(0xFF8D6E45);
  static const Color woodLight = Color(0xFFB08D57);
  static const Color cardBlue = Color(0xFFE8F1FB);
  static const Color accentBrown = Color(0xFF6D4C2E);

  void _addTeacher() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      FirebaseApp tempApp = await Firebase.initializeApp(
        name: 'TemporaryApp_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );
      FirebaseAuth tempAuth = FirebaseAuth.instanceFor(app: tempApp);

      UserCredential credential = await tempAuth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      String uid = credential.user!.uid;
      String name = _nameController.text.trim();
      String teacherId = _idController.text.trim();
      String email = _emailController.text.trim();
      String dept = _deptController.text.trim();
      String designation = _designationController.text.trim();

      await _firestore.collection(AppConstants.collectionUsers).doc(uid).set({
        'role': 'teacher',
        'name': name,
        'idNumber': teacherId,
        'dept': dept,
        'designation': designation,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _firestore
          .collection(AppConstants.collectionTeachers)
          .doc(uid)
          .set({
            'uid': uid,
            'name': name,
            'email': email,
            'teacherId': teacherId,
            'dept': dept,
            'designation': designation,
            'role': 'teacher',
            'createdAt': FieldValue.serverTimestamp(),
          });

      await tempApp.delete();

      if (mounted) {
        UIHelpers.showSnackBar(context, 'Teacher added successfully!');
        _nameController.clear();
        _emailController.clear();
        _passwordController.clear();
        _idController.clear();
        _deptController.clear();
        _designationController.clear();
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

  void _showAddTeacherSheet() {
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
                    'Register New Teacher',
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
                    controller: _designationController,
                    decoration: _fieldDecoration(
                      'Designation (e.g. Associate Professor)',
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Field required' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _idController,
                    decoration: _fieldDecoration('Teacher ID / Code'),
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
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _fieldDecoration('Email Address'),
                    validator: (value) =>
                        value!.isEmpty ? 'Field required' : null,
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
                      onPressed: _isSaving ? null : _addTeacher,
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
                              'Save Teacher',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
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
        title: const Text('Manage Teachers'),
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
                .collection(AppConstants.collectionTeachers)
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
                    'No teachers registered yet.',
                    style: TextStyle(color: Colors.white.withOpacity(0.9)),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  var teacher = docs[index];
                  String dept = teacher['dept'] ?? 'N/A';
                  String designation = teacher['designation'] ?? 'N/A';
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
                        child: Icon(Icons.person, color: accentBrown),
                      ),
                      title: Text(
                        teacher['name'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        '$designation • ID: ${teacher['teacherId']} • Dept: $dept',
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
        onPressed: _showAddTeacherSheet,
        backgroundColor: accentBrown,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
