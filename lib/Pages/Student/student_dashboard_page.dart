import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import '../login_page.dart';
import 'my_attendance_page.dart';
import 'my_fees_page.dart';
import 'my_profile_page.dart'; // Naya page import kiya

// ------------------- Naya Page: Student ka Main Dashboard -------------------
class StudentDashboardPage extends StatefulWidget {
  const StudentDashboardPage({super.key});

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  int _pageIndex = 0;

  // Student ke liye alag pages, placeholder ko naye page se replace kiya
  final List<Widget> _pages = [
    const StudentHome(),
    const MyAttendancePage(),
    const MyFeesPage(),
    const MyProfilePage(), // Yahan badlav kiya hai
  ];

  final List<String> _titles = [
    'Dashboard',
    'My Attendance',
    'My Fees',
    'My Profile'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(_titles[_pageIndex]),
        centerTitle: true,
        backgroundColor: Colors.green.withOpacity(0.8),
        elevation: 0,
        // Back button ab sirf doosre pages par dikhega
        leading: _pageIndex != 0
            ? IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            // Back button dabane par dashboard (index 0) par jayenge
            setState(() {
              _pageIndex = 0;
            });
          },
        )
            : null, // Dashboard par back button nahi hoga
        actions: [
          // Logout button wapas add kar diya hai
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                    (Route<dynamic> route) => false,
              );
            },
          )
        ],
      ),
      bottomNavigationBar: CurvedNavigationBar(
        // Navigation bar ko bhi page ke hisaab se update kiya
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
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 400),
        onTap: (index) {
          setState(() {
            _pageIndex = index;
          });
        },
        letIndexChange: (index) => true,
      ),
      body: _pages[_pageIndex],
    );
  }
}

// ------------------- Student ka Home Page (Timetable) -------------------
class StudentHome extends StatelessWidget {
  const StudentHome({super.key});

  @override
  Widget build(BuildContext context) {
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, Aarav!',
                style: GoogleFonts.lato(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Here is your schedule and updates',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 30),
              _buildSectionTitle('Upcoming Tests', Icons.assignment_turned_in),
              _buildUpcomingTestCard(
                  'Physics Chapter 3 Test', 'October 10, 2025', '4:00 PM'),
              _buildUpcomingTestCard(
                  'Maths Weekly Test', 'October 12, 2025', '5:00 PM'),
              const SizedBox(height: 30),
              _buildSectionTitle('Recent Announcements', Icons.campaign),
              _buildAnnouncementCard('Diwali Holidays',
                  'Classes will be closed from 15th Oct to 20th Oct for Diwali.'),
              const SizedBox(height: 30),
              _buildSectionTitle('Your Timetable', Icons.calendar_month),
              _buildTimetableCard('Physics', 'Monday, 4:00 PM - 5:00 PM',
                  'Mr. Rahul Verma', Icons.science),
              _buildTimetableCard('Chemistry', 'Tuesday, 5:00 PM - 6:00 PM',
                  'Mrs. Sunita Nair', Icons.biotech),
              _buildTimetableCard('Mathematics', 'Wednesday, 4:00 PM - 5:00 PM',
                  'Mrs. Anjali Singh', Icons.calculate),
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
          Text(
            title,
            style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingTestCard(String title, String date, String time) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white.withOpacity(0.8),
      child: ListTile(
        leading: const Icon(Icons.timer, color: Colors.blueAccent),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$date at $time'),
      ),
    );
  }

  Widget _buildAnnouncementCard(String title, String message) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.amber.shade50.withOpacity(0.8),
      child: ListTile(
        leading: const Icon(Icons.info, color: Colors.amber),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(message),
      ),
    );
  }

  Widget _buildTimetableCard(
      String subject, String time, String teacher, IconData icon) {
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
        trailing:
        const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
      ),
    );
  }
}

// ------------------- Placeholder Page for other sections -------------------
class PlaceholderPage extends StatelessWidget {
  final String pageName;
  final IconData icon;
  const PlaceholderPage({super.key, required this.pageName, required this.icon});

  @override
  Widget build(BuildContext context) {
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
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.green.withOpacity(0.5)),
            const SizedBox(height: 20),
            Text(
              '$pageName\n(Coming Soon)',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

