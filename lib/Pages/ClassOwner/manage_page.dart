import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Dropdown ke actions ko manage karne ke liye, naye actions add kiye
enum ManageAction {
  addStudent,
  viewStudents,
  addTeacher,
  viewTeachers,
  markTeacherAttendance,
  manageStudentAttendance,
  manageTeacherAttendance,
}

// ------------------- Management Portal Page (Updated with New Attendance Menu) -------------------
class ManagePage extends StatelessWidget {
  // Saare callbacks yahan define kiye hain
  final VoidCallback onAddStudent;
  final VoidCallback onViewStudents;
  final VoidCallback onAddTeacher;
  final VoidCallback onViewTeachers;
  final VoidCallback onMarkTeacherAttendance;
  final VoidCallback onManageStudentAttendance;
  final VoidCallback onManageTeacherAttendance;

  const ManagePage({
    super.key,
    required this.onAddStudent,
    required this.onViewStudents,
    required this.onAddTeacher,
    required this.onViewTeachers,
    required this.onMarkTeacherAttendance,
    required this.onManageStudentAttendance,
    required this.onManageTeacherAttendance,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(height: 20),
            Text(
              'Management Portal',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 30),

            // Student Management Card
            _buildManagementCard(
              context: context,
              title: 'Manage Students',
              icon: Icons.people_alt_rounded,
              color: Colors.orange,
              onSelected: (action) {
                if (action == ManageAction.addStudent) {
                  onAddStudent();
                } else if (action == ManageAction.viewStudents) {
                  onViewStudents();
                }
              },
            ),
            const SizedBox(height: 20),

            // Teacher Management Card
            _buildManagementCard(
              context: context,
              title: 'Manage Teachers',
              icon: Icons.person_pin_rounded,
              color: Colors.teal,
              onSelected: (action) {
                if (action == ManageAction.addTeacher) {
                  onAddTeacher();
                } else if (action == ManageAction.viewTeachers) {
                  onViewTeachers();
                }
              },
            ),
            const SizedBox(height: 20),

            // Naya Attendance Management Card
            _buildAttendanceCard(
              context: context,
              title: 'Manage Attendance',
              icon: Icons.checklist_rtl_rounded,
              color: Colors.indigo,
              onSelected: (action) {
                if (action == ManageAction.markTeacherAttendance) {
                  onMarkTeacherAttendance();
                } else if (action == ManageAction.manageStudentAttendance) {
                  onManageStudentAttendance();
                } else if (action == ManageAction.manageTeacherAttendance) {
                  onManageTeacherAttendance();
                }
              },
            ),

            const SizedBox(height: 80), // Bottom nav bar ke liye jagah
          ],
        ),
      ),
    );
  }

  // Student/Teacher ke liye card
  Widget _buildManagementCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required PopupMenuItemSelected<ManageAction> onSelected,
  }) {
    bool isStudent = title.contains("Students");
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: color.withOpacity(0.3),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(
          title,
          style: GoogleFonts.lato(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        trailing: PopupMenuButton<ManageAction>(
          icon: const Icon(Icons.more_vert),
          onSelected: onSelected,
          itemBuilder: (BuildContext context) => <PopupMenuEntry<ManageAction>>[
            PopupMenuItem<ManageAction>(
              value: isStudent
                  ? ManageAction.addStudent
                  : ManageAction.addTeacher,
              child: const ListTile(
                leading: Icon(Icons.add, color: Colors.green),
                title: Text('Add New'),
              ),
            ),
            PopupMenuItem<ManageAction>(
              value: isStudent
                  ? ManageAction.viewStudents
                  : ManageAction.viewTeachers,
              child: const ListTile(
                leading: Icon(Icons.list, color: Colors.blue),
                title: Text('View All'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Attendance ke liye naya card
  Widget _buildAttendanceCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required PopupMenuItemSelected<ManageAction> onSelected,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: color.withOpacity(0.3),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(
          title,
          style: GoogleFonts.lato(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        trailing: PopupMenuButton<ManageAction>(
          icon: const Icon(Icons.more_vert),
          onSelected: onSelected,
          itemBuilder: (BuildContext context) => <PopupMenuEntry<ManageAction>>[
            const PopupMenuItem<ManageAction>(
              value: ManageAction.markTeacherAttendance,
              child: ListTile(
                leading: Icon(Icons.edit_calendar, color: Colors.blueAccent),
                title: Text('Mark Teacher Attendance'),
              ),
            ),
            const PopupMenuItem<ManageAction>(
              value: ManageAction.manageStudentAttendance,
              child: ListTile(
                leading: Icon(Icons.person_search, color: Colors.orange),
                title: Text('Manage Student Attendance'),
              ),
            ),
            const PopupMenuItem<ManageAction>(
              value: ManageAction.manageTeacherAttendance,
              child: ListTile(
                leading: Icon(Icons.hail, color: Colors.teal),
                title: Text('Manage Teacher Attendance'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

