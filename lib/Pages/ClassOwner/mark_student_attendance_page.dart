// File: lib/Pages/ClassOwner/manage_student_attendance_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AttendanceStatus { Present, Absent, Leave }

// Main Page
class ManageStudentAttendancePage extends StatefulWidget {
  const ManageStudentAttendancePage({super.key});
  @override
  State<ManageStudentAttendancePage> createState() => _ManageStudentAttendancePageState();
}

class _ManageStudentAttendancePageState extends State<ManageStudentAttendancePage> {
  bool _isLoading = true;
  List<dynamic> _allStudents = [];
  List<dynamic> _filteredStudents = [];
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  List<String> _standards = ['All Standards'];
  String _selectedStandard = 'All Standards';

  @override
  void initState() {
    super.initState();
    _fetchStudents();
    _searchController.addListener(_filterStudents);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchStudents() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('https://coaching-api-backend.onrender.com/api/student'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (mounted) {
        if (response.statusCode == 200) {
          final allData = jsonDecode(response.body);
          final uniqueStandards = <String>{'All Standards'};
          for (var student in allData) {
            if (student['standard'] != null) uniqueStandards.add(student['standard']);
          }
          setState(() {
            _allStudents = allData;
            _filteredStudents = _allStudents;
            _standards = uniqueStandards.toList();
            _isLoading = false;
          });
        } else {
          setState(() { _errorMessage = 'Failed to load students.'; _isLoading = false; });
        }
      }
    } catch (e) {
      if (mounted) setState(() { _errorMessage = 'Could not connect to server.'; _isLoading = false; });
    }
  }

  void _filterStudents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStudents = _allStudents.where((student) {
        final nameMatch = student['full_name'].toLowerCase().contains(query);
        final standardMatch = _selectedStandard == 'All Standards' || student['standard'] == _selectedStandard;
        return nameMatch && standardMatch;
      }).toList();
    });
  }

  void _showAttendanceHistoryDialog(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('History for ${student['full_name']}'),
        contentPadding: const EdgeInsets.all(8),
        content: _AttendanceHistoryDialogContent(student: student),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                          hintText: 'Search by student name...',
                          prefixIcon: const Icon(Icons.search)
                      ),
                    )
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _selectedStandard,
                  items: _standards.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
                  onChanged: (newValue) {
                    setState(() { _selectedStandard = newValue!; _filterStudents(); });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: _filteredStudents.length,
              itemBuilder: (context, index) {
                final student = _filteredStudents[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(child: Text(student['full_name'][0])),
                    title: Text(student['full_name']),
                    subtitle: Text('Standard: ${student['standard']}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.history),
                      tooltip: 'View History',
                      onPressed: () => _showAttendanceHistoryDialog(student),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Dialog content and logic
class _AttendanceHistoryDialogContent extends StatefulWidget {
  final Map<String, dynamic> student;
  const _AttendanceHistoryDialogContent({required this.student});
  @override
  State<_AttendanceHistoryDialogContent> createState() => _AttendanceHistoryDialogContentState();
}

class _AttendanceHistoryDialogContentState extends State<_AttendanceHistoryDialogContent> {
  bool _isLoading = true;
  List<dynamic> _history = [];
  String? _errorMessage;
  List<dynamic> _selectedRecords = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() { _isLoading = true; _errorMessage = null; _selectedRecords.clear(); });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final studentId = widget.student['id'];
      final response = await http.get(
        Uri.parse('https://coaching-api-backend.onrender.com/api/attendance/student/history/$studentId'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));

      if(mounted){
        if(response.statusCode == 200){
          setState(() { _history = jsonDecode(response.body); _isLoading = false; });
        } else {
          setState(() { _errorMessage = "Failed to load history. Status: ${response.statusCode}"; _isLoading = false; });
        }
      }
    } catch(e) {
      if(mounted) setState(() { _errorMessage = "Connection error: ${e.toString()}"; _isLoading = false; });
    }
  }

  Future<void> _updateRecord(String recordId, String status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.put(
        Uri.parse('https://coaching-api-backend.onrender.com/api/attendance/student/record/$recordId'),
        headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer $token' },
        body: jsonEncode({'status': status}),
      );
      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status updated!'), backgroundColor: Colors.green));
          _fetchHistory();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update status.'), backgroundColor: Colors.red));
        }
      }
    } catch(e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connection error.'), backgroundColor: Colors.red));
    }
  }

  Future<void> _deleteRecords(List<dynamic> recordIds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.delete(
        Uri.parse('https://coaching-api-backend.onrender.com/api/attendance/student/records'),
        headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer $token' },
        body: jsonEncode({'recordIds': recordIds}),
      );
      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selected records deleted!'), backgroundColor: Colors.green));
          _fetchHistory();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete records.'), backgroundColor: Colors.red));
        }
      }
    } catch(e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connection error.'), backgroundColor: Colors.red));
    }
  }

  String _statusToString(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.Present: return 'Present';
      case AttendanceStatus.Absent: return 'Absent';
      case AttendanceStatus.Leave: return 'Leave';
    }
  }

  void _showUpdateStatusDialog(Map<String, dynamic> record) {
    AttendanceStatus? tempStatus;
    try {
      tempStatus = AttendanceStatus.values.firstWhere((e) => e.name == record['status']);
    } catch(e) {
      tempStatus = null;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text("Update status for ${DateFormat('dd-MM-yyyy').format(DateTime.parse(record['attendance_date']))}"),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setStateAlert) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<AttendanceStatus>(title: const Text('Present'), value: AttendanceStatus.Present, groupValue: tempStatus, onChanged: (val) => setStateAlert(() => tempStatus = val)),
                  RadioListTile<AttendanceStatus>(title: const Text('Absent'), value: AttendanceStatus.Absent, groupValue: tempStatus, onChanged: (val) => setStateAlert(() => tempStatus = val)),
                  RadioListTile<AttendanceStatus>(title: const Text('Leave'), value: AttendanceStatus.Leave, groupValue: tempStatus, onChanged: (val) => setStateAlert(() => tempStatus = val)),
                ],
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final status = tempStatus;
                if (status != null) {
                  String newStatus = _statusToString(status);
                  _updateRecord(record['id'], newStatus);
                }
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Update'),
            )
          ],
        );
      },
    );
  }

  Color _getToggleFillColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.Present: return Colors.green;
      case AttendanceStatus.Absent: return Colors.red;
      case AttendanceStatus.Leave: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Delete Selected (${_selectedRecords.length})'),
                IconButton(icon: const Icon(Icons.delete_sweep, color: Colors.red), onPressed: _selectedRecords.isEmpty ? null : () => _deleteRecords(_selectedRecords.map((r) => r['id'] as String).toList())),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: _history.isEmpty
                ? const Center(child: Text("No attendance history found."))
                : ListView.builder(
              shrinkWrap: true,
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final record = _history[index];
                return CheckboxListTile(
                  value: _selectedRecords.contains(record),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value!) _selectedRecords.add(record);
                      else _selectedRecords.remove(record);
                    });
                  },
                  title: Text(DateFormat('dd MMM, yyyy').format(DateTime.parse(record['attendance_date']))),
                  secondary: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(record['status'][0], style: TextStyle(color: _getToggleFillColor(AttendanceStatus.values.firstWhere((e) => e.name == record['status'])), fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _showUpdateStatusDialog(record)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}