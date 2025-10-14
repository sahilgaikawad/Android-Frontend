// File: lib/Pages/Student/my_attendance_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// BADLAV 1: Widget ab StatefulWidget hai
class MyAttendancePage extends StatefulWidget {
  const MyAttendancePage({super.key});

  @override
  State<MyAttendancePage> createState() => _MyAttendancePageState();
}

class _MyAttendancePageState extends State<MyAttendancePage> {
  bool _isLoading = true;
  String? _errorMessage;
  // BADLAV 2: Dummy data hata diya gaya hai
  List<dynamic> _attendanceHistory = [];

  @override
  void initState() {
    super.initState();
    _fetchMyAttendanceHistory();
  }

  // BADLAV 3: API se history fetch karne ka function
  Future<void> _fetchMyAttendanceHistory() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('https://coaching-api-backend.onrender.com:10000/api/attendance/student/my-history'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (mounted) {
        if (response.statusCode == 200) {
          setState(() {
            _attendanceHistory = jsonDecode(response.body);
            _isLoading = false;
          });
        } else {
          setState(() { _errorMessage = 'Failed to load attendance history. Status: ${response.statusCode}'; _isLoading = false; });
        }
      }
    } catch (e) {
      if (mounted) setState(() { _errorMessage = 'Could not connect to server: ${e.toString()}'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    // BADLAV 4: build() method ab loading/error handle karta hai
    final totalLectures = _attendanceHistory.length;
    final presentDays = _attendanceHistory.where((r) => r['status'] == 'Present').length;
    final percentage = totalLectures > 0 ? (presentDays / totalLectures * 100) : 0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade200, Colors.green.shade50, Colors.white],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(child: Text(_errorMessage!))
            : Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem('Total', '$totalLectures', Colors.blue),
                      _buildSummaryItem('Present', '$presentDays', Colors.green),
                      _buildSummaryItem('Absent', '${_attendanceHistory.where((log) => log['status'] == 'Absent').length}', Colors.red),
                      _buildSummaryItem('Attendance', '${percentage.toStringAsFixed(0)}%', Colors.orange),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Recent History', style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchMyAttendanceHistory,
                child: _attendanceHistory.isEmpty
                    ? const Center(child: Text("No attendance history found."))
                    : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
                  itemCount: _attendanceHistory.length,
                  itemBuilder: (context, index) {
                    final log = _attendanceHistory[index];
                    return _buildHistoryItem(log);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  // BADLAV 5: Helper ab Map<String, dynamic> leta hai
  Widget _buildHistoryItem(Map<String, dynamic> log) {
    IconData icon;
    Color color;
    switch (log['status']) {
      case 'Present':
        icon = Icons.check_circle_outline;
        color = Colors.green;
        break;
      case 'Absent':
        icon = Icons.cancel_outlined;
        color = Colors.red;
        break;
      default:
        icon = Icons.info_outline;
        color = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(DateFormat('EEEE, dd MMMM yyyy').format(DateTime.parse(log['attendance_date']))),
        trailing: Text(log['status'], style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ),
    );
  }
}