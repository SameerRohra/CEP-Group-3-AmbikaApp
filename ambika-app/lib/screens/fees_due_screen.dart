import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:animate_do/animate_do.dart';

class FeesScreen extends StatefulWidget {
  const FeesScreen({super.key});

  @override
  State<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends State<FeesScreen> with TickerProviderStateMixin {
  late Future<Map<String, dynamic>> _feesData;
  late TabController _tabController;
  bool _isLoading = true;

  late String apiKey;
  late String ambikaId;
  final String conn = "connect_2324";
  final String baseUrl = "http://127.0.0.1:3000"; // Adjust the base URL as needed

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
    ambikaId = args?['ambikaId'] ?? '961';
    _feesData = _loadFeesData();
  }

  Future<Map<String, dynamic>> _loadFeesData() async {
    // Add the API key to the headers
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
    };

    final response = await http.get(
      Uri.parse('$baseUrl/fees/get/$conn/$ambikaId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      setState(() {
        _isLoading = false;
      });
      return {
        'fees': jsonDecode(response.body),
      };
    } else {
      throw Exception('Failed to load dashboard data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF2E3B8C),
        title: Text(
          "Fees Management",
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
                Tab(text: "Fee Breakup"),
                Tab(text: "Transactions"),
              ],
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              // Show info about fees
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fee details are updated periodically'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _feesData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || _isLoading) {
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
                ],
              ),
            );
          } else {
            final data = snapshot.data!;
            final summary = data['fees']['allFeeData']['summary'];
            final feeBreakup =
                data['fees']['allFeeData']['monthwise'] as List<dynamic>? ?? [];
            final transactions =
                data['fees']['allFeeData']['transactions'] as List<dynamic>? ?? [];

            return Column(
              children: [
                FadeInDown(
                  duration: const Duration(milliseconds: 600),
                  child: _buildSummaryCard(summary),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildFeeBreakupTab(feeBreakup),
                      _buildTransactionsTab(transactions),
                    ],
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> summary) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E3B8C), Color(0xFF252F6B)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E3B8C).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 16),
            child: Text(
              "Fee Summary",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatBlock("Total", "₹${summary['total_payable'] ?? 0}", Colors.amber),
              _buildDivider(),
              _buildStatBlock("Paid", "₹${summary['total_paid'] ?? 0}", Colors.greenAccent),
              _buildDivider(),
              _buildStatBlock("Due", "₹${summary['due_amount'] ?? 0}", Colors.redAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white24,
    );
  }

  Widget _buildStatBlock(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFeeBreakupTab(List<dynamic> feeBreakup) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: feeBreakup.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.receipt_long,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No fee breakup available",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 12, bottom: 20),
              itemCount: feeBreakup.length,
              itemBuilder: (context, index) {
                final item = feeBreakup[index];
                return FadeInUp(
                  duration: Duration(milliseconds: 300 + (index * 50)),
                  delay: Duration(milliseconds: 100 * index),
                  child: _buildFeeItem(item),
                );
              },
            ),
    );
  }

  Widget _buildTransactionsTab(List<dynamic> transactions) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: transactions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.payment,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No transactions available",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 12, bottom: 20),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final tx = transactions[index];
                return FadeInUp(
                  duration: Duration(milliseconds: 300 + (index * 50)),
                  delay: Duration(milliseconds: 100 * index),
                  child: _buildTransactionItem(tx),
                );
              },
            ),
    );
  }

  Widget _buildFeeItem(Map<String, dynamic> item) {
    final month = item['Month'] ?? 'Month';
    final amount = item['DueAmount'] ?? 0;
    final status = item['Status']?.toString().toLowerCase() == 'paid' ? 'Paid' : 'Pending';
    final statusColor = status == 'Paid' ? Colors.green : Colors.orange;
    final statusBgColor = status == 'Paid' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E3B8C).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_month,
                  color: Color(0xFF2E3B8C),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                month,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "₹$amount",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.poppins(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> tx) {
    final ref = tx['Payment_Ref']?.toString() ?? 'N/A';
    final amount = tx['Amount']?.toString() ?? '0';
    final mode = tx['Mode']?.toString() ?? 'Unknown';
    final date = tx['Date']?.toString() ?? 'No Date';
    final months = (tx['Months'] as List?)?.join(', ') ?? 'Not specified';

    IconData getModeIcon() {
      switch (mode.toLowerCase()) {
        case 'cash':
          return Icons.money;
        case 'online':
          return Icons.language;
        case 'upi':
          return Icons.qr_code;
        case 'card':
          return Icons.credit_card;
        default:
          return Icons.payment;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E3B8C).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      getModeIcon(),
                      color: const Color(0xFF2E3B8C),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Ref: $ref",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        date,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                "₹$amount",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E3B8C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTransactionDetail("Payment Mode", mode),
              _buildTransactionDetail("For", months),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}