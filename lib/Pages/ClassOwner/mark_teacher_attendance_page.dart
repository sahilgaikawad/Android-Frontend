import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Attendance status enum
enum AttendanceStatus { present, absent, leave }

class MarkTeacherAttendancePage extends StatefulWidget {
  const MarkTeacherAttendancePage({super.key});

  @override
  State<MarkTeacherAttendancePage> createState() => _MarkTeacherAttendancePageState();
}

class _MarkTeacherAttendancePageState extends State<MarkTeacherAttendancePage> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  String? _errorMessage;

  List<dynamic> _teachers = [];
  Map<String, AttendanceStatus> _attendanceData = {};

  @override
  void initState() {
    super.initState();
    _fetchAttendanceData();
  }

  Future<void> _fetchAttendanceData() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

      // TIMEOUT ADDED HERE
      final response = await http.get(
        Uri.parse('https://coaching-api-backend.onrender.com/api/attendance/teacher?date=$formattedDate'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));

      if (mounted) {
        if (response.statusCode == 200) {
          final List<dynamic> fetchedTeachers = jsonDecode(response.body);
          final Map<String, AttendanceStatus> newAttendanceData = {};

          for (var teacher in fetchedTeachers) {
            final teacherId = teacher['id'];
            switch (teacher['status']) {
              case 'Present':
                newAttendanceData[teacherId] = AttendanceStatus.present;
                break;
              case 'Absent':
                newAttendanceData[teacherId] = AttendanceStatus.absent;
                break;
              case 'Leave':
                newAttendanceData[teacherId] = AttendanceStatus.leave;
                break;
              default:
                newAttendanceData[teacherId] = AttendanceStatus.present;
            }
          }
          setState(() {
            _teachers = fetchedTeachers;
            _attendanceData = newAttendanceData;
            _isLoading = false;
          });
        } else {
          setState(() { _errorMessage = 'Failed to load data. Status: ${response.statusCode}'; _isLoading = false; });
        }
      }
    } catch(e) {
      if (mounted) setState(() { _errorMessage = 'Could not connect to server: ${e.toString()}'; _isLoading = false; });
    }
  }

  Future<void> _saveAttendance() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

      final List<Map<String, String>> attendancePayload = [];
      _attendanceData.forEach((teacherId, status) {
        String statusString;
        switch (status) {
          case AttendanceStatus.present: statusString = 'Present'; break;
          case AttendanceStatus.absent: statusString = 'Absent'; break;
          case AttendanceStatus.leave: statusString = 'Leave'; break;
        }
        attendancePayload.add({'teacher_id': teacherId, 'status': statusString});
      });

      // TIMEOUT ADDED HERE
      final response = await http.post(
        Uri.parse('https://coaching-api-backend.onrender.com/api/attendance/teacher'),
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
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.lightBlue.shade200, Colors.lightBlue.shade50, Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: SafeArea(
          child: _isLoading && _teachers.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_errorMessage!, textAlign: TextAlign.center)))
              : Column(
            children: [
              _buildDateSelector(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _fetchAttendanceData,
                  child: ListView.builder(
                    itemCount: _teachers.length,
                    itemBuilder: (context, index) {
                      final teacher = _teachers[index];
                      return _buildTeacherAttendanceItem(teacher);
                    },
                  ),
                ),
              ),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(DateFormat('dd MMMM, yyyy').format(_selectedDate), style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () => _selectDate(context),
                icon: const Icon(Icons.calendar_today, size: 18),
                label: const Text('Change'),
                style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeacherAttendanceItem(Map<String, dynamic> teacher) {
    final teacherId = teacher['id'] as String;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.teal.shade100,
              child: Text(teacher['full_name'][0], style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(teacher['full_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(teacher['subject'] ?? 'No Subject', style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            ToggleButtons(
              isSelected: [
                _attendanceData[teacherId] == AttendanceStatus.present,
                _attendanceData[teacherId] == AttendanceStatus.absent,
                _attendanceData[teacherId] == AttendanceStatus.leave,
              ],
              onPressed: (int index) {
                setState(() { _attendanceData[teacherId] = AttendanceStatus.values[index]; });
              },
              borderRadius: BorderRadius.circular(8),
              selectedColor: Colors.white,
              fillColor: _getToggleFillColor(_attendanceData[teacherId]!),
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
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.absent:
        return Colors.red;
      case AttendanceStatus.leave:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: _isLoading ? null : _saveAttendance,
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Save Attendance', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}