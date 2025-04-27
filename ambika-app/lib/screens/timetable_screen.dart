import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  _TimetableScreenState createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  // For API data - keeping the same API logic
  late Future<Map<String, dynamic>> _lectureData;
  late String apiKey;
  late String ambikaId;
  late String classId;
  
  bool isLoading = true;
  bool isError = false;
  String errorMessage = '';

  final String conn = "connect_2324";
  final String baseUrl = "http://127.0.0.1:3000";

  @override
  void initState() {
    super.initState();
    // Set default values
    apiKey = 'f1d16e0c-c37d-4495-b5b0-11d64e7ad3da';
    ambikaId = '961';
    classId = 'CS10BSBA';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null) {
      apiKey = args['apiKey'] ?? apiKey;
      ambikaId = args['ambikaId'] ?? ambikaId;
      classId = args['classId'] ?? classId;
    }
    _lectureData = _loadLectureData();
  }

  Future<Map<String, dynamic>> _loadLectureData() async {
    setState(() {
      isLoading = true;
      isError = false;
    });

    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
    };

    try {
      // Get lectures grouped by date
      final Uri groupedApiUrl = Uri.parse('$baseUrl/lectures/groupByDate/$conn/$classId/$ambikaId');
      final groupedResponse = await http.get(groupedApiUrl, headers: headers);

      if (groupedResponse.statusCode != 200) {
        throw Exception('Failed to load grouped lectures: ${groupedResponse.statusCode}');
      }

      // Get all lectures
      final Uri allLecturesUrl = Uri.parse('$baseUrl/lectures/all/$conn/$classId');
      final allLecturesResponse = await http.get(allLecturesUrl, headers: headers);

      if (allLecturesResponse.statusCode != 200) {
        throw Exception('Failed to load all lectures: ${allLecturesResponse.statusCode}');
      }

      setState(() {
        isLoading = false;
      });

      return {
        'groupedLectures': jsonDecode(groupedResponse.body),
        'allLectures': jsonDecode(allLecturesResponse.body),
      };
    } catch (e) {
      setState(() {
        isLoading = false;
        isError = true;
        errorMessage = e.toString();
      });
      throw Exception('Failed to load lecture data: $e');
    }
  }

  String _formatTimeDisplay(String time) {
    try {
      final timeParts = time.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      
      final period = hour >= 12 ? 'pm' : 'am';
      final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      
      return '$hour12:${minute.toString().padLeft(2, '0')}$period';
    } catch (e) {
      return time;
    }
  }

  // Get all lectures from the API response
  List<Map<String, dynamic>> _getAllLectures(Map<String, dynamic> data) {
    try {
      final allLectures = data['allLectures'];
      if (allLectures is List<dynamic>) {
        return List<Map<String, dynamic>>.from(allLectures);
      }
      
      final List<dynamic> groupedLectures = data['groupedLectures']['allLectures'] ?? [];
      final List<Map<String, dynamic>> lectures = [];
      
      for (var dateGroup in groupedLectures) {
        if (dateGroup['lectures'] is List) {
          lectures.addAll(List<Map<String, dynamic>>.from(dateGroup['lectures']));
        }
      }
      
      return lectures;
    } catch (e) {
      print('Error getting all lectures: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2F3B85),
        title: Text(
          "Class Timetable",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/dashboard');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {
                _lectureData = _loadLectureData();
              });
            },
          ),
        ],
        elevation: 0,
      ),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _lectureData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF2F3B85),
                ),
              );
            } else if (snapshot.hasError || isError) {
              return _buildErrorState();
            } else if (!snapshot.hasData) {
              return _buildEmptyState("No data available");
            } else {
              final allLectures = _getAllLectures(snapshot.data!);
              
              if (allLectures.isEmpty) {
                return _buildEmptyState("No lectures available");
              }
              
              return _buildLectureView(allLectures);
            }
          },
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Failed to load timetable",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _lectureData = _loadLectureData();
              });
            },
            icon: const Icon(Icons.refresh),
            label: Text(
              "Retry",
              style: GoogleFonts.poppins(),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2F3B85),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_busy,
              size: 40,
              color: Colors.blue.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLectureView(List<Map<String, dynamic>> lectures) {
    // Group lectures by date
    Map<String, List<Map<String, dynamic>>> groupedByDate = {};
    
    // Sort lectures by date first, then by time
    lectures.sort((a, b) {
      // First compare by date
      final dateComparison = (a['Lecture_Date'] ?? '').compareTo(b['Lecture_Date'] ?? '');
      if (dateComparison != 0) return dateComparison;
      
      // If same date, compare by time
      return (a['Time_IN'] ?? '').compareTo(b['Time_IN'] ?? '');
    });
    
    // Group by date
    for (var lecture in lectures) {
      final date = lecture['Lecture_Date'] ?? '';
      if (!groupedByDate.containsKey(date)) {
        groupedByDate[date] = [];
      }
      groupedByDate[date]!.add(lecture);
    }
    
    // Sort dates
    final sortedDates = groupedByDate.keys.toList()..sort();
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final lecturesForDate = groupedByDate[date]!;
        
        // Format date for display
        String formattedDate = "";
        try {
          final parsedDate = DateFormat('yyyy-MM-dd').parse(date);
          formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(parsedDate);
        } catch (e) {
          formattedDate = date;
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 8, bottom: 16),
              child: Text(
                formattedDate,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2F3B85),
                ),
              ),
            ),
            
            // Lectures for this date
            ...lecturesForDate.map((lecture) => _buildLectureCard(lecture)).toList(),
            
            // Add some space between date groups
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildLectureCard(Map<String, dynamic> lecture) {
    // Extract lecture details
    final subject = lecture['Subject'] ?? "Unknown Subject";
    final timeIn = _formatTimeDisplay(lecture['Time_IN'] ?? "");
    final timeOut = _formatTimeDisplay(lecture['Time_OUT'] ?? "");
    final timeRange = "$timeIn - $timeOut";
    final teacher = lecture['Teacher'] ?? "Unknown Teacher";
    final roomNo = lecture['Room_No'] ?? "Unknown Room";
    final lectureType = lecture['Lecture_Type'] ?? "Regular";
    final schoolName = lecture['School_Name'] ?? "";
    final notes = lecture['Notes'] ?? "";
    
    // Set colors based on lecture type
    Color accentColor;
    IconData typeIcon;
    
    switch (lectureType.toLowerCase()) {
      case 'exam':
        accentColor = Colors.red.shade700;
        typeIcon = Icons.assignment;
        break;
      case 'revision':
        accentColor = Colors.orange.shade700;
        typeIcon = Icons.autorenew;
        break;
      default:
        accentColor = const Color(0xFF2F3B85);
        typeIcon = Icons.menu_book;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left color bar for lecture type
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
              ),
            ),
            
            // Main content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with subject and time
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            subject,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                typeIcon,
                                size: 14,
                                color: accentColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                lectureType,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: accentColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Time range in a row
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          timeRange,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 6),
                    
                    // Teacher and room
                    Row(
                      children: [
                        // Teacher
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.person,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  teacher,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Room
                        Row(
                          children: [
                            const Icon(
                              Icons.room,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Room $roomNo",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    // School name if present
                    if (schoolName.isNotEmpty && schoolName != "ALL") ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.school,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              schoolName,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    // Notes if present
                    if (notes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.notes,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                notes,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}