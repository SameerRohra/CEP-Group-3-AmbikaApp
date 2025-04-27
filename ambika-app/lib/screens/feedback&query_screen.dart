import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

class FQC {
  final int id;
  final int ambikaId;
  final String title;
  final String type;
  final String date;
  final String description;
  final String resolution;
  final int statusCode;
  final String statusText;

  FQC({
    required this.id,
    required this.ambikaId,
    required this.title,
    required this.type,
    required this.date,
    required this.description,
    required this.resolution,
    required this.statusCode,
    required this.statusText,
  });

  factory FQC.fromJson(Map<String, dynamic> json) {
    return FQC(
      id: json['ID'],
      ambikaId: json['Ambika_ID'],
      title: json['FQCTitle'] ?? '',
      type: json['FQCType'] ?? '',
      date: json['FQCDate'] ?? '',
      description: json['FQCDescription'] ?? '',
      resolution: json['FQCResolution'] ?? '',
      statusCode: json['FQCStatus'] ?? 0,
      statusText: json['FQCStatusText'] ?? '',
    );
  }
}

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  _FeedbackPageState createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> with TickerProviderStateMixin {
  String? selectedStatus;
  String? selectedType;
  List<FQC> fqcList = [];
  bool isLoading = true;
  String? error;
  late String apiKey;
  late int ambikaid;
  late TabController _tabController;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedType = 'Query'; // Default type

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    apiKey = args?['apiKey'] ?? 'f1d16e0c-c37d-4495-b5b0-11d64e7ad3da';
    ambikaid = args?['ambikaid'] ?? 961;
    fetchFQCData();
  }

  Future<void> fetchFQCData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      const baseUrl = 'http://127.0.0.1:3000';
      final response = await http.get(
        Uri.parse('$baseUrl/fqc/all/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data.containsKey('fqc')) {
          final List<dynamic> fqcs = data['fqc'];
          setState(() {
            fqcList = fqcs.map((json) => FQC.fromJson(json)).toList();
            isLoading = false;
          });
        } else {
          setState(() {
            error = 'Unexpected JSON structure';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          error = 'Server error: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Network error: $e';
        isLoading = false;
      });
    }
  }

  Future<void> submitFQC() async {
    const baseUrl = 'http://127.0.0.1:3000';
    final body = {
      "ambikaid": ambikaid,
      "date": DateTime.now().toIso8601String().split('T')[0],
      "title": _titleController.text,
      "description": _descriptionController.text,
      "type": _selectedType,
    };

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/fqc/add'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'x-api-key': apiKey,
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['addition'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'])),
          );
          _titleController.clear();
          _descriptionController.clear();
          fetchFQCData(); // Refresh the list
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to submit')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e')),
      );
    }
  }

  List<FQC> getFilteredFQCs() {
    return fqcList.where((fqc) {
      bool statusMatch = selectedStatus == null || fqc.statusText == selectedStatus;
      bool typeMatch = selectedType == null || fqc.type == selectedType;
      return statusMatch && typeMatch;
    }).toList();
  }

  String formatDate(String dateStr) {
    try {
      // Parse the date string
      final parsedDate = DateTime.parse(dateStr);
      // Format it
      return DateFormat('MMM dd, yyyy').format(parsedDate);
    } catch (e) {
      return dateStr; // Return original if parsing fails
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredFQCs = getFilteredFQCs();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF2E3B8C),
        title: Text(
          "Feedback & Queries",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/dashboard');
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF2E3B8C),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.amber,
              indicatorWeight: 4,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w400,
                fontSize: 15,
              ),
              tabs: const [
                Tab(text: "My Requests"),
                Tab(text: "New Request"),
              ],
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: fetchFQCData,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // First Tab: Listing with Filters
          _buildListingTab(filteredFQCs),
          
          // Second Tab: New Request Form
          _buildNewRequestTab(),
        ],
      ),
    );
  }

  Widget _buildListingTab(List<FQC> filteredFQCs) {
    return Column(
      children: [
        FadeInDown(
          duration: const Duration(milliseconds: 500),
          child: Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filters',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF2E3B8C),
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedStatus,
                            hint: Text('Status', style: GoogleFonts.poppins()),
                            isExpanded: true,
                            items: [null, 'Pending', 'In Progress', 'Closed']
                                .map((status) => DropdownMenuItem(
                                      value: status,
                                      child: Text(status ?? 'All Statuses', style: GoogleFonts.poppins()),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedStatus = value;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedType,
                            hint: Text('Type', style: GoogleFonts.poppins()),
                            isExpanded: true,
                            items: [null, 'Query', 'Feedback', 'Complaint']
                                .map((type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(type ?? 'All Types', style: GoogleFonts.poppins()),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedType = value;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF2E3B8C),
                  ),
                )
              : error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 60,
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Error loading data",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            error!,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    )
                  : filteredFQCs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.question_answer,
                                size: 80,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                "No requests found",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 20),
                          itemCount: filteredFQCs.length,
                          itemBuilder: (context, index) {
                            final fqc = filteredFQCs[index];
                            return FadeInUp(
                              duration: Duration(milliseconds: 300 + (index * 50)),
                              delay: Duration(milliseconds: 100 * index),
                              child: _buildFQCCard(fqc),
                            );
                          },
                        ),
        ),
      ],
    );
  }

  Widget _buildNewRequestTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FadeInUp(
          duration: const Duration(milliseconds: 500),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Submit New Request",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E3B8C),
                ),
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Request Type",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedType,
                          isExpanded: true,
                          items: ['Query', 'Feedback', 'Complaint']
                              .map((type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(type, style: GoogleFonts.poppins()),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedType = value!;
                            });
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Title",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: _titleController,
                      style: GoogleFonts.poppins(),
                      decoration: InputDecoration(
                        hintText: "Enter a title for your request",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Color(0xFF2E3B8C), width: 2),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Description",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: _descriptionController,
                      style: GoogleFonts.poppins(),
                      decoration: InputDecoration(
                        hintText: "Describe your issue or feedback in detail",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Color(0xFF2E3B8C), width: 2),
                        ),
                        contentPadding: EdgeInsets.all(16),
                      ),
                      maxLines: 5,
                    ),
                    SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Please fill in all fields"),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } else {
                            submitFQC();
                          }
                        },
                        child: Text(
                          "Submit Request",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF2E3B8C),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFQCCard(FQC fqc) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        collapsedBackgroundColor: Colors.white,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: EdgeInsets.all(16),
        title: Text(
          fqc.title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Color(0xFF2E3B8C),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 6),
            Row(
              children: [
                _buildStatusChip(fqc.statusText),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    fqc.type,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                Spacer(),
                Text(
                  formatDate(fqc.date),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Divider(color: Colors.grey.shade200),
              SizedBox(height: 8),
              Text(
                "Description:",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF2E3B8C),
                ),
              ),
              SizedBox(height: 4),
              Text(
                fqc.description,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              if (fqc.resolution.isNotEmpty) ...[
                SizedBox(height: 16),
                Text(
                  "Resolution:",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF2E3B8C),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  fqc.resolution,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'Pending':
        color = Colors.orange;
        break;
      case 'In Progress':
        color = Colors.blue;
        break;
      case 'Closed':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status,
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}