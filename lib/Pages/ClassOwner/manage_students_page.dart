// File: lib/ClassOwner/manage_students_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ManageStudentsPage extends StatefulWidget {
  // onAddStudent parameter has been removed
  const ManageStudentsPage({super.key});

  @override
  State<ManageStudentsPage> createState() => _ManageStudentsPageState();
}

class _ManageStudentsPageState extends State<ManageStudentsPage> {
  bool _isLoading = true;
  List<dynamic> _allStudents = [];
  List<dynamic> _filteredStudents = [];
  List<String> _standards = ['All Standards'];
  String _selectedStandard = 'All Standards';
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

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
        Uri.parse('https://coaching-api-backend.onrender.com:10000/api/student'),
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

  Future<void> _deleteStudent(String studentId) async {
    final bool? confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this student?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        final response = await http.delete(
          Uri.parse('https://coaching-api-backend.onrender.com:10000/api/student/$studentId'),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (mounted) {
          if (response.statusCode == 200) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student deleted successfully!'), backgroundColor: Colors.green));
            _fetchStudents();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete student.'), backgroundColor: Colors.red));
          }
        }
      } catch (e) {
        // ============== CATCH BLOCK FIXED ==============
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not connect to server.'), backgroundColor: Colors.red));
        }
      }
    }
  }

  Future<void> _showEditStudentDialog(Map<String, dynamic> studentData) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Student Details'),
          content: _EditStudentDialogContent(studentData: studentData),
          actions: <Widget>[
            TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop(false)),
          ],
        );
      },
    );
    if (result == true) _fetchStudents();
  }

  void _showStudentDetailsDialog(String studentId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Student Profile"),
          content: _StudentDetailsDialogContent(studentId: studentId),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Close"))
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(child: TextField(controller: _searchController, decoration: const InputDecoration(labelText: 'Search by name...', prefixIcon: Icon(Icons.search)))),
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
              : RefreshIndicator(
            onRefresh: _fetchStudents,
            child: ListView.builder(
              itemCount: _filteredStudents.length,
              itemBuilder: (context, index) {
                final student = _filteredStudents[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(child: Text(student['full_name'][0])),
                    title: Text(student['full_name']),
                    subtitle: Text('Standard: ${student['standard']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.visibility_outlined, color: Colors.blue), onPressed: () => _showStudentDetailsDialog(student['id'])),
                        IconButton(icon: Icon(Icons.edit_outlined, color: Colors.grey.shade600), onPressed: () => _showEditStudentDialog(student)),
                        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _deleteStudent(student['id'])),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _EditStudentDialogContent extends StatefulWidget {
  final Map<String, dynamic> studentData;
  const _EditStudentDialogContent({required this.studentData});
  @override
  State<_EditStudentDialogContent> createState() => __EditStudentDialogContentState();
}

class __EditStudentDialogContentState extends State<_EditStudentDialogContent> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController, _standardController, _studentPhoneController, _parentPhoneController, _addressController, _assignedClassController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.studentData['full_name']);
    _standardController = TextEditingController(text: widget.studentData['standard']);
    _studentPhoneController = TextEditingController(text: widget.studentData['student_phone']);
    _parentPhoneController = TextEditingController(text: widget.studentData['parent_phone']);
    _addressController = TextEditingController(text: widget.studentData['address']);
    _assignedClassController = TextEditingController(text: widget.studentData['assigned_class']);
  }

  @override
  void dispose() {
    _nameController.dispose();_standardController.dispose();_studentPhoneController.dispose();_parentPhoneController.dispose();_addressController.dispose();_assignedClassController.dispose();
    super.dispose();
  }

  Future<void> _updateStudent() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final studentId = widget.studentData['id'];
      final response = await http.put(
        Uri.parse('https://coaching-api-backend.onrender.com:10000/api/student/$studentId'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({
          'full_name': _nameController.text, 'standard': _standardController.text,
          'student_phone': _studentPhoneController.text, 'parent_phone': _parentPhoneController.text,
          'address': _addressController.text, 'assigned_class': _assignedClassController.text,
        }),
      );
      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student updated successfully!'), backgroundColor: Colors.green));
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update student.'), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      // ============== CATCH BLOCK FIXED ==============
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connection Error.'), backgroundColor: Colors.red));
      }
    }
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: "Full Name")),
            const SizedBox(height: 16),
            TextFormField(controller: _standardController, decoration: const InputDecoration(labelText: "Standard")),
            const SizedBox(height: 16),
            TextFormField(controller: _studentPhoneController, decoration: const InputDecoration(labelText: "Student's Phone")),
            const SizedBox(height: 16),
            TextFormField(controller: _parentPhoneController, decoration: const InputDecoration(labelText: "Parent's Phone")),
            const SizedBox(height: 16),
            TextFormField(controller: _addressController, decoration: const InputDecoration(labelText: "Address")),
            const SizedBox(height: 16),
            TextFormField(controller: _assignedClassController, decoration: const InputDecoration(labelText: "Assigned Class")),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _updateStudent,
              child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 3)) : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentDetailsDialogContent extends StatefulWidget {
  final String studentId;
  const _StudentDetailsDialogContent({required this.studentId});
  @override
  State<_StudentDetailsDialogContent> createState() => _StudentDetailsDialogContentState();
}

class _StudentDetailsDialogContentState extends State<_StudentDetailsDialogContent> {
  bool _isLoading = true;
  Map<String, dynamic>? _studentData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchStudentDetails();
  }

  Future<void> _fetchStudentDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('https://coaching-api-backend.onrender.com:10000/api/student/${widget.studentId}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (mounted) {
        if (response.statusCode == 200) {
          setState(() { _studentData = jsonDecode(response.body); _isLoading = false; });
        } else {
          setState(() { _errorMessage = 'Failed to load details.'; _isLoading = false; });
        }
      }
    } catch (e) {
      if (mounted) setState(() { _errorMessage = 'Connection error.'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) return Text(_errorMessage!);
    if (_studentData == null) return const Text("No data found.");

    return SizedBox(
      width: double.maxFinite,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Email', _studentData!['email']),
            _buildDetailRow('Student Phone', _studentData!['student_phone']),
            _buildDetailRow('Parent Phone', _studentData!['parent_phone']),
            _buildDetailRow('Address', _studentData!['address']),
            _buildDetailRow('Registration Date', _studentData!['registration_date']),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(value ?? 'N/A', style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}