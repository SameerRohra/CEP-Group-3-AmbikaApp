import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:animate_do/animate_do.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<Map<String, dynamic>> _dashboardData;

  late String apiKey;
  late String ambikaId;

  final String conn = "connect_2324";
  final String baseUrl = "http://127.0.0.1:3000";
  
  // Color scheme for the app
  final Color primaryColor = const Color(0xFF2E3B8C);
  final Color accentColor = const Color(0xFF5E72E4);
  final Color secondaryColor = const Color(0xFFF7FAFC);
  final Color textDarkColor = const Color(0xFF1A202C);
  final Color textLightColor = const Color(0xFF718096);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    apiKey = args?['apiKey'] ?? '';
    ambikaId = args?['ambikaId'] ?? '961';
    _dashboardData = fetchDashboardData();
  }

  Future<Map<String, dynamic>> fetchDashboardData() async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
    };

    final studentRes = await http.get(
      Uri.parse('$baseUrl/signin/getStudentData/$conn/$ambikaId'),
      headers: headers,
    );

    final attendanceRes = await http.get(
      Uri.parse('$baseUrl/attendance/student/$conn/$ambikaId'),
      headers: headers,
    );

    final feesRes = await http.get(
      Uri.parse('$baseUrl/fees/get/$conn/$ambikaId'),
      headers: headers,
    );

    if (studentRes.statusCode == 200 &&
        attendanceRes.statusCode == 200 &&
        feesRes.statusCode == 200) {
      return {
        'student': jsonDecode(studentRes.body),
        'attendance': jsonDecode(attendanceRes.body),
        'fees': jsonDecode(feesRes.body),
      };
    } else {
      throw Exception('Failed to load dashboard data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondaryColor,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E3B8C)),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Loading your dashboard...",
                    style: GoogleFonts.poppins(
                      color: textLightColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red[400], size: 60),
                  const SizedBox(height: 16),
                  Text(
                    "Oops! Something went wrong",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: textDarkColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Please try again later",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: textLightColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _dashboardData = fetchDashboardData();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Retry",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            );
          } else {
            final data = snapshot.data!;
            final student = data['student'];
            final attendance = data['attendance'];
            final fees = data['fees'];
            
            final attendancePercent = double.parse(
              attendance['absence_summary']['overall_presence'].toString()
            ) / 100;
            
            final dueAmount = fees['allFeeData']['summary']['total_payable'] ?? 0;

            return SafeArea(
              child: CustomScrollView(
                slivers: [
                  // Profile Header
                  SliverToBoxAdapter(
                    child: FadeInDown(
                      duration: const Duration(milliseconds: 600),
                      child: _buildProfileHeader(student),
                    ),
                  ),
                  
                  // Stats Cards
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 200),
                        child: _buildStatsCards(attendancePercent, dueAmount),
                      ),
                    ),
                  ),
                  
                  // Section Title - Quick Actions
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: FadeInLeft(
                        duration: const Duration(milliseconds: 400),
                        delay: const Duration(milliseconds: 300),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 20,
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Quick Actions",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: textDarkColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Grid Menu
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.9,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      delegate: SliverChildListDelegate(
                        [
                          _buildMenuCard(context, "Attendance", Icons.event_available, '/attendance', 0),
                          _buildMenuCard(context, "Fees Due", Icons.account_balance_wallet, '/fees_due', 150),
                          _buildMenuCard(context, "Exams & Results", Icons.assignment, '/result', 300),
                          _buildMenuCard(context, "Lectures", Icons.schedule, '/timetable', 450),
                          _buildMenuCard(context, "Feedback", Icons.feedback, '/feedback', 600),
                          _buildMenuCard(context, "Logout", Icons.logout, '/login', 750),
                        ],
                      ),
                    ),
                  ),
                  
                  // Bottom padding
                  SliverToBoxAdapter(
                    child: const SizedBox(height: 24),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildProfileHeader(dynamic student) {
    final studentName = student['studentData']['Name'] ?? "Student Name";
    final courseName = student['studentData']['Course_Name'] ?? "Course";
    final rollNo = student['studentData']['Roll_No'] ?? "Roll No";
    
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, primaryColor.withOpacity(0.8)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      "Dashboard",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Notification icon removed from here
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey[200],
                  child: Text(
                    studentName.split(' ').length > 1
                        ? "${studentName.split(' ')[0][0]}${studentName.split(' ')[1][0]}"
                        : studentName[0],
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentName,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      courseName,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Roll No: $rollNo",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(double attendancePercent, num dueAmount) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              "Attendance",
              "${(attendancePercent * 100).toStringAsFixed(0)}%",
              "Your overall presence in classes",
              attendancePercent,
              Colors.green,
              Icons.timeline,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              "Fees Due",
              "₹${dueAmount.toStringAsFixed(0)}",
              "Payment pending",
              dueAmount > 0 ? 1.0 : 0.0,
              Colors.orange,
              Icons.account_balance_wallet,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, double percent, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: textLightColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircularPercentIndicator(
                radius: 25,
                lineWidth: 5.0,
                percent: percent,
                center: Text(
                  title == "Attendance" ? "${(percent * 100).toInt()}%" : "",
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: textDarkColor,
                  ),
                ),
                progressColor: color,
                backgroundColor: Colors.grey.withOpacity(0.2),
                circularStrokeCap: CircularStrokeCap.round,
                animation: true,
                animationDuration: 1200,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textDarkColor,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: textLightColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, IconData icon, String route, int delay) {
    final Map<String, Color> iconColors = {
      'Attendance': Colors.green,
      'Fees Due': Colors.orange,
      'Exams & Results': Colors.purple,
      'Lectures': Colors.blue,
      'Feedback': Colors.amber,
      'Logout': Colors.red,
    };

    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      delay: Duration(milliseconds: delay),
      child: GestureDetector(
        onTap: () {
          if (title == "Logout") {
            Navigator.pushReplacementNamed(context, route);
          } else {
            Navigator.pushReplacementNamed(context, route, arguments: {
              'ambikaId': ambikaId,
              'apiKey': apiKey
            });
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColors[title]?.withOpacity(0.1) ?? Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColors[title] ?? Colors.blue,
                  size: 26,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textDarkColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}