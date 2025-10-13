// File: lib/ClassOwner/profile_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ProfilePage ab data fetch karne ke liye ek StatefulWidget hai
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Page khulte hi API se details fetch ki jaayengi
    _fetchProfileDetails();
  }

  // API se profile details laane ka function
  Future<void> _fetchProfileDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        if (mounted) setState(() { _errorMessage = 'Authentication token not found.'; _isLoading = false; });
        return;
      }
      final response = await http.get(
        Uri.parse('http://192.168.1.103:5001/api/institute/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (mounted) {
        if (response.statusCode == 200) {
          setState(() {
            _profileData = jsonDecode(response.body);
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Failed to load profile data.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not connect to the server.';
          _isLoading = false;
        });
      }
    }
  }

  // Edit profile ka pop-up dialog dikhane ka function
  Future<void> _showEditProfileDialog() async {
    if (_profileData == null) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: _EditProfileDialogContent(initialData: _profileData!),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        );
      },
    );

    // Agar update safal hua, to details dobara fetch karein
    if (result == true) {
      _fetchProfileDetails();
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                const CircleAvatar(radius: 60, backgroundColor: Colors.white, child: Icon(Icons.school_rounded, size: 70, color: Colors.lightBlue)),
                const SizedBox(height: 16),
                Text(_profileData?['institute_name'] ?? 'Loading...', style: GoogleFonts.lato(fontSize: 26, fontWeight: FontWeight.bold)),
                Text('Owned by: ${_profileData?['owner_name'] ?? '...'}', style: const TextStyle(fontSize: 16, color: Colors.black54)),
                const SizedBox(height: 30),
                const Divider(),
                _buildProfileDetailItem(icon: Icons.email_outlined, title: 'Contact Email', value: _profileData?['owner_email'] ?? '...'),
                _buildProfileDetailItem(icon: Icons.phone_outlined, title: 'Contact Phone', value: _profileData?['phone_number'] ?? '...'),
                _buildProfileDetailItem(icon: Icons.location_on_outlined, title: 'Address', value: _profileData?['address'] ?? '...'),
                _buildProfileDetailItem(icon: Icons.calendar_today_outlined, title: 'Established In', value: _profileData?['establishment_year'].toString() ?? '...'),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white),
                  onPressed: _showEditProfileDialog,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit Profile', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileDetailItem({required IconData icon, required String title, required String value}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.lightBlue),
        title: Text(title, style: const TextStyle(color: Colors.grey)),
        subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
      ),
    );
  }
}


// Edit form ka logic is alag widget mein hai taaki state manage karna aasan ho
class _EditProfileDialogContent extends StatefulWidget {
  final Map<String, dynamic> initialData;
  const _EditProfileDialogContent({required this.initialData});

  @override
  State<_EditProfileDialogContent> createState() => __EditProfileDialogContentState();
}

class __EditProfileDialogContentState extends State<_EditProfileDialogContent> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController, _classNameController, _standardsRangeController, _establishmentYearController, _addressController, _phoneController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialData['owner_name']);
    _classNameController = TextEditingController(text: widget.initialData['institute_name']);
    _standardsRangeController = TextEditingController(text: widget.initialData['standards_range']);
    _establishmentYearController = TextEditingController(text: widget.initialData['establishment_year'].toString());
    _addressController = TextEditingController(text: widget.initialData['address']);
    _phoneController = TextEditingController(text: widget.initialData['phone_number']);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _classNameController.dispose();
    _standardsRangeController.dispose();
    _establishmentYearController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    try {
      final response = await http.put(
        Uri.parse('http://192.168.1.103:5001/api/institute/profile'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({
          'owner_name': _nameController.text,
          'institute_name': _classNameController.text,
          'standards_range': _standardsRangeController.text,
          'establishment_year': int.parse(_establishmentYearController.text),
          'address': _addressController.text,
          'phone_number': _phoneController.text,
        }),
      );
      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green));
          Navigator.pop(context, true); // Dialog band karein aur refresh ka signal dein
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(jsonDecode(response.body)['message']), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not connect to server.'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Owner\'s Full Name')),
            const SizedBox(height: 16),
            TextFormField(controller: _classNameController, decoration: const InputDecoration(labelText: 'Class Name')),
            const SizedBox(height: 16),
            TextFormField(controller: _standardsRangeController, decoration: const InputDecoration(labelText: 'Standards Range')),
            const SizedBox(height: 16),
            TextFormField(controller: _establishmentYearController, decoration: const InputDecoration(labelText: 'Establishment Year'), keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            TextFormField(controller: _addressController, decoration: const InputDecoration(labelText: 'Full Address')),
            const SizedBox(height: 16),
            TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Contact Phone Number'), keyboardType: TextInputType.phone),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _updateProfile,
              child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 3)) : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}