import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled1/pages/login_page.dart';
import 'teacher_mark_attendance_page.dart';
import 'teacher_view_attendance_page.dart';
import 'teacher_profile_page.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class TeacherDashboardPage extends StatefulWidget {
  const TeacherDashboardPage({super.key});
  @override
  State<TeacherDashboardPage> createState() => _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends State<TeacherDashboardPage> {
  int _pageIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      TeacherHome(onMarkAttendance: () => setState(() => _pageIndex = 1)),
      const TeacherMarkAttendancePage(),
      const TeacherViewAttendancePage(),
      const TeacherProfilePage(),
    ];
  }

  final List<String> _titles = ['Dashboard', 'Mark Attendance', 'My Attendance', 'My Profile'];

  // Logout function now deletes the token
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
            (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(_titles[_pageIndex]),
        centerTitle: true,
        backgroundColor: Colors.purple.withOpacity(0.8),
        elevation: 0,
        leading: _pageIndex != 0
            ? IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => setState(() => _pageIndex = 0), // Go back to the dashboard
        )
            : null,
        actions: [
          // The right-side button now logs out
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          )
        ],
      ),
      bottomNavigationBar: CurvedNavigationBar(
        index: _pageIndex,
        height: 60.0,
        items: const <Widget>[
          Icon(Icons.dashboard_rounded, size: 30, color: Colors.white),
          Icon(Icons.edit_calendar_rounded, size: 30, color: Colors.white),
          Icon(Icons.fact_check_rounded, size: 30, color: Colors.white),
          Icon(Icons.person_rounded, size: 30, color: Colors.white),
        ],
        color: Colors.purple,
        buttonBackgroundColor: Colors.purple,
        backgroundColor: Colors.transparent,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 400),
        onTap: (index) => setState(() => _pageIndex = index),
        letIndexChange: (index) => true,
      ),
      body: _pages[_pageIndex],
    );
  }
}

// TeacherHome is now a StatefulWidget to fetch API data
class TeacherHome extends StatefulWidget {
  final VoidCallback onMarkAttendance;
  const TeacherHome({super.key, required this.onMarkAttendance});

  @override
  State<TeacherHome> createState() => _TeacherHomeState();
}

class _TeacherHomeState extends State<TeacherHome> {
  bool _isLoading = true;
  String? _teacherName;
  String? _instituteName;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  // Function to fetch profile data from the backend
  Future<void> _fetchProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        if (mounted) setState(() { _errorMessage = 'Not logged in.'; _isLoading = false; });
        return;
      }
      final response = await http.get(
        Uri.parse('https://coaching-api-backend.onrender.com:10000/api/teacher/profile/me'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (mounted) {
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            _teacherName = data['full_name'];
            _instituteName = data['institute_name'];
            _isLoading = false;
          });
        } else {
          setState(() { _errorMessage = 'Failed to load profile data.'; _isLoading = false; });
        }
      }
    } catch (e) {
      if (mounted) setState(() { _errorMessage = 'Could not connect to server.'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.purple.shade200, Colors.purple.shade50, Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: SafeArea(
        bottom: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(child: Text(_errorMessage!))
            : SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Data is now dynamic
              Text(
                'Welcome, ${_teacherName ?? 'Teacher'}!',
                style: GoogleFonts.lato(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 10),
              Text(
                _instituteName ?? 'Your Institute',
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 30),

              _buildSectionTitle('Quick Actions', Icons.bolt),
              _buildQuickActionCard('Mark Today\'s Attendance', Icons.checklist, Colors.green, widget.onMarkAttendance),
              const SizedBox(height: 30),

              _buildSectionTitle('My Classes', Icons.school),
              _buildClassCard('12th Science - Physics', '45 Students', 'Mon, Wed, Fri', Icons.science),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.purple.shade700),
          const SizedBox(width: 8),
          Text(title, style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Icon(icon, color: color, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildClassCard(String className, String studentCount, String schedule, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.purple.shade100,
                  child: Icon(icon, color: Colors.purple),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(className, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoChip(Icons.group, studentCount, Colors.orange),
                _buildInfoChip(Icons.schedule, schedule, Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Text(text),
      ],
    );
  }
}