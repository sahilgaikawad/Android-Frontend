import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AttendanceStatus { present, absent, leave }

class TeacherMarkAttendancePage extends StatefulWidget {
  const TeacherMarkAttendancePage({super.key});

  @override
  State<TeacherMarkAttendancePage> createState() => _TeacherMarkAttendancePageState();
}

class _TeacherMarkAttendancePageState extends State<TeacherMarkAttendancePage> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true; // Initially true to load classes
  String? _errorMessage;

  List<dynamic> _students = [];
  Map<String, AttendanceStatus> _attendanceData = {};

  List<String> _assignedClasses = ['Select Class'];
  String? _selectedClass;

  @override
  void initState() {
    super.initState();
    _selectedClass = _assignedClasses[0];
    _fetchAssignedClasses(); // Fetch classes when the page loads
  }

  // New function to fetch the teacher's assigned classes from the backend
  Future<void> _fetchAssignedClasses() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('https://coaching-api-backend.onrender.com/api/teacher/profile/my-classes'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (mounted) {
        if (response.statusCode == 200) {
          final List<String> classes = List<String>.from(jsonDecode(response.body));
          setState(() {
            _assignedClasses = ['Select Class', ...classes];
            _isLoading = false;
          });
        } else {
          setState(() { _errorMessage = 'Failed to load assigned classes.'; _isLoading = false; });
        }
      }
    } catch (e) {
      if (mounted) setState(() { _errorMessage = 'Could not connect to server.'; _isLoading = false; });
    }
  }

  Future<void> _fetchAttendanceData() async {
    if (_selectedClass == null || _selectedClass == 'Select Class') {
      setState(() {
        _students = [];
        _isLoading = false;
      });
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

      final response = await http.get(
        Uri.parse('https://coaching-api-backend.onrender.com/api/attendance/student?date=$formattedDate&standard=$_selectedClass'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));

      if (mounted) {
        if (response.statusCode == 200) {
          final List<dynamic> fetchedStudents = jsonDecode(response.body);
          final Map<String, AttendanceStatus> newAttendanceData = {};
          for (var student in fetchedStudents) {
            final studentId = student['id'];
            switch (student['status']) {
              case 'Present': newAttendanceData[studentId] = AttendanceStatus.present; break;
              case 'Absent': newAttendanceData[studentId] = AttendanceStatus.absent; break;
              case 'Leave': newAttendanceData[studentId] = AttendanceStatus.leave; break;
              default: newAttendanceData[studentId] = AttendanceStatus.present;
            }
          }
          setState(() {
            _students = fetchedStudents;
            _attendanceData = newAttendanceData;
            _isLoading = false;
          });
        } else {
          setState(() { _errorMessage = 'Failed to load students. Status: ${response.statusCode}'; _isLoading = false; });
        }
      }
    } catch(e) {
      if (mounted) setState(() { _errorMessage = 'Could not connect to server: ${e.toString()}'; _isLoading = false; });
    }
  }

  Future<void> _saveAttendance() async {
    if (_selectedClass == 'Select Class' || _students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a class with students.'), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

      final List<Map<String, String>> attendancePayload = [];
      _attendanceData.forEach((studentId, status) {
        String statusString;
        switch (status) {
          case AttendanceStatus.present: statusString = 'Present'; break;
          case AttendanceStatus.absent: statusString = 'Absent'; break;
          case AttendanceStatus.leave: statusString = 'Leave'; break;
        }
        attendancePayload.add({'student_id': studentId, 'status': statusString});
      });

      final response = await http.post(
        Uri.parse('https://coaching-api-backend.onrender.com/api/attendance/student'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({
          'date': formattedDate,
          'attendanceData': attendancePayload,
        }),
      ).timeout(const Duration(seconds: 15));

      if (mounted) {
        final responseData = jsonDecode(response.body);
        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseData['message']), backgroundColor: Colors.green));
          _fetchAttendanceData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseData['message']), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Connection error: ${e.toString()}'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _fetchAttendanceData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.purple.shade200, Colors.purple.shade50, Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildDateAndClassSelector(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? Center(child: Text(_errorMessage!))
                  : _students.isEmpty
                  ? const Center(child: Text('No students found for this class.'))
                  : RefreshIndicator(
                onRefresh: _fetchAttendanceData,
                child: ListView.builder(
                  itemCount: _students.length,
                  itemBuilder: (context, index) {
                    final student = _students[index];
                    return _buildStudentAttendanceItem(student);
                  },
                ),
              ),
            ),
            if (!_isLoading) _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateAndClassSelector() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(DateFormat('dd MMMM, yyyy').format(_selectedDate), style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton(
                onPressed: () => _selectDate(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                child: const Text('Change Date'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedClass,
            decoration: InputDecoration(
              labelText: 'Select Class',
              labelStyle: const TextStyle(color: Colors.purple),
              filled: true,
              fillColor: Colors.white.withOpacity(0.8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.purple)),
            ),
            items: _assignedClasses.map((String className) => DropdownMenuItem<String>(value: className, child: Text(className))).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedClass = newValue;
                _fetchAttendanceData();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStudentAttendanceItem(Map<String, dynamic> student) {
    final studentId = student['id'] as String;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.purple.shade100,
              child: Text(student['full_name'][0], style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(student['full_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            ToggleButtons(
              isSelected: [
                _attendanceData[studentId] == AttendanceStatus.present,
                _attendanceData[studentId] == AttendanceStatus.absent,
                _attendanceData[studentId] == AttendanceStatus.leave,
              ],
              onPressed: (int index) {
                setState(() { _attendanceData[studentId] = AttendanceStatus.values[index]; });
              },
              borderRadius: BorderRadius.circular(8),
              selectedColor: Colors.white,
              fillColor: _getToggleFillColor(_attendanceData[studentId]!),
              color: Colors.black54,
              constraints: const BoxConstraints(minHeight: 36.0, minWidth: 40.0),
              children: const [
                Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('P')),
                Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('A')),
                Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('L')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getToggleFillColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present: return Colors.green;
      case AttendanceStatus.absent: return Colors.red;
      case AttendanceStatus.leave: return Colors.orange;
      default: return Colors.grey;
    }
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
        ),
        onPressed: _isLoading ? null : _saveAttendance,
        child: _isLoading
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
            : const Text('Save Attendance', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}