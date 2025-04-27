import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:percent_indicator/percent_indicator.dart';

class ExamsScreen extends StatefulWidget {
  const ExamsScreen({super.key});

  @override
  _ExamsScreenState createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen> {
  late Future<Map<String, dynamic>> _examsData;
  late Future<Map<String, dynamic>> _summaryData;

  late String apiKey;
  late String ambikaId;

  final String conn = "connect_2324";
  final String baseUrl = "http://127.0.0.1:3000";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    apiKey = args?['apiKey'] ?? 'f1d16e0c-c37d-4495-b5b0-11d64e7ad3da';
    ambikaId = args?['ambikaId'] ?? '961';

    _examsData = _loadExamsData();
    _summaryData = _loadSummaryData();
  }

  Future<Map<String, dynamic>> _loadExamsData() async {
    final Uri apiUrl = Uri.parse('$baseUrl/exams/course/$conn/CS10BSBA');
    final headers = {
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
    };

    final response = await http.get(apiUrl, headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load exams data');
    }
  }

  Future<Map<String, dynamic>> _loadSummaryData() async {
    final Uri apiUrl = Uri.parse('$baseUrl/exams/summary/$conn/$ambikaId');
    final headers = {
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
    };

    final response = await http.get(apiUrl, headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load summary data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E3B8C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/dashboard');
          },
        ),
        title: Text(
          "Exams Performance",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {
                _examsData = _loadExamsData();
                _summaryData = _loadSummaryData();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: Future.wait([_examsData, _summaryData]).then((responses) => {
              'exams': responses[0]['exams'],
              'summary': responses[1]['allData'],
            }),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2E3B8C),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Error loading data",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${snapshot.error}",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _examsData = _loadExamsData();
                        _summaryData = _loadSummaryData();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E3B8C),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      "Retry",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            final data = snapshot.data!;
            final exams = data['exams'] as List<dynamic>;
            final summary = data['summary'] as Map<String, dynamic>;
            return _buildExamsBody(exams, summary);
          }
        },
      ),
    );
  }

  Widget _buildExamsBody(List<dynamic> exams, Map<String, dynamic> summary) {
    final overallSummary = summary['overallSummary'];
    final typeWiseSummary = summary['typeWiseSummary'] as List<dynamic>;
    
    // Calculate percentage for progress indicator
    double percentage = 0.0;
    if (overallSummary['percentage'] != null) {
      percentage = overallSummary['percentage'] / 100;
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with performance summary
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF2E3B8C),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircularPercentIndicator(
                  radius: 70.0,
                  lineWidth: 13.0,
                  animation: true,
                  percent: percentage,
                  center: Text(
                    "${overallSummary['percentage'] ?? 0}%",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: Colors.white,
                    ),
                  ),
                  circularStrokeCap: CircularStrokeCap.round,
                  progressColor: _getProgressColor(overallSummary['percentage'] ?? 0),
                  backgroundColor: Colors.white.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  "Overall Performance",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSummaryItem(
                      "Total Tests",
                      "${overallSummary['noOfTests']}",
                      Icons.assignment,
                    ),
                    _buildSummaryItem(
                      "Marks Obtained",
                      "${overallSummary['marksObtained']}/${overallSummary['totalMarks']}",
                      Icons.grade,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Type-wise Summary Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader("Type-Wise Performance"),
                const SizedBox(height: 12),
                
                typeWiseSummary.isEmpty
                    ? _buildEmptyState("No type-wise data available")
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: typeWiseSummary.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = typeWiseSummary[index];
                          double typePercentage = 0.0;
                          if (item['percentage'] != null) {
                            typePercentage = item['percentage'] / 100;
                          }
                          
                          return Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "${item['type']}",
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF2E3B8C),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getProgressColor(item['percentage']).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          "${item['percentage']}%",
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: _getProgressColor(item['percentage']),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  LinearPercentIndicator(
                                    animation: true,
                                    lineHeight: 8.0,
                                    animationDuration: 1500,
                                    percent: typePercentage,
                                    backgroundColor: Colors.grey.withOpacity(0.2),
                                    progressColor: _getProgressColor(item['percentage']),
                                    barRadius: const Radius.circular(4),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Marks: ${item['marksObtained']}/${item['totalMarks']}",
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      
                // Exams List Section
                const SizedBox(height: 24),
                _buildSectionHeader("Exam Details"),
                const SizedBox(height: 12),
                
                exams.isEmpty
                    ? _buildEmptyState("No exams data available")
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: exams.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final exam = exams[index];
                          return Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: _getSubjectColor(exam['Subject']).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            _getSubjectIcon(exam['Subject']),
                                            color: _getSubjectColor(exam['Subject']),
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "${exam['Subject']}",
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              "Type: ${exam['Type']}",
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2E3B8C).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          "${exam['Total_Marks']} marks",
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFF2E3B8C),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildExamInfoItem(
                                          "Date",
                                          "${exam['Date']}",
                                          Icons.calendar_today,
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildExamInfoItem(
                                          "Supervisor",
                                          "${exam['Supervisor']}",
                                          Icons.person,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  _buildExamInfoItem(
                                    "Examiner",
                                    "${exam['Examiner']}",
                                    Icons.school,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFF2E3B8C),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 40,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getProgressColor(dynamic percentage) {
    if (percentage == null) return Colors.grey;
    
    double percent = percentage is int ? percentage.toDouble() : percentage;
    
    if (percent < 40) {
      return Colors.red;
    } else if (percent < 60) {
      return Colors.orange;
    } else if (percent < 75) {
      return Colors.amber[700]!;
    } else {
      return Colors.green;
    }
  }

  IconData _getSubjectIcon(String subject) {
    // This can be expanded with more subject mappings
    final subjectLower = subject.toLowerCase();
    if (subjectLower.contains('math')) return Icons.calculate;
    if (subjectLower.contains('science')) return Icons.science;
    if (subjectLower.contains('english')) return Icons.language;
    if (subjectLower.contains('history')) return Icons.history_edu;
    if (subjectLower.contains('computer')) return Icons.computer;
    return Icons.book;
  }

  Color _getSubjectColor(String subject) {
    // This can be expanded with more subject mappings
    final subjectLower = subject.toLowerCase();
    if (subjectLower.contains('math')) return Colors.blue;
    if (subjectLower.contains('science')) return Colors.green;
    if (subjectLower.contains('english')) return Colors.purple;
    if (subjectLower.contains('history')) return Colors.brown;
    if (subjectLower.contains('computer')) return Colors.teal;
    return const Color(0xFF2E3B8C);
  }
}