import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ------------------- Naya Page: Student ka Profile (Redesigned) -------------------
class MyProfilePage extends StatelessWidget {
  const MyProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Abhi ke liye dummy data
    const String studentName = "Aarav Mehta";
    const String standard = "12th Science";
    const String email = "aarav.mehta@email.com";
    const String studentPhone = "9123456789";
    const String parentPhone = "9988776655";
    const String address = "456, XYZ Society, Pune";

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade200,
            Colors.green.shade50,
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Naya profile header
                _buildProfileHeader(studentName, standard),
                // Header aur cards ke beech me sahi gap ke liye SizedBox
                const SizedBox(height: 120),
                // Profile details section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      _buildProfileDetailCard(
                        icon: Icons.email_outlined,
                        title: 'Email ID',
                        value: email,
                        color: Colors.redAccent,
                      ),
                      _buildProfileDetailCard(
                        icon: Icons.phone_android_outlined,
                        title: 'My Phone Number',
                        value: studentPhone,
                        color: Colors.blueAccent,
                      ),
                      _buildProfileDetailCard(
                        icon: Icons.phone_outlined,
                        title: 'Parent\'s Phone Number',
                        value: parentPhone,
                        color: Colors.orangeAccent,
                      ),
                      _buildProfileDetailCard(
                        icon: Icons.location_on_outlined,
                        title: 'Address',
                        value: address,
                        color: Colors.purpleAccent,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80), // Nav bar ke liye jagah
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Naya header design
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
              Text(
                name,
                style: GoogleFonts.lato(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Standard: $standard',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Naya detail card design (Gap kam kar diya hai)
  Widget _buildProfileDetailCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      // Yahan margin theek kar diya hai taaki extra gap na aaye
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
                  Text(
                    title,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

