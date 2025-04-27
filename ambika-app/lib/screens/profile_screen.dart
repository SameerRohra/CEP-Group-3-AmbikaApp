import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E3B8C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("My Profile",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            )),
        actions: [
          TextButton(
            onPressed: () {},
            child: Text("DONE",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                )),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Card
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey[300],
                      child: const Icon(Icons.person, size: 30, color: Colors.grey),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Akshay Patil",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Class XI-B  |  Roll no: 04",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.camera_alt_outlined, color: Colors.grey),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Profile Details
              _buildProfileItem("Adhar No", "1234 4325 4567 1234"),
              _buildProfileItem("Academic Year", "2024-25"),
              _buildProfileItem("Admission Class", "VI"),
              _buildProfileItem("Old Admission No", "T00221", locked: true),
              _buildProfileItem("Date of Admission", "01 Apr 2018", locked: true),
              _buildProfileItem("Date of Birth", "22 July 2015", locked: true),
              _buildProfileItem("Parent Mail ID", "parentboth84@gmail.com", locked: true),
              _buildProfileItem("Mother Name", "Monica Larson", locked: true),
              _buildProfileItem("Father Name", "Bernard Taylor", locked: true),
              _buildProfileItem("Permanent Address", "Karol Bagh, Delhi", locked: true),
            ],
          ),
        ),
      ),
    );
  }

  // Profile Item Widget
  Widget _buildProfileItem(String title, String value, {bool locked = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (locked) const Icon(Icons.lock, color: Colors.grey),
        ],
      ),
    );
  }
}
