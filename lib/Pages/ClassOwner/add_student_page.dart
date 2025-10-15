// File: lib/ClassOwner/add_student_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddStudentPage extends StatefulWidget {
  const AddStudentPage({super.key});

  @override
  State<AddStudentPage> createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _standardController = TextEditingController();
  final _studentPhoneController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _registrationDateController = TextEditingController();
  final _assignedClassController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _feesController = TextEditingController(); // 1. FEES CONTROLLER ADDED
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _standardController.dispose();
    _studentPhoneController.dispose();
    _parentPhoneController.dispose();
    _addressController.dispose();
    _registrationDateController.dispose();
    _assignedClassController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _feesController.dispose(); // 2. DISPOSE ADDED
    super.dispose();
  }

  Future<void> _addStudent() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.post(
        Uri.parse('https://coaching-api-backend.onrender.com/api/student/add'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'full_name': _nameController.text,
          'standard': _standardController.text,
          'student_phone': _studentPhoneController.text,
          'parent_phone': _parentPhoneController.text,
          'address': _addressController.text,
          'registration_date': _registrationDateController.text,
          'assigned_class': _assignedClassController.text,
          'email': _emailController.text,
          'password': _passwordController.text,
          'fees': double.tryParse(_feesController.text) ?? 0.0, // 3. FEES ADDED TO API CALL
        }),
      );

      if (mounted) {
        final responseData = jsonDecode(response.body);
        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseData['message']), backgroundColor: Colors.green));
          _formKey.currentState?.reset();
          _nameController.clear(); _standardController.clear(); _studentPhoneController.clear();
          _parentPhoneController.clear(); _addressController.clear(); _registrationDateController.clear();
          _assignedClassController.clear(); _emailController.clear(); _passwordController.clear();
          _feesController.clear(); // 4. CLEAR ADDED
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseData['message']), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not connect to the server.')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context, initialDate: DateTime.now(),
        firstDate: DateTime(2000), lastDate: DateTime(2101));
    if (picked != null) {
      setState(() {
        _registrationDateController.text = DateFormat('yyyy-MM-dd').format(picked);
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
                  Text('Enter Student Details', textAlign: TextAlign.center, style: GoogleFonts.lato(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 30),
                  TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)), validator: (v) => v!.isEmpty ? 'Please enter name' : null),
                  const SizedBox(height: 20),
                  TextFormField(controller: _standardController, decoration: const InputDecoration(labelText: 'Standard', prefixIcon: Icon(Icons.class_outlined)), validator: (v) => v!.isEmpty ? 'Please enter standard' : null),
                  const SizedBox(height: 20),

                  // 5. FEES TEXT FIELD ADDED
                  TextFormField(
                    controller: _feesController,
                    decoration: const InputDecoration(labelText: 'Total Fees', prefixIcon: Icon(Icons.currency_rupee)),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Please enter fees';
                      if (double.tryParse(v) == null) return 'Please enter a valid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  TextFormField(controller: _studentPhoneController, decoration: const InputDecoration(labelText: 'Student\'s Phone Number', prefixIcon: Icon(Icons.phone_android_outlined)), keyboardType: TextInputType.phone, validator: (v) => v!.length < 10 ? 'Enter a valid number' : null),
                  const SizedBox(height: 20),
                  TextFormField(controller: _parentPhoneController, decoration: const InputDecoration(labelText: 'Parent\'s Phone Number', prefixIcon: Icon(Icons.phone_outlined)), keyboardType: TextInputType.phone, validator: (v) => v!.length < 10 ? 'Enter a valid number' : null),
                  const SizedBox(height: 20),
                  TextFormField(controller: _addressController, decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on_outlined)), maxLines: 2, validator: (v) => v!.isEmpty ? 'Please enter address' : null),
                  const SizedBox(height: 20),
                  TextFormField(controller: _registrationDateController, decoration: const InputDecoration(labelText: 'Registration Date', prefixIcon: Icon(Icons.calendar_today_outlined)), readOnly: true, onTap: () => _selectDate(context), validator: (v) => v!.isEmpty ? 'Please select a date' : null),
                  const SizedBox(height: 20),
                  TextFormField(controller: _assignedClassController, decoration: const InputDecoration(labelText: 'Assign to Class', prefixIcon: Icon(Icons.assignment_ind_outlined))),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),
                  Text('Create Student Login', textAlign: TextAlign.center, style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'Student Email ID', prefixIcon: Icon(Icons.email_outlined)), keyboardType: TextInputType.emailAddress, validator: (v) => v == null || v.isEmpty || !v.contains('@') ? 'Enter a valid email' : null),
                  const SizedBox(height: 20),
                  TextFormField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Create Password', prefixIcon: Icon(Icons.lock_outline)), validator: (v) => v == null || v.length < 6 ? 'Password must be at least 6 characters' : null),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    onPressed: _isLoading ? null : _addStudent,
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Add Student', style: TextStyle(fontSize: 18)),
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