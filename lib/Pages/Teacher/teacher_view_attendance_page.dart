// File: lib/Pages/Teacher/teacher_view_attendance_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// BADLAV 1: Widget ab StatefulWidget hai
class TeacherViewAttendancePage extends StatefulWidget {
  const TeacherViewAttendancePage({super.key});

  @override
  State<TeacherViewAttendancePage> createState() => _TeacherViewAttendancePageState();
}

class _TeacherViewAttendancePageState extends State<TeacherViewAttendancePage> {
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
        Uri.parse('http://192.168.1.103:5001/api/attendance/teacher/my-history'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (mounted) {
        if (response.statusCode == 200) {
          setState(() {
            _attendanceHistory = jsonDecode(response.body);
            _isLoading = false;
          });
        } else {
          setState(() { _errorMessage = 'Failed to load attendance history.'; _isLoading = false; });
        }
      }
    } catch (e) {
      if (mounted) setState(() { _errorMessage = 'Could not connect to server.'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    // BADLAV 4: build() method ab loading/error handle karta hai
    int presentDays = _attendanceHistory.where((r) => r['status'] == 'Present').length;
    int absentDays = _attendanceHistory.where((r) => r['status'] == 'Absent').length;
    int leaveDays = _attendanceHistory.where((r) => r['status'] == 'Leave').length;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade200, Colors.purple.shade50, Colors.white],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
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
              Text('Your Attendance Summary', style: GoogleFonts.lato(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 16, mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildSummaryCard('Present', '$presentDays Days', Colors.green),
                  _buildSummaryCard('Absent', '$absentDays Days', Colors.red),
                  _buildSummaryCard('Leave', '$leaveDays Days', Colors.orange),
                ],
              ),
              const SizedBox(height: 24),
              Text('Detailed History', style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _attendanceHistory.isEmpty
                  ? const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text("No history found.")))
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _attendanceHistory.length,
                itemBuilder: (context, index) {
                  final record = _attendanceHistory[index];
                  return _buildAttendanceHistoryItem(record);
                },
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'Present':
        return {'icon': Icons.check_circle, 'color': Colors.green};
      case 'Absent':
        return {'icon': Icons.cancel, 'color': Colors.red};
      case 'Leave':
        return {'icon': Icons.time_to_leave, 'color': Colors.orange};
      default:
        return {'icon': Icons.help, 'color': Colors.grey};
    }
  }

  // BADLAV 5: Helper ab Map<String, dynamic> leta hai
  Widget _buildAttendanceHistoryItem(Map<String, dynamic> record) {
    final statusInfo = _getStatusInfo(record['status']);
    final date = DateTime.parse(record['attendance_date']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusInfo['color'].withOpacity(0.2),
          child: Icon(statusInfo['icon'], color: statusInfo['color']),
        ),
        title: Text(DateFormat('EEEE, dd MMM yyyy').format(date)),
        trailing: Text(
          record['status'],
          style: TextStyle(color: statusInfo['color'], fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}