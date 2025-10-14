// File: lib/Pages/Student/student_dashboard_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

import '../login_page.dart';
import 'my_attendance_page.dart';
import 'my_fees_page.dart';
import 'my_profile_page.dart';

class StudentDashboardPage extends StatefulWidget {
  const StudentDashboardPage({super.key});
  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  int _pageIndex = 0;
  final List<Widget> _pages = [
    const StudentHome(),
    const MyAttendancePage(),
    const MyFeesPage(),
    const MyProfilePage(),
  ];
  final List<String> _titles = ['Dashboard', 'My Attendance', 'My Fees', 'My Profile'];

  // ============== LOGOUT FUNCTION AB TOKEN DELETE KAREGA ==============
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
        backgroundColor: Colors.green.withOpacity(0.8),
        leading: _pageIndex != 0
            ? IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => setState(() => _pageIndex = 0),
        )
            : null,
        actions: [
          // Right side wala button ab logout karega
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
          Icon(Icons.fact_check_rounded, size: 30, color: Colors.white),
          Icon(Icons.monetization_on_rounded, size: 30, color: Colors.white),
          Icon(Icons.person_rounded, size: 30, color: Colors.white),
        ],
        color: Colors.green,
        buttonBackgroundColor: Colors.green,
        backgroundColor: Colors.transparent,
        onTap: (index) => setState(() => _pageIndex = index),
      ),
      body: _pages[_pageIndex],
    );
  }
}

// ============== STUDENTHOME AB STATEFUL WIDGET HAI ==============
class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  bool _isLoading = true;
  String? _studentName;
  String? _instituteName;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  // ============== API SE DATA FETCH KARNE KA FUNCTION ==============
  Future<void> _fetchProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        if (mounted) setState(() { _errorMessage = 'Not logged in.'; _isLoading = false; });
        return;
      }
      final response = await http.get(
        Uri.parse('https://coaching-api-backend.onrender.com:10000/api/student/profile/me'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (mounted) {
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            _studentName = data['full_name'];
            _instituteName = data['institute_name'];
            _isLoading = false;
          });
        } else {
          setState(() { _errorMessage = 'Failed to load profile. Error: ${response.body}'; _isLoading = false; });
        }
      }
    } catch (e) {
      if (mounted) setState(() { _errorMessage = 'Connection error: ${e.toString()}'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.green.shade200, Colors.green.shade50, Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: SafeArea(
        bottom: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_errorMessage!, textAlign: TextAlign.center)))
            : SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ============== DATA AB DYNAMIC HAI ==============
              Text(
                'Welcome, ${_studentName ?? 'Student'}!',
                style: GoogleFonts.lato(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 10),
              Text(
                _instituteName ?? 'Your Institute',
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 30),
              _buildSectionTitle('Upcoming Tests', Icons.assignment_turned_in),
              _buildUpcomingTestCard('Physics Chapter 3 Test', 'October 20, 2025', '4:00 PM'),
              const SizedBox(height: 30),
              _buildSectionTitle('Your Timetable', Icons.calendar_month),
              _buildTimetableCard('Physics', 'Monday, 4:00 PM', 'Mr. Rahul Verma', Icons.science),
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
          Icon(icon, color: Colors.green.shade700),
          const SizedBox(width: 8),
          Text(title, style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildUpcomingTestCard(String title, String date, String time) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.timer, color: Colors.blueAccent),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$date at $time'),
      ),
    );
  }

  Widget _buildTimetableCard(String subject, String time, String teacher, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade100,
          child: Icon(icon, color: Colors.green),
        ),
        title: Text(subject, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$time\nBy: $teacher'),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
      ),
    );
  }
}