// File: lib/ClassOwner/manage_teachers_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Date formatting ke liye
import 'package:shared_preferences/shared_preferences.dart';

class ManageTeachersPage extends StatefulWidget {
  const ManageTeachersPage({super.key});

  @override
  State<ManageTeachersPage> createState() => _ManageTeachersPageState();
}

class _ManageTeachersPageState extends State<ManageTeachersPage> {
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
        Uri.parse('http://192.168.1.103:5001/api/teacher'),
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
      if (mounted) {
        setState(() { _errorMessage = 'Could not connect to server.'; _isLoading = false; });
      }
    }
  }

  void _filterTeachers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredTeachers = _allTeachers.where((teacher) {
        return teacher['full_name'].toLowerCase().contains(query) ||
            (teacher['subject'] != null && teacher['subject'].toLowerCase().contains(query));
      }).toList();
    });
  }

  Future<void> _deleteTeacher(String teacherId) async {
    final bool? confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this teacher?'),
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
          Uri.parse('http://192.168.1.103:5001/api/teacher/$teacherId'),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (mounted) {
          if (response.statusCode == 200) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Teacher deleted successfully!'), backgroundColor: Colors.green));
            _fetchTeachers();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete teacher.'), backgroundColor: Colors.red));
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not connect to server.'), backgroundColor: Colors.red));
        }
      }
    }
  }

  void _showTeacherDetailsDialog(String teacherId) {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text("Teacher Profile"),
      content: _TeacherDetailsDialogContent(teacherId: teacherId),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Close"))],
    ));
  }

  Future<void> _showEditTeacherDialog(Map<String, dynamic> teacherData) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Teacher Details'),
          content: _EditTeacherDialogContent(teacherData: teacherData),
          actions: <Widget>[
            TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop(false)),
          ],
        );
      },
    );
    if (result == true) _fetchTeachers();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(labelText: 'Search by name or subject...', prefixIcon: const Icon(Icons.search)),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : RefreshIndicator(
            onRefresh: _fetchTeachers,
            child: ListView.builder(
              itemCount: _filteredTeachers.length,
              itemBuilder: (context, index) {
                final teacher = _filteredTeachers[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: Colors.teal.shade100, child: Text(teacher['full_name'][0], style: const TextStyle(color: Colors.teal))),
                    title: Text(teacher['full_name']),
                    subtitle: Text('Subject: ${teacher['subject']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.visibility_outlined, color: Colors.blue), onPressed: () => _showTeacherDetailsDialog(teacher['id'])),
                        IconButton(icon: Icon(Icons.edit_outlined, color: Colors.grey.shade600), onPressed: () => _showEditTeacherDialog(teacher)),
                        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _deleteTeacher(teacher['id'])),
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

// Dialog content for VIEWING teacher details
class _TeacherDetailsDialogContent extends StatefulWidget {
  final String teacherId;
  const _TeacherDetailsDialogContent({required this.teacherId});

  @override
  State<_TeacherDetailsDialogContent> createState() => _TeacherDetailsDialogContentState();
}

class _TeacherDetailsDialogContentState extends State<_TeacherDetailsDialogContent> {
  bool _isLoading = true;
  Map<String, dynamic>? _teacherData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchTeacherDetails();
  }

  Future<void> _fetchTeacherDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('http://192.168.1.103:5001/api/teacher/${widget.teacherId}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (mounted) {
        if (response.statusCode == 200) {
          setState(() { _teacherData = jsonDecode(response.body); _isLoading = false; });
        } else {
          setState(() { _errorMessage = 'Failed to load details.'; _isLoading = false; });
        }
      }
    } catch(e) {
      if (mounted) setState(() { _errorMessage = 'Connection error.'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) return Text(_errorMessage!);
    if (_teacherData == null) return const Text("No data found.");

    // ============== DATE FORMATTING LOGIC ADDED HERE ==============
    String formattedDate = 'N/A';
    if (_teacherData!['joining_date'] != null) {
      try {
        final date = DateTime.parse(_teacherData!['joining_date']);
        formattedDate = DateFormat('dd MMM, yyyy').format(date);
      } catch (e) {
        formattedDate = _teacherData!['joining_date'];
      }
    }

    return SizedBox(
      width: double.maxFinite,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Email', _teacherData!['email']),
            _buildDetailRow('Phone', _teacherData!['phone_number']),
            _buildDetailRow('Subject', _teacherData!['subject']),
            _buildDetailRow('Qualification', _teacherData!['qualification']),
            _buildDetailRow('Address', _teacherData!['address']),
            _buildDetailRow('Assigned Classes', _teacherData!['assigned_classes']),
            _buildDetailRow('Joining Date', formattedDate),
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

// Dialog content for EDITING teacher details
class _EditTeacherDialogContent extends StatefulWidget {
  final Map<String, dynamic> teacherData;
  const _EditTeacherDialogContent({required this.teacherData});

  @override
  State<_EditTeacherDialogContent> createState() => _EditTeacherDialogContentState();
}

class _EditTeacherDialogContentState extends State<_EditTeacherDialogContent> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController, _subjectController, _phoneController, _qualificationController, _addressController, _assignedClassesController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.teacherData['full_name']);
    _subjectController = TextEditingController(text: widget.teacherData['subject']);
    _phoneController = TextEditingController(text: widget.teacherData['phone_number']);
    _qualificationController = TextEditingController(text: widget.teacherData['qualification']);
    _addressController = TextEditingController(text: widget.teacherData['address']);
    _assignedClassesController = TextEditingController(text: widget.teacherData['assigned_classes']);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subjectController.dispose();
    _phoneController.dispose();
    _qualificationController.dispose();
    _addressController.dispose();
    _assignedClassesController.dispose();
    super.dispose();
  }

  Future<void> _updateTeacher() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final teacherId = widget.teacherData['id'];
      final response = await http.put(
        Uri.parse('http://192.168.1.103:5001/api/teacher/$teacherId'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({
          'full_name': _nameController.text,
          'subject': _subjectController.text,
          'phone_number': _phoneController.text,
          'qualification': _qualificationController.text,
          'address': _addressController.text,
          'assigned_classes': _assignedClassesController.text,
        }),
      );
      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Teacher updated successfully!'), backgroundColor: Colors.green));
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update teacher.'), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not connect to server.'), backgroundColor: Colors.red));
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
            TextFormField(controller: _subjectController, decoration: const InputDecoration(labelText: "Subject")),
            const SizedBox(height: 16),
            TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: "Phone Number"), keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            TextFormField(controller: _qualificationController, decoration: const InputDecoration(labelText: "Qualification")),
            const SizedBox(height: 16),
            TextFormField(controller: _addressController, decoration: const InputDecoration(labelText: "Address")),
            const SizedBox(height: 16),
            TextFormField(controller: _assignedClassesController, decoration: const InputDecoration(labelText: "Assigned Classes")),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _updateTeacher,
              child: _isLoading ? const CircularProgressIndicator() : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}