import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:to_do_list/dashboard.dart';
import 'package:to_do_list/registration.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool _isNotValidate = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    initSharedPref();
  }

  void initSharedPref() async {
    prefs = await SharedPreferences.getInstance();
  }

  void loginUser() async {
    if (_isLoading) return;

    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      setState(() {
        _isNotValidate = true;
      });
      _showSnackBar('Please fill in all fields', Colors.orange);
      return;
    }

    setState(() {
      _isLoading = true;
      _isNotValidate = false;
    });

    try {
      var reqBody = {
        "email": emailController.text,
        "password": passwordController.text,
      };

      print('📤 Sending login request...');

      var response = await http
          .post(
            Uri.parse('https://todolist-flutterapp.onrender.com/signin'), // CHANGE THIS!
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(reqBody),
          )
          .timeout(Duration(seconds: 15));

      print('📥 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      var jsonResponse = jsonDecode(response.body);

      // Handle different status codes
      if (response.statusCode == 200) {
        // Success
        if (jsonResponse['token'] != null) {
          var myToken = jsonResponse['token'];
          await prefs.setString('token', myToken);

          _showSnackBar('Login successful!', Colors.green);

          await Future.delayed(Duration(milliseconds: 500));

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => Dashboard(
                    token: myToken,
                    onLogout: () async {
                      await prefs.remove('token');
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/',
                        (route) => false,
                      );
                    },
                  ),
            ),
          );
        } else {
          _showSnackBar('No token received', Colors.red);
        }
      } else if (response.statusCode == 404) {
        // User not found
        _showSnackBar('User not found. Please check your email.', Colors.red);
      } else if (response.statusCode == 400) {
        // Invalid password or missing fields
        _showSnackBar(
          jsonResponse['message'] ?? 'Invalid email or password',
          Colors.red,
        );
      } else {
        // Other server errors
        _showSnackBar(
          'Server error: ${jsonResponse['message'] ?? response.statusCode}',
          Colors.red,
        );
      }
    } on http.ClientException catch (e) {
      _showSnackBar('Connection error: Check your internet', Colors.red);
      print('Connection error: $e');
    } on TimeoutException catch (_) {
      _showSnackBar('Request timeout. Try again.', Colors.red);
    } catch (e) {
      _showSnackBar('Login failed. Please try again.', Colors.red);
      print('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlueAccent,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isSmallScreen = constraints.maxHeight < 700;

            return SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // Add top padding here
                      SizedBox(height: constraints.maxHeight * 0.04),

                      // Top decorative wave - FIXED HEIGHT
                      Container(
                        height:
                            isSmallScreen
                                ? constraints.maxHeight * 0.25
                                : constraints.maxHeight * 0.28,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(40),
                            bottomRight: Radius.circular(40),
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // App Icon/Logo
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blueAccent.withOpacity(0.3),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.check_circle,
                                  color: Colors.lightBlueAccent,
                                  size: 50,
                                ),
                              ),
                              SizedBox(height: 15),
                              Text(
                                'Welcome Back',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Sign in to continue to your tasks',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Login Form - FLEXIBLE
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: isSmallScreen ? 20 : 30,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Email Field
                              Container(
                                margin: EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blueAccent.withOpacity(0.1),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: TextStyle(fontSize: 16),
                                  decoration: InputDecoration(
                                    hintText: 'Enter your email',
                                    hintStyle: TextStyle(
                                      color: Colors.grey[500],
                                    ),
                                    border: InputBorder.none,
                                    prefixIcon: Icon(
                                      Icons.email_outlined,
                                      color: Colors.lightBlueAccent,
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: isSmallScreen ? 14 : 16,
                                    ),
                                    errorText:
                                        _isNotValidate &&
                                                emailController.text.isEmpty
                                            ? 'Email is required'
                                            : null,
                                  ),
                                ),
                              ),

                              // Password Field
                              Container(
                                margin: EdgeInsets.only(bottom: 24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blueAccent.withOpacity(0.1),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: passwordController,
                                  obscureText: _obscurePassword,
                                  style: TextStyle(fontSize: 16),
                                  decoration: InputDecoration(
                                    hintText: 'Enter your password',
                                    hintStyle: TextStyle(
                                      color: Colors.grey[500],
                                    ),
                                    border: InputBorder.none,
                                    prefixIcon: Icon(
                                      Icons.lock_outline,
                                      color: Colors.lightBlueAccent,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.grey[500],
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: isSmallScreen ? 14 : 16,
                                    ),
                                    errorText:
                                        _isNotValidate &&
                                                passwordController.text.isEmpty
                                            ? 'Password is required'
                                            : null,
                                  ),
                                ),
                              ),

                              // Login Button
                              Container(
                                height: isSmallScreen ? 48 : 52,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.lightBlueAccent,
                                      Colors.blueAccent,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blueAccent.withOpacity(0.3),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : loginUser,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child:
                                      _isLoading
                                          ? SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                          : Text(
                                            'SIGN IN',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                              letterSpacing: 1.1,
                                            ),
                                          ),
                                ),
                              ),

                              SizedBox(height: isSmallScreen ? 12 : 16),

                              // Divider with "or"
                              if (!isSmallScreen) ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: Divider(
                                        color: Colors.white.withOpacity(0.3),
                                        thickness: 1,
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Text(
                                        'or',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(
                                        color: Colors.white.withOpacity(0.3),
                                        thickness: 1,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                              ],

                              // Sign Up Section - UPDATED TEXT
                              Container(
                                height: isSmallScreen ? 48 : 52,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.lightBlueAccent.withOpacity(
                                      0.3,
                                    ),
                                    width: 1.5,
                                  ),
                                ),
                                child: TextButton(
                                  onPressed:
                                      _isLoading
                                          ? null
                                          : () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) => Registration(),
                                              ),
                                            );
                                          },
                                  style: TextButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Don\'t have an account? ',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      Text(
                                        'Sign Up',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.lightBlueAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Spacer to push content up on small screens
                              if (isSmallScreen) Spacer(),

                              // Forgot Password - Only show on larger screens
                              if (!isSmallScreen) ...[
                                SizedBox(height: 16),
                                TextButton(
                                  onPressed: () {
                                    _showSnackBar(
                                      'Forgot password feature coming soon!',
                                      Colors.blue,
                                    );
                                  },
                                  child: Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],

                              // Small screen extra spacing
                              SizedBox(height: isSmallScreen ? 20 : 0),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
