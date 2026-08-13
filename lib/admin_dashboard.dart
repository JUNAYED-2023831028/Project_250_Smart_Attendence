import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'prefs_service.dart';
import 'helpers.dart';
import 'login_screen.dart';
import 'manage_teachers_screen.dart';
import 'manage_students_screen.dart';
import 'manage_subjects_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AuthService _authService = AuthService();
  String _adminName = "Administrator";
  String _adminUid = "";
  bool _isSessionLoaded = false;

  static const Color woodDark = Color(0xFF4E342E);
  static const Color woodMid = Color(0xFF8D6E45);
  static const Color woodLight = Color(0xFFB08D57);
  static const Color cardBlue = Color(0xFFE8F1FB);
  static const Color accentBrown = Color(0xFF6D4C2E);

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  void _loadAdminData() async {
    final session = await PrefsService.getUserSession();
    if (!mounted) return;
    setState(() {
      _adminName = session['name'] ?? 'Administrator';
      _adminUid = session['uid'] ?? '';
      _isSessionLoaded = true;
    });
  }

  void _handleLogout() async {
    try {
      await _authService.logout(_adminUid, 'admin');
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

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
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
          vertical: 10,
        ),
        leading: CircleAvatar(
          backgroundColor: accentBrown.withOpacity(0.15),
          child: Icon(icon, color: accentBrown),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.black.withOpacity(0.55)),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: accentBrown),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Admin Command Center'),
        backgroundColor: woodDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Log Out',
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
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome, $_adminName',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'System Administration panel',
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.55),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView(
                          children: [
                            _buildMenuCard(
                              icon: Icons.person,
                              title: 'Manage Teachers',
                              subtitle: 'Add, view or update instructor files',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ManageTeachersScreen(),
                                ),
                              ),
                            ),
                            _buildMenuCard(
                              icon: Icons.school,
                              title: 'Manage Students',
                              subtitle: 'Create and verify student profiles',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ManageStudentsScreen(),
                                ),
                              ),
                            ),
                            _buildMenuCard(
                              icon: Icons.book,
                              title: 'Manage Subjects',
                              subtitle: 'Define courses and assign teachers',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ManageSubjectsScreen(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
