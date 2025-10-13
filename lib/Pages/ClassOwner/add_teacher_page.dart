// File: lib/ClassOwner/add_teacher_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddTeacherPage extends StatefulWidget {
  const AddTeacherPage({super.key});

  @override
  State<AddTeacherPage> createState() => _AddTeacherPageState();
}

class _AddTeacherPageState extends State<AddTeacherPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _assignedClassesController = TextEditingController();
  final _subjectController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _joiningDateController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _assignedClassesController.dispose();
    _subjectController.dispose();
    _qualificationController.dispose();
    _joiningDateController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // ============== API CALL LOGIC YAHAN HAI ==============
  Future<void> _addTeacher() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('http://192.168.1.103:5001/api/teacher/add'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'full_name': _nameController.text,
          'email': _emailController.text,
          'password': _passwordController.text,
          'phone_number': _phoneController.text,
          'subject': _subjectController.text,
          'qualification': _qualificationController.text,
          'joining_date': _joiningDateController.text,
          'address': _addressController.text,
          'assigned_classes': _assignedClassesController.text,
        }),
      );
      if (mounted) {
        final responseData = jsonDecode(response.body);
        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['message']), backgroundColor: Colors.green),
          );
          _formKey.currentState?.reset();
          _nameController.clear(); _emailController.clear(); _passwordController.clear();
          _phoneController.clear(); _subjectController.clear(); _qualificationController.clear();
          _joiningDateController.clear(); _addressController.clear(); _assignedClassesController.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['message']), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not connect to the server.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        // Database ke liye sahi format (yyyy-MM-dd)
        _joiningDateController.text = DateFormat('yyyy-MM-dd').format(picked);
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text('Enter Teacher Details', textAlign: TextAlign.center, style: GoogleFonts.lato(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 30),
                  TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)), validator: (v) => v!.isEmpty ? 'Please enter name' : null),
                  const SizedBox(height: 20),
                  TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email ID (for login)', prefixIcon: Icon(Icons.email_outlined)), keyboardType: TextInputType.emailAddress, validator: (v) => v!.isEmpty || !v.contains('@') ? 'Please enter a valid email' : null),
                  const SizedBox(height: 20),
                  TextFormField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Create Temporary Password', prefixIcon: Icon(Icons.lock_outline)), validator: (v) => v!.length < 6 ? 'Password must be at least 6 characters' : null),
                  const SizedBox(height: 20),
                  TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Contact Phone Number', prefixIcon: Icon(Icons.phone_outlined)), keyboardType: TextInputType.phone, validator: (v) => v!.length < 10 ? 'Please enter a valid 10-digit number' : null),
                  const SizedBox(height: 20),
                  TextFormField(controller: _subjectController, decoration: const InputDecoration(labelText: 'Main Subject', prefixIcon: Icon(Icons.book_outlined)), validator: (v) => v!.isEmpty ? 'Please enter subject' : null),
                  const SizedBox(height: 20),
                  TextFormField(controller: _qualificationController, decoration: const InputDecoration(labelText: 'Qualification', prefixIcon: Icon(Icons.school_outlined)), validator: (v) => v!.isEmpty ? 'Please enter qualification' : null),
                  const SizedBox(height: 20),
                  TextFormField(controller: _joiningDateController, decoration: const InputDecoration(labelText: 'Joining Date', prefixIcon: Icon(Icons.calendar_today_outlined)), readOnly: true, onTap: () => _selectDate(context), validator: (v) => v!.isEmpty ? 'Please select a date' : null),
                  const SizedBox(height: 20),
                  TextFormField(controller: _addressController, decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on_outlined)), maxLines: 2, validator: (v) => v!.isEmpty ? 'Please enter address' : null),
                  const SizedBox(height: 20),
                  TextFormField(controller: _assignedClassesController, decoration: const InputDecoration(labelText: 'Assign Classes (comma separated)', prefixIcon: Icon(Icons.class_outlined)), validator: (v) => v!.isEmpty ? 'Please assign at least one class' : null),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: _isLoading ? null : _addTeacher,
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Add Teacher', style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}