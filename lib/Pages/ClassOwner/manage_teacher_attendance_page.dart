// File: lib/ClassOwner/manage_teacher_attendance_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Enum is declared at the top level
enum AttendanceStatus { Present, Absent, Leave }

// Main Page
class ManageTeacherAttendancePage extends StatefulWidget {
  const ManageTeacherAttendancePage({super.key});
  @override
  State<ManageTeacherAttendancePage> createState() => _ManageTeacherAttendancePageState();
}

class _ManageTeacherAttendancePageState extends State<ManageTeacherAttendancePage> {
  bool _isLoading = true;
  List<dynamic> _allTeachers = [];
  List<dynamic> _filteredTeachers = [];
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchTeachers();
    _searchController.addListener(_filterTeachers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchTeachers() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('https://coaching-api-backend.onrender.com:10000/api/teacher'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (mounted) {
        if (response.statusCode == 200) {
          setState(() {
            _allTeachers = jsonDecode(response.body);
            _filteredTeachers = _allTeachers;
            _isLoading = false;
          });
        } else {
          setState(() { _errorMessage = 'Failed to load teachers.'; _isLoading = false; });
        }
      }
    } catch (e) {
      if (mounted) setState(() { _errorMessage = 'Could not connect to server.'; _isLoading = false; });
    }
  }

  void _filterTeachers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredTeachers = _allTeachers.where((teacher) {
        return teacher['full_name'].toLowerCase().contains(query) || (teacher['subject'] != null && teacher['subject'].toLowerCase().contains(query));
      }).toList();
    });
  }

  void _showAttendanceHistoryDialog(Map<String, dynamic> teacher) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('History for ${teacher['full_name']}'),
        contentPadding: const EdgeInsets.all(8),
        content: _AttendanceHistoryDialogContent(teacher: teacher),
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
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by teacher name or subject...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.white.withOpacity(0.8),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: _filteredTeachers.length,
              itemBuilder: (context, index) {
                final teacher = _filteredTeachers[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    leading: CircleAvatar(backgroundColor: Colors.teal.shade100, child: Text(teacher['full_name'][0], style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold))),
                    title: Text(teacher['full_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text(teacher['subject'] ?? 'No Subject', style: const TextStyle(color: Colors.grey)),
                    trailing: IconButton(
                      icon: const Icon(Icons.history, color: Colors.blueGrey, size: 28),
                      tooltip: 'View History',
                      onPressed: () => _showAttendanceHistoryDialog(teacher),
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
  final Map<String, dynamic> teacher;
  const _AttendanceHistoryDialogContent({required this.teacher});

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
      final teacherId = widget.teacher['id'];

      // ============== BADLAV YAHAN HUA HAI: URL me '/history' joda gaya hai ==============
      final response = await http.get(
        Uri.parse('https://coaching-api-backend.onrender.com:10000/api/attendance/teacher/history/$teacherId'),
        headers: {'Authorization': 'Bearer $token'},
      );

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
        Uri.parse('https://coaching-api-backend.onrender.com:10000/api/attendance/teacher/record/$recordId'),
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
        Uri.parse('https://coaching-api-backend.onrender.com:10000/api/attendance/teacher/records'),
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
    final statusMap = {
      'present': AttendanceStatus.Present,
      'absent': AttendanceStatus.Absent,
      'leave': AttendanceStatus.Leave,
    };
    AttendanceStatus? tempStatus = statusMap[record['status']?.toLowerCase()];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text("Update status for ${DateFormat('dd-MM-yyyy').format(DateTime.parse(record['attendance_date']))}"),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setStateAlert) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: AttendanceStatus.values.map((status) {
                  return RadioListTile<AttendanceStatus>(
                    title: Text(status.name),
                    value: status,
                    groupValue: tempStatus,
                    onChanged: (val) => setStateAlert(() => tempStatus = val),
                  );
                }).toList(),
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

  Color _getStatusColor(String status) {
    if (status == 'Present') return Colors.green;
    if (status == 'Absent') return Colors.red;
    return Colors.orange;
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
                      Text(record['status'][0], style: TextStyle(color: _getStatusColor(record['status']), fontWeight: FontWeight.bold)),
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