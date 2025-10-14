// File: lib/Pages/Student/my_profile_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// BADLAV 1: Widget ab StatefulWidget hai
class MyProfilePage extends StatefulWidget {
  const MyProfilePage({super.key});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  bool _isLoading = true;
  String? _errorMessage;
  // BADLAV 2: Dummy data ki jagah Map<String, dynamic>
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  // BADLAV 3: API se profile data fetch karne ka function
  Future<void> _fetchProfileData() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        if (mounted) setState(() { _errorMessage = 'Not logged in.'; _isLoading = false; });
        return;
      }

      final response = await http.get(
        Uri.parse('https://coaching-api-backend.onrender.com:10000/api/student/profile/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (mounted) {
        if (response.statusCode == 200) {
          setState(() {
            _profileData = jsonDecode(response.body);
            _isLoading = false;
          });
        } else {
          setState(() { _errorMessage = 'Failed to load profile. Status: ${response.statusCode}'; _isLoading = false; });
        }
      }
    } catch (e) {
      if (mounted) setState(() { _errorMessage = 'Could not connect to server: ${e.toString()}'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade200, Colors.green.shade50, Colors.white],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          // BADLAV 4: build() method ab loading/error handle karta hai
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : RefreshIndicator(
            onRefresh: _fetchProfileData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildProfileHeader(
                    _profileData?['full_name'] ?? 'Student Name',
                    _profileData?['standard'] ?? 'Standard',
                  ),
                  const SizedBox(height: 120),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      children: [
                        _buildProfileDetailCard(icon: Icons.email_outlined, title: 'Email ID', value: _profileData?['email'] ?? 'N/A', color: Colors.redAccent),
                        _buildProfileDetailCard(icon: Icons.phone_android_outlined, title: 'My Phone Number', value: _profileData?['student_phone'] ?? 'N/A', color: Colors.blueAccent),
                        _buildProfileDetailCard(icon: Icons.phone_outlined, title: 'Parent\'s Phone Number', value: _profileData?['parent_phone'] ?? 'N/A', color: Colors.orangeAccent),
                        _buildProfileDetailCard(icon: Icons.location_on_outlined, title: 'Address', value: _profileData?['address'] ?? 'N/A', color: Colors.purpleAccent),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(String name, String standard) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.green.shade400,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
        ),
        Positioned(
          top: 80,
          child: Column(
            children: [
              const CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.green,
                  child: Icon(Icons.person, size: 70, color: Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              Text(name, style: GoogleFonts.lato(fontSize: 24, fontWeight: FontWeight.bold)),
              Text('Standard: $standard', style: const TextStyle(fontSize: 16, color: Colors.black54)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileDetailCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}