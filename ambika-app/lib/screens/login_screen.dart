import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  final _ambikaIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;

  Future<void> login() async {
    final ambikaIdText = _ambikaIdController.text.trim();
    final password = _passwordController.text.trim();

    print('Raw Ambika ID input: "$ambikaIdText"');
    print('Raw Password input: "$password"');

    final ambikaId = int.tryParse(ambikaIdText);

    if (ambikaId == null || password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a valid Ambika ID and password.';
      });
      print('Validation failed: Invalid Ambika ID or empty password');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('Sending POST request to backend with:');
      print('ambikaId: $ambikaId, password: $password');

      final response = await http.post(
        Uri.parse('http://127.0.0.1:3000/signin/validateCredentialsToGetAY'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'conn': 'connect_main',
          'environment': 'LOCAL',
          'ambikaid': ambikaId,
          'password': password,
        }),
      );

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        final ayList = responseData['AY_list'];
        final isValidUser = ayList != null &&
            ayList.isNotEmpty &&
            ayList[0]['debug_valid_user'] == 1;

        if (isValidUser) {
          print('Login success!');
          final apiKey = responseData['apiKey'];
          final message = responseData['message'];

          print('Message: $message');
          print('API Key: $apiKey');

          // TODO: Use apiKey as needed

          // Navigate to home or dashboard
          Navigator.pushReplacementNamed(context, '/dashboard', arguments: {
            'ambikaId': ambikaId,
            'apiKey': apiKey,
          });
        } else {
          setState(() {
            _errorMessage = 'Invalid Ambika ID or password.';
          });
          print('Login failed: Invalid Ambika ID or password.');
        }
      } else {
        setState(() {
          _errorMessage = 'Login failed. Please try again.';
        });
        print('Error: Login failed with status ${response.statusCode}');
      }
    } catch (e) {
      print('Login error: $e');
      setState(() {
        _errorMessage = '⚠️ Network error. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      print('Login process ended');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background design element
          Positioned(
            top: 0,
            right: 0,
            child: Image.asset(
              'assets/logo_sidedesign.png',
              width: MediaQuery.of(context).size.width * 0.4,
              fit: BoxFit.cover,
            ),
          ),

          // Blue wave at the bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: screenHeight * 0.15,
              child: CustomPaint(
                size: Size(
                    MediaQuery.of(context).size.width, screenHeight * 0.15),
                painter: WavePainter(color: const Color(0xFF2E3B8C)),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              child: Container(
                height: screenHeight,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      SizedBox(height: screenHeight * 0.08),

                      // Logo
                      Image.asset(
                        'assets/logo.png',
                        height: 60,
                      ),

                      SizedBox(height: screenHeight * 0.05),

                      // Title
                      Text(
                        "Let's Connect With Us!",
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: screenHeight * 0.04),

                      // Error message
                      if (_errorMessage != null && _errorMessage!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 15),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: GoogleFonts.poppins(
                                    color: Colors.red,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Ambika ID TextField
                      Container(
                        margin: EdgeInsets.only(bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 5, bottom: 6),
                              child: Text(
                                "Ambika ID",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            TextFormField(
                              controller: _ambikaIdController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: "Enter your Ambika ID",
                                hintStyle: GoogleFonts.poppins(
                                    fontSize: 14, color: Colors.grey),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF2E3B8C), width: 2),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your Ambika ID';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      // Password Field
                      Container(
                        margin: EdgeInsets.only(bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 5, bottom: 6),
                              child: Text(
                                "Password",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              decoration: InputDecoration(
                                hintText: "Enter your password",
                                hintStyle: GoogleFonts.poppins(
                                    fontSize: 14, color: Colors.grey),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF2E3B8C), width: 2),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.06),

                      // Sign In Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  if (_formKey.currentState!.validate()) {
                                    login();
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E3B8C),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "SIGN IN",
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Icon(Icons.arrow_forward,
                                        color: Colors.white),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom wave painter for the bottom decoration
class WavePainter extends CustomPainter {
  final Color color;

  WavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    // Starting point (bottom left)
    path.moveTo(0, size.height);

    // Create a wave effect
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.3,
        size.width * 0.5, size.height * 0.5);

    path.quadraticBezierTo(
        size.width * 0.75, size.height * 0.7, size.width, size.height * 0.2);

    // Complete the shape
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}