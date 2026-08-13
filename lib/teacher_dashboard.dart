import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'prefs_service.dart';
import 'helpers.dart';
import 'login_screen.dart';
import 'app_constants.dart';
import 'teacher_classes_screen.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({Key? key}) : super(key: key);

  @override
  _TeacherDashboardState createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final AuthService _authService = AuthService();

  String _teacherName = "Teacher";
  String _teacherUid = "";
  String _teacherIdNumber = "";
  String _dept = "";
  String _designation = "";
  bool _isSessionLoaded = false;
  bool _isProfileLoaded = false;

  static const Color woodDark = Color(0xFF4E342E);
  static const Color woodMid = Color(0xFF8D6E45);
  static const Color woodLight = Color(0xFFB08D57);
  static const Color cardBlue = Color(0xFFE8F1FB);
  static const Color accentBrown = Color(0xFF6D4C2E);

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  void _loadTeacherData() async {
    final session = await PrefsService.getUserSession();
    if (!mounted) return;
    setState(() {
      _teacherName = session['name'] ?? 'Teacher';
      _teacherUid = session['uid'] ?? '';
      _teacherIdNumber = session['id'] ?? '';
      _isSessionLoaded = true;
    });

    if (_teacherUid.isNotEmpty) {
      _loadProfileDetails();
    }
  }

  void _loadProfileDetails() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection(AppConstants.collectionUsers)
          .doc(_teacherUid)
          .get();
      if (!mounted) return;
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        setState(() {
          _dept = data['dept'] ?? '';
          _designation = data['designation'] ?? '';
          _isProfileLoaded = true;
        });
      } else {
        setState(() => _isProfileLoaded = true);
      }
    } catch (e) {
      if (mounted) setState(() => _isProfileLoaded = true);
    }
  }

  void _handleLogout() async {
    try {
      await _authService.logout(_teacherUid, 'teacher');
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      UIHelpers.showSnackBar(context, 'Logout failed: $e', isError: true);
    }
  }

  void _showChangePasswordDialog() {
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscure = true;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Change Password'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: obscure,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscure ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () =>
                              setDialogState(() => obscure = !obscure),
                        ),
                      ),
                      validator: (value) => value == null || value.length < 6
                          ? 'Minimum 6 characters'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: obscure,
                      decoration: const InputDecoration(
                        labelText: 'Confirm New Password',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Please confirm your password';
                        if (value != newPasswordController.text)
                          return 'Passwords do not match';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => isSaving = true);

                          try {
                            await _authService.updateUserPassword(
                              newPasswordController.text,
                            );
                            if (mounted) {
                              Navigator.pop(context);
                              UIHelpers.showSnackBar(
                                context,
                                'Password updated successfully!',
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                            if (mounted) {
                              UIHelpers.showSnackBar(
                                context,
                                e.toString(),
                                isError: true,
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentBrown,
                    foregroundColor: Colors.white,
                  ),
                  child: isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildProfileDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: accentBrown),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.black.withOpacity(0.55),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'N/A' : value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Teacher Panel'),
        backgroundColor: woodDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Menu',
            onSelected: (value) {
              if (value == 'change_password') {
                _showChangePasswordDialog();
              } else if (value == 'logout') {
                _handleLogout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'change_password',
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, size: 20, color: Colors.black87),
                    SizedBox(width: 10),
                    Text('Change Password'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: Colors.redAccent),
                    SizedBox(width: 10),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
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
        child: !_isSessionLoaded
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 40,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: cardBlue,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 18,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 32,
                                        backgroundColor: accentBrown
                                            .withOpacity(0.15),
                                        child: Icon(
                                          Icons.person,
                                          size: 36,
                                          color: accentBrown,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _teacherName,
                                              style: const TextStyle(
                                                fontSize: 21,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: accentBrown.withOpacity(
                                                  0.12,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                _designation.isEmpty
                                                    ? 'Teacher'
                                                    : _designation,
                                                style: TextStyle(
                                                  color: accentBrown,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  Divider(
                                    color: Colors.black.withOpacity(0.1),
                                    height: 1,
                                  ),
                                  const SizedBox(height: 10),
                                  if (!_isProfileLoaded)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      child: Center(
                                        child: SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                    )
                                  else ...[
                                    _buildProfileDetailRow(
                                      Icons.business_outlined,
                                      'Department',
                                      _dept,
                                    ),
                                    _buildProfileDetailRow(
                                      Icons.badge_outlined,
                                      'Teacher ID',
                                      _teacherIdNumber,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.class_outlined),
                                label: const Text('View Assigned Courses'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accentBrown,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 3,
                                ),
                                onPressed: _teacherUid.isEmpty
                                    ? null
                                    : () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                TeacherClassesScreen(
                                                  teacherUid: _teacherUid,
                                                ),
                                          ),
                                        );
                                      },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
