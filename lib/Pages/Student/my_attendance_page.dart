import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// Dummy data models
class AttendanceLog {
  final DateTime date;
  final String status;

  AttendanceLog({required this.date, required this.status});
}

// ------------------- Naya Page: Student ki Attendance Dikhane Ke Liye -------------------
class MyAttendancePage extends StatelessWidget {
  const MyAttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Abhi ke liye dummy attendance data
    final List<AttendanceLog> attendanceHistory = [
      AttendanceLog(date: DateTime(2025, 10, 5), status: 'Present'),
      AttendanceLog(date: DateTime(2025, 10, 4), status: 'Present'),
      AttendanceLog(date: DateTime(2025, 10, 3), status: 'Absent'),
      AttendanceLog(date: DateTime(2025, 10, 2), status: 'Present'),
      AttendanceLog(date: DateTime(2025, 10, 1), status: 'Leave'),
    ];

    // Attendance summary calculate karna
    final totalLectures = attendanceHistory.length;
    final presentDays =
        attendanceHistory.where((log) => log.status == 'Present').length;
    final percentage =
    totalLectures > 0 ? (presentDays / totalLectures * 100) : 0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade200,
            Colors.green.shade50,
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Attendance Summary Card
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem('Total', '$totalLectures', Colors.blue),
                      _buildSummaryItem('Present', '$presentDays', Colors.green),
                      _buildSummaryItem(
                          'Absent',
                          '${attendanceHistory.where((log) => log.status == 'Absent').length}',
                          Colors.red),
                      _buildSummaryItem(
                          'Attendance',
                          '${percentage.toStringAsFixed(0)}%',
                          Colors.orange),
                    ],
                  ),
                ),
              ),
            ),
            // History list
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Recent History',
                  style: GoogleFonts.lato(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
                itemCount: attendanceHistory.length,
                itemBuilder: (context, index) {
                  final log = attendanceHistory[index];
                  return _buildHistoryItem(log);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Summary item ke liye helper widget
  Widget _buildSummaryItem(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  // History list item ke liye helper widget
  Widget _buildHistoryItem(AttendanceLog log) {
    IconData icon;
    Color color;
    switch (log.status) {
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
        title: Text(DateFormat('EEEE, dd MMMM yyyy').format(log.date)),
        trailing: Text(
          log.status,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
