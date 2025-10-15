// File: lib/ClassOwner/Classdashboard_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../login_page.dart';
import 'manage_page.dart';
import 'add_student_page.dart';
import 'add_teacher_page.dart';
import 'manage_students_page.dart';
import 'manage_teachers_page.dart';
import 'mark_teacher_attendance_page.dart';
import 'mark_student_attendance_page.dart'; // Correct import if name differs
import 'manage_teacher_attendance_page.dart';
import 'view_fees_page.dart';
import 'profile_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late List<Widget> _mainPages;
  final List<Widget> _viewStack = [];
  final List<String> _titleStack = [];

  @override
  void initState() {
    super.initState();
    _initializePages();
    _viewStack.add(_mainPages[0]);
    _titleStack.add('Dashboard');
  }

  void _initializePages() {
    _mainPages = [
      const DashboardHome(),
      ManagePage(
        onAddStudent: () => _navigateTo(const AddStudentPage(), 'Add Student'),
        onAddTeacher: () => _navigateTo(const AddTeacherPage(), 'Add Teacher'),
        onViewStudents: () => _navigateTo(const ManageStudentsPage(), 'Manage Students'),
        onViewTeachers: () => _navigateTo(const ManageTeachersPage(), 'Manage Teachers'),
        onMarkTeacherAttendance: () => _navigateTo(const MarkTeacherAttendancePage(), 'Mark Teacher Attendance'),

        // ============== THIS LINE IS NOW FIXED ==============
        onManageStudentAttendance: () => _navigateTo(const ManageStudentAttendancePage(), 'Manage Student Attendance'),

        onManageTeacherAttendance: () => _navigateTo(const ManageTeacherAttendancePage(), 'Manage Teacher Attendance'),
      ),
      const ViewFeesPage(),
      const ProfilePage(),
    ];
  }

  void _navigateTo(Widget page, String title) {
    setState(() { _viewStack.add(page); _titleStack.add(title); });
  }

  void _goBack() {
    if (_viewStack.length > 1) {
      setState(() { _viewStack.removeLast(); _titleStack.removeLast(); });
    }
  }

  void _goToDashboard() {
    setState(() {
      _viewStack.clear();
      _titleStack.clear();
      _viewStack.add(_mainPages[0]);
      _titleStack.add('Dashboard');
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    if (mounted) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginPage()), (Route<dynamic> route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentView = _viewStack.last;
    final currentTitle = _titleStack.last;
    int mainPageIndex = _mainPages.indexOf(currentView);
    final bool showBackButton = (_viewStack.length > 1) || (mainPageIndex > 0);
    int navBarIndex = mainPageIndex;
    if (navBarIndex == -1) navBarIndex = 1;

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        leading: showBackButton
            ? IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            if (_viewStack.length > 1) {
              _goBack();
            } else {
              _goToDashboard();
            }
          },
        )
            : null,
        title: Text(currentTitle),
        centerTitle: true,
        actions: [
          Tooltip(
            message: 'Logout',
            child: IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
          )
        ],
      ),
      floatingActionButton: (currentView is ManagePage)
          ? FloatingActionButton(
        onPressed: () {
          _navigateTo(const AddStudentPage(), 'Add Student');
        },
        child: const Icon(Icons.add),
      )
          : null,
      bottomNavigationBar: CurvedNavigationBar(
        index: navBarIndex,
        height: 60.0,
        items: const <Widget>[
          Icon(Icons.dashboard_rounded, size: 30, color: Colors.white),
          Icon(Icons.list_alt_rounded, size: 30, color: Colors.white),
          Icon(Icons.monetization_on_rounded, size: 30, color: Colors.white),
          Icon(Icons.person_rounded, size: 30, color: Colors.white),
        ],
        color: Colors.lightBlue,
        buttonBackgroundColor: Colors.lightBlue,
        backgroundColor: Colors.transparent,
        onTap: (index) {
          setState(() {
            _viewStack.clear();
            _titleStack.clear();
            _viewStack.add(_mainPages[index]);
            _titleStack.add(['Dashboard', 'Manage', 'View Fees', 'Profile'][index]);
          });
        },
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.lightBlue.shade200, Colors.lightBlue.shade50, Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: currentView),
      ),
    );
  }
}

// --- DASHBOARDHOME WIDGET (No Changes) ---
class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});
  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  bool _isLoading = true;
  String? _ownerName;
  String? _instituteName;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchInstituteDetails();
  }

  Future<void> _fetchInstituteDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        if(mounted) setState(() { _errorMessage = 'Authentication token not found.'; _isLoading = false; });
        return;
      }
      final response = await http.get(
        Uri.parse('https://coaching-api-backend.onrender.com/api/institute/profile'),
        headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer $token',},
      );
      if(mounted){
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            _ownerName = data['owner_name'];
            _instituteName = data['institute_name'];
            _isLoading = false;
          });
        } else {
          setState(() { _errorMessage = 'Failed to load data from server.'; _isLoading = false; });
        }
      }
    } catch (e) {
      if(mounted) setState(() { _errorMessage = 'Could not connect to the server.'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)));
    }
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome, ${_ownerName ?? 'Owner'}!', style: GoogleFonts.lato(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 10),
            Text(_instituteName ?? 'Your Institute', style: const TextStyle(fontSize: 18, color: Colors.black54)),
            const SizedBox(height: 30),
            GridView.count(
              crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16,
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildInfoCard(icon: Icons.group, title: 'Total Students', value: '45', color: Colors.orange),
                _buildInfoCard(icon: Icons.class_, title: 'Total Classes', value: '5', color: Colors.lightBlue),
                _buildInfoCard(icon: Icons.account_balance_wallet, title: 'Fees Collected', value: '₹ 85,000', color: Colors.green),
                _buildInfoCard(icon: Icons.pending_actions, title: 'Pending Fees', value: '₹ 15,000', color: Colors.redAccent),
              ],
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String value, required Color color}) {
    return Card(
      elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(radius: 22, backgroundColor: color, child: Icon(icon, color: Colors.white, size: 24)),
            const Spacer(),
            Text(title, style: const TextStyle(fontSize: 16, color: Colors.black54)),
            const SizedBox(height: 5),
            Text(value, style: GoogleFonts.lato(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
      ),
    );
  }
}