// import 'dart:convert';
// import 'dart:math';

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:http/http.dart' as http;
// import 'package:to_do_list/loginPage.dart';

// class Registration extends StatefulWidget {
//   const Registration({super.key});

//   @override
//   _RegistrationState createState() => _RegistrationState();
// }

// class _RegistrationState extends State<Registration> {
//   TextEditingController emailController = TextEditingController();
//   TextEditingController passwordController = TextEditingController();
//   bool _isNotValidate = false;
//   bool _isLoading = false;
//   bool _obscurePassword = true;
//   bool _passwordGenerated = false;

//   Future<void> registerUser() async {
//     if (_isLoading) return;

//     final email = emailController.text.trim();
//     final password = passwordController.text.trim();

//     if (email.isEmpty || password.isEmpty) {
//       setState(() => _isNotValidate = true);
//       _showSnackBar('Please fill in all fields', Colors.orange);
//       return;
//     }

//     if (password.length < 6) {
//       _showSnackBar('Password must be at least 6 characters', Colors.orange);
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//       _isNotValidate = false;
//     });

//     final regBody = {"email": email, "password": password};
//     // print('Request JSON: ${jsonEncode(regBody)}');

//     try {
//       final response = await http
//           .post(
//             Uri.parse('http://localhost:5000/signup'),
//             headers: {'Content-Type': 'application/json'},
//             body: jsonEncode(regBody),
//           )
//           .timeout(Duration(seconds: 15));

//       // print('Status: ${response.statusCode}');
//       // print('Body: ${response.body}');

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         final jsonResponse = jsonDecode(response.body);
//         if (jsonResponse['status'] == true || jsonResponse['success'] == true) {
//           _showSnackBar(
//             'Registration successful! Please sign in.',
//             Colors.green,
//           );

//           await Future.delayed(Duration(milliseconds: 5000));

//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (_) => SignInPage()),
//           );
//           return;
//         } else {
//           final msg =
//               jsonResponse['message'] ??
//               jsonResponse['error'] ??
//               'Registration failed';
//           _showSnackBar(msg, Colors.red);
//         }
//       } else {
//         _showSnackBar('Server error: ${response.statusCode}', Colors.red);
//       }
//     } on http.ClientException catch (e) {
//       _showSnackBar('Connection error: Check your internet', Colors.red);
//     } catch (e) {
//       print('Error: $e');
//       _showSnackBar('Registration failed. Please try again.', Colors.red);
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   void _showSnackBar(String message, Color color) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: color,
//         behavior: SnackBarBehavior.floating,
//         duration: Duration(seconds: 3),
//       ),
//     );
//   }

//   String generatePassword() {
//     String upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
//     String lower = 'abcdefghijklmnopqrstuvwxyz';
//     String numbers = '1234567890';
//     String symbols = '!@#\$%^&*';

//     String password = '';
//     int passLength = 12;

//     String seed = upper + lower + numbers + symbols;
//     List<String> list = seed.split('').toList();
//     Random rand = Random();

//     // Ensure at least one of each character type
//     password += upper[rand.nextInt(upper.length)];
//     password += lower[rand.nextInt(lower.length)];
//     password += numbers[rand.nextInt(numbers.length)];
//     password += symbols[rand.nextInt(symbols.length)];

//     // Fill the rest
//     for (int i = 4; i < passLength; i++) {
//       password += list[rand.nextInt(list.length)];
//     }

//     // Shuffle the password
//     List<String> passwordList = password.split('');
//     passwordList.shuffle(rand);
//     return passwordList.join();
//   }

//   void _copyToClipboard() {
//     if (passwordController.text.isNotEmpty) {
//       Clipboard.setData(ClipboardData(text: passwordController.text));
//       _showSnackBar('Password copied to clipboard!', Colors.green);
//     }
//   }

//   void _generatePassword() {
//     final newPassword = generatePassword();
//     setState(() {
//       passwordController.text = newPassword;
//       _passwordGenerated = true;
//       _obscurePassword = false; // Show the generated password
//     });
//     _showSnackBar('Secure password generated!', Colors.blue);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.lightBlueAccent,
//       body: SafeArea(
//         child: LayoutBuilder(
//           builder: (context, constraints) {
//             bool isSmallScreen = constraints.maxHeight < 700;

//             return SingleChildScrollView(
//               physics: BouncingScrollPhysics(),
//               child: ConstrainedBox(
//                 constraints: BoxConstraints(minHeight: constraints.maxHeight),
//                 child: IntrinsicHeight(
//                   child: Column(
//                     children: [
//                       // Top padding
//                       SizedBox(height: constraints.maxHeight * 0.04),

//                       // Top decorative wave
//                       Container(
//                         height:
//                             isSmallScreen
//                                 ? constraints.maxHeight * 0.25
//                                 : constraints.maxHeight * 0.28,
//                         decoration: BoxDecoration(
//                           color: Colors.white.withOpacity(0.1),
//                           borderRadius: BorderRadius.only(
//                             bottomLeft: Radius.circular(40),
//                             bottomRight: Radius.circular(40),
//                           ),
//                         ),
//                         child: Center(
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               // App Icon/Logo
//                               Container(
//                                 width: 80,
//                                 height: 80,
//                                 decoration: BoxDecoration(
//                                   color: Colors.white,
//                                   shape: BoxShape.circle,
//                                   boxShadow: [
//                                     BoxShadow(
//                                       color: Colors.blueAccent.withOpacity(0.3),
//                                       blurRadius: 15,
//                                       spreadRadius: 2,
//                                     ),
//                                   ],
//                                 ),
//                                 child: Icon(
//                                   Icons.person_add_alt_1,
//                                   color: Colors.lightBlueAccent,
//                                   size: 50,
//                                 ),
//                               ),
//                               SizedBox(height: 15),
//                               Text(
//                                 'Create Account',
//                                 style: TextStyle(
//                                   fontSize: 24,
//                                   fontWeight: FontWeight.w700,
//                                   color: Colors.white,
//                                 ),
//                               ),
//                               SizedBox(height: 6),
//                               Text(
//                                 'Join us to manage your tasks',
//                                 style: TextStyle(
//                                   fontSize: 14,
//                                   color: Colors.white.withOpacity(0.8),
//                                 ),
//                                 textAlign: TextAlign.center,
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),

//                       // Registration Form
//                       Expanded(
//                         child: Container(
//                           padding: EdgeInsets.symmetric(
//                             horizontal: 24,
//                             vertical: isSmallScreen ? 20 : 30,
//                           ),
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             crossAxisAlignment: CrossAxisAlignment.stretch,
//                             children: [
//                               // Email Field
//                               Container(
//                                 margin: EdgeInsets.only(bottom: 16),
//                                 decoration: BoxDecoration(
//                                   color: Colors.white,
//                                   borderRadius: BorderRadius.circular(12),
//                                   boxShadow: [
//                                     BoxShadow(
//                                       color: Colors.blueAccent.withOpacity(0.1),
//                                       blurRadius: 8,
//                                       spreadRadius: 1,
//                                     ),
//                                   ],
//                                 ),
//                                 child: TextField(
//                                   controller: emailController,
//                                   keyboardType: TextInputType.emailAddress,
//                                   style: TextStyle(fontSize: 16),
//                                   decoration: InputDecoration(
//                                     hintText: 'Enter your email',
//                                     hintStyle: TextStyle(
//                                       color: Colors.grey[500],
//                                     ),
//                                     border: InputBorder.none,
//                                     prefixIcon: Icon(
//                                       Icons.email_outlined,
//                                       color: Colors.lightBlueAccent,
//                                     ),
//                                     contentPadding: EdgeInsets.symmetric(
//                                       horizontal: 16,
//                                       vertical: isSmallScreen ? 14 : 16,
//                                     ),
//                                     errorText:
//                                         _isNotValidate &&
//                                                 emailController.text.isEmpty
//                                             ? 'Email is required'
//                                             : null,
//                                   ),
//                                 ),
//                               ),

//                               // Password Field
//                               Container(
//                                 margin: EdgeInsets.only(bottom: 24),
//                                 decoration: BoxDecoration(
//                                   color: Colors.white,
//                                   borderRadius: BorderRadius.circular(12),
//                                   boxShadow: [
//                                     BoxShadow(
//                                       color: Colors.blueAccent.withOpacity(0.1),
//                                       blurRadius: 8,
//                                       spreadRadius: 1,
//                                     ),
//                                   ],
//                                 ),
//                                 child: TextField(
//                                   controller: passwordController,
//                                   obscureText: _obscurePassword,
//                                   style: TextStyle(fontSize: 16),
//                                   decoration: InputDecoration(
//                                     hintText: 'Create a strong password',
//                                     hintStyle: TextStyle(
//                                       color: Colors.grey[500],
//                                     ),
//                                     border: InputBorder.none,
//                                     prefixIcon: IconButton(
//                                       icon: Icon(
//                                         Icons.password,
//                                         color: Colors.lightBlueAccent,
//                                       ),
//                                       onPressed: _generatePassword,
//                                       tooltip: 'Generate secure password',
//                                     ),
//                                     suffixIcon: Row(
//                                       mainAxisSize: MainAxisSize.min,
//                                       children: [
//                                         IconButton(
//                                           icon: Icon(
//                                             _obscurePassword
//                                                 ? Icons.visibility_off
//                                                 : Icons.visibility,
//                                             color: Colors.grey[500],
//                                           ),
//                                           onPressed: () {
//                                             setState(() {
//                                               _obscurePassword =
//                                                   !_obscurePassword;
//                                             });
//                                           },
//                                           tooltip: 'Show/hide password',
//                                         ),
//                                         if (passwordController.text.isNotEmpty)
//                                           IconButton(
//                                             icon: Icon(
//                                               Icons.copy,
//                                               color: Colors.grey[500],
//                                             ),
//                                             onPressed: _copyToClipboard,
//                                             tooltip: 'Copy to clipboard',
//                                           ),
//                                       ],
//                                     ),
//                                     contentPadding: EdgeInsets.symmetric(
//                                       horizontal: 16,
//                                       vertical: isSmallScreen ? 14 : 16,
//                                     ),
//                                     errorText:
//                                         _isNotValidate &&
//                                                 passwordController.text.isEmpty
//                                             ? 'Password is required'
//                                             : null,
//                                   ),
//                                 ),
//                               ),

//                               // Password Strength Indicator (if generated)
//                               if (_passwordGenerated &&
//                                   passwordController.text.isNotEmpty)
//                                 Container(
//                                   margin: EdgeInsets.only(bottom: 16),
//                                   padding: EdgeInsets.all(12),
//                                   decoration: BoxDecoration(
//                                     color: Colors.green.withOpacity(0.1),
//                                     borderRadius: BorderRadius.circular(8),
//                                     border: Border.all(
//                                       color: Colors.green.withOpacity(0.3),
//                                     ),
//                                   ),
//                                   child: Row(
//                                     children: [
//                                       Icon(
//                                         Icons.check_circle,
//                                         color: Colors.green,
//                                         size: 16,
//                                       ),
//                                       SizedBox(width: 8),
//                                       Expanded(
//                                         child: Text(
//                                           'Secure password generated!',
//                                           style: TextStyle(
//                                             fontSize: 13,
//                                             color: Colors.green[800],
//                                             fontWeight: FontWeight.w500,
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),

//                               // Register Button
//                               Container(
//                                 height: isSmallScreen ? 48 : 52,
//                                 decoration: BoxDecoration(
//                                   borderRadius: BorderRadius.circular(12),
//                                   gradient: LinearGradient(
//                                     colors: [
//                                       Colors.lightBlueAccent,
//                                       Colors.blueAccent,
//                                     ],
//                                     begin: Alignment.topLeft,
//                                     end: Alignment.bottomRight,
//                                   ),
//                                   boxShadow: [
//                                     BoxShadow(
//                                       color: Colors.blueAccent.withOpacity(0.3),
//                                       blurRadius: 10,
//                                       spreadRadius: 1,
//                                     ),
//                                   ],
//                                 ),
//                                 child: ElevatedButton(
//                                   onPressed: _isLoading ? null : registerUser,
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: Colors.transparent,
//                                     shadowColor: Colors.transparent,
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(12),
//                                     ),
//                                     padding: EdgeInsets.zero,
//                                   ),
//                                   child:
//                                       _isLoading
//                                           ? SizedBox(
//                                             width: 20,
//                                             height: 20,
//                                             child: CircularProgressIndicator(
//                                               strokeWidth: 2.5,
//                                               valueColor:
//                                                   AlwaysStoppedAnimation<Color>(
//                                                     Colors.white,
//                                                   ),
//                                             ),
//                                           )
//                                           : Text(
//                                             'CREATE ACCOUNT',
//                                             style: TextStyle(
//                                               fontSize: 16,
//                                               fontWeight: FontWeight.w600,
//                                               color: Colors.white,
//                                               letterSpacing: 1.1,
//                                             ),
//                                           ),
//                                 ),
//                               ),

//                               SizedBox(height: isSmallScreen ? 12 : 16),

//                               // Divider with "or"
//                               if (!isSmallScreen) ...[
//                                 Row(
//                                   children: [
//                                     Expanded(
//                                       child: Divider(
//                                         color: Colors.white.withOpacity(0.3),
//                                         thickness: 1,
//                                       ),
//                                     ),
//                                     Padding(
//                                       padding: EdgeInsets.symmetric(
//                                         horizontal: 12,
//                                       ),
//                                       child: Text(
//                                         'or',
//                                         style: TextStyle(
//                                           color: Colors.white.withOpacity(0.7),
//                                           fontSize: 13,
//                                         ),
//                                       ),
//                                     ),
//                                     Expanded(
//                                       child: Divider(
//                                         color: Colors.white.withOpacity(0.3),
//                                         thickness: 1,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 SizedBox(height: 16),
//                               ],

//                               // Sign In Section
//                               Container(
//                                 height: isSmallScreen ? 48 : 52,
//                                 decoration: BoxDecoration(
//                                   color: Colors.white,
//                                   borderRadius: BorderRadius.circular(12),
//                                   border: Border.all(
//                                     color: Colors.lightBlueAccent.withOpacity(
//                                       0.3,
//                                     ),
//                                     width: 1.5,
//                                   ),
//                                 ),
//                                 child: TextButton(
//                                   onPressed:
//                                       _isLoading
//                                           ? null
//                                           : () {
//                                             Navigator.pushReplacement(
//                                               context,
//                                               MaterialPageRoute(
//                                                 builder:
//                                                     (context) => SignInPage(),
//                                               ),
//                                             );
//                                           },
//                                   style: TextButton.styleFrom(
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(12),
//                                     ),
//                                     padding: EdgeInsets.zero,
//                                   ),
//                                   child: Row(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     children: [
//                                       Text(
//                                         'Already have an account? ',
//                                         style: TextStyle(
//                                           fontSize: 14,
//                                           fontWeight: FontWeight.w500,
//                                           color: Colors.grey[700],
//                                         ),
//                                       ),
//                                       Text(
//                                         'Sign In',
//                                         style: TextStyle(
//                                           fontSize: 14,
//                                           fontWeight: FontWeight.w600,
//                                           color: Colors.lightBlueAccent,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),

//                               // Spacer to push content up on small screens
//                               if (isSmallScreen) Spacer(),

//                               // Small screen extra spacing
//                               SizedBox(height: isSmallScreen ? 20 : 0),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:to_do_list/loginPage.dart';

class Registration extends StatefulWidget {
  const Registration({super.key});

  @override
  _RegistrationState createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool _isNotValidate = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _passwordGenerated = false;
  String? _emailError;

  // Email validation regex
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      caseSensitive: false,
      multiLine: false,
    );
    return emailRegex.hasMatch(email);
  }

  // Check if email contains @gmail.com or other common domains
  bool _hasValidDomain(String email) {
    final commonDomains = [
      'gmail.com',
      'yahoo.com',
      'outlook.com',
      'hotmail.com',
      'icloud.com',
      'protonmail.com',
      'mail.com',
      'aol.com',
    ];

    final parts = email.split('@');
    if (parts.length != 2) return false;

    final domain = parts[1].toLowerCase();
    return commonDomains.contains(domain);
  }

  // Validate email with detailed error messages
  String? _validateEmail(String email) {
    if (email.isEmpty) return 'Email is required';

    if (!_isValidEmail(email)) {
      return 'Please enter a valid email address';
    }

    final parts = email.split('@');
    if (parts.length != 2) return 'Invalid email format';

    final username = parts[0];
    final domain = parts[1];

    // Check username
    if (username.isEmpty) return 'Email username cannot be empty';
    if (username.length < 3) return 'Email username is too short';

    // Check domain
    if (domain.isEmpty) return 'Email domain cannot be empty';
    if (!domain.contains('.')) return 'Email domain must contain a dot (.)';

    // Check for common TLDs
    final tld = domain.split('.').last;
    if (tld.length < 2) return 'Invalid domain extension';

    // Optional: Check for @gmail.com specifically if needed
    if (email.toLowerCase().contains('@gmail')) {
      if (!email.toLowerCase().endsWith('@gmail.com')) {
        return 'Please use @gmail.com (not @gmail)';
      }
    }

    return null;
  }

  Future<void> registerUser() async {
    if (_isLoading) return;

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // Clear previous errors
    setState(() {
      _emailError = null;
      _isNotValidate = false;
    });

    // Validate email
    final emailValidationError = _validateEmail(email);
    if (emailValidationError != null) {
      setState(() {
        _emailError = emailValidationError;
        _isNotValidate = true;
      });
      _showSnackBar(emailValidationError, Colors.orange);
      return;
    }

    if (password.isEmpty) {
      setState(() => _isNotValidate = true);
      _showSnackBar('Please enter a password', Colors.orange);
      return;
    }

    if (password.length < 6) {
      _showSnackBar('Password must be at least 6 characters', Colors.orange);
      return;
    }

    // Password strength check (optional)
    if (!_isStrongPassword(password)) {
      _showSnackBar(
        'Password should include uppercase, lowercase, numbers & special characters',
        Colors.orange,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _isNotValidate = false;
    });

    final regBody = {"email": email, "password": password};
    print('Request JSON: ${jsonEncode(regBody)}');

    try {
      final response = await http
          .post(
            Uri.parse('https://todolist-flutterapp.onrender.com/signup'), // Changed from localhost
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(regBody),
          )
          .timeout(Duration(seconds: 15));

      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == true || jsonResponse['success'] == true) {
          _showSnackBar(
            'Registration successful! Please sign in.',
            Colors.green,
          );

          await Future.delayed(Duration(milliseconds: 1500));

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => SignInPage()),
          );
          return;
        } else {
          final msg =
              jsonResponse['message'] ??
              jsonResponse['error'] ??
              'Registration failed';
          _showSnackBar(msg, Colors.red);
        }
      } else if (response.statusCode == 400) {
        final jsonResponse = jsonDecode(response.body);
        final msg = jsonResponse['message'] ?? 'Invalid request';
        _showSnackBar(msg, Colors.red);
      } else if (response.statusCode == 409) {
        _showSnackBar('Email already registered', Colors.red);
      } else {
        _showSnackBar('Server error: ${response.statusCode}', Colors.red);
      }
    } on http.ClientException catch (e) {
      _showSnackBar('Connection error: Check your internet', Colors.red);
    } catch (e) {
      print('Error: $e');
      _showSnackBar('Registration failed. Please try again.', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Password strength validator
  bool _isStrongPassword(String password) {
    // At least one uppercase
    bool hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    // At least one lowercase
    bool hasLower = RegExp(r'[a-z]').hasMatch(password);
    // At least one digit
    bool hasDigit = RegExp(r'\d').hasMatch(password);
    // At least one special character
    bool hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);

    return hasUpper && hasLower && hasDigit && hasSpecial;
  }

  // Real-time email validation
  void _onEmailChanged(String value) {
    final trimmedValue = value.trim();

    if (trimmedValue.isEmpty) {
      setState(() {
        _emailError = null;
      });
      return;
    }

    // Show validation only when user has typed something meaningful
    if (trimmedValue.contains('@')) {
      final error = _validateEmail(trimmedValue);
      setState(() {
        _emailError = error;
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

  String generatePassword() {
    String upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    String lower = 'abcdefghijklmnopqrstuvwxyz';
    String numbers = '1234567890';
    String symbols = '!@#\$%^&*';

    String password = '';
    int passLength = 12;

    String seed = upper + lower + numbers + symbols;
    List<String> list = seed.split('').toList();
    Random rand = Random();

    // Ensure at least one of each character type
    password += upper[rand.nextInt(upper.length)];
    password += lower[rand.nextInt(lower.length)];
    password += numbers[rand.nextInt(numbers.length)];
    password += symbols[rand.nextInt(symbols.length)];

    // Fill the rest
    for (int i = 4; i < passLength; i++) {
      password += list[rand.nextInt(list.length)];
    }

    // Shuffle the password
    List<String> passwordList = password.split('');
    passwordList.shuffle(rand);
    return passwordList.join();
  }

  void _copyToClipboard() {
    if (passwordController.text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: passwordController.text));
      _showSnackBar('Password copied to clipboard!', Colors.green);
    }
  }

  void _generatePassword() {
    final newPassword = generatePassword();
    setState(() {
      passwordController.text = newPassword;
      _passwordGenerated = true;
      _obscurePassword = false; // Show the generated password
    });
    _showSnackBar('Secure password generated!', Colors.blue);
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
                      // Top padding
                      SizedBox(height: constraints.maxHeight * 0.04),

                      // Top decorative wave
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
                                  Icons.person_add_alt_1,
                                  color: Colors.lightBlueAccent,
                                  size: 50,
                                ),
                              ),
                              SizedBox(height: 15),
                              Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Join us to manage your tasks',
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

                      // Registration Form
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
                              // Email Field with Validation
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blueAccent.withOpacity(
                                            0.1,
                                          ),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: TextField(
                                      controller: emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      style: TextStyle(fontSize: 16),
                                      onChanged: _onEmailChanged,
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
                                        errorText: _emailError,
                                      ),
                                    ),
                                  ),

                                  // Email validation helper text
                                  if (emailController.text.isNotEmpty &&
                                      _emailError == null)
                                    Padding(
                                      padding: EdgeInsets.only(left: 8, top: 4),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                            size: 14,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Valid email format',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),

                              SizedBox(height: 16),

                              // Password Field
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
                                  controller: passwordController,
                                  obscureText: _obscurePassword,
                                  style: TextStyle(fontSize: 16),
                                  decoration: InputDecoration(
                                    hintText: 'Create a strong password',
                                    hintStyle: TextStyle(
                                      color: Colors.grey[500],
                                    ),
                                    border: InputBorder.none,
                                    prefixIcon: IconButton(
                                      icon: Icon(
                                        Icons.password,
                                        color: Colors.lightBlueAccent,
                                      ),
                                      onPressed: _generatePassword,
                                      tooltip: 'Generate secure password',
                                    ),
                                    suffixIcon: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                            color: Colors.grey[500],
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword =
                                                  !_obscurePassword;
                                            });
                                          },
                                          tooltip: 'Show/hide password',
                                        ),
                                        if (passwordController.text.isNotEmpty)
                                          IconButton(
                                            icon: Icon(
                                              Icons.copy,
                                              color: Colors.grey[500],
                                            ),
                                            onPressed: _copyToClipboard,
                                            tooltip: 'Copy to clipboard',
                                          ),
                                      ],
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

                              // Password Strength Indicator (if generated)
                              if (_passwordGenerated &&
                                  passwordController.text.isNotEmpty)
                                Container(
                                  margin: EdgeInsets.only(bottom: 16),
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.green.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 16,
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Secure password generated!',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.green[800],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Password strength indicator (for manual entry)
                              if (passwordController.text.isNotEmpty &&
                                  !_passwordGenerated)
                                Container(
                                  margin: EdgeInsets.only(bottom: 16),
                                  child: _buildPasswordStrengthIndicator(
                                    passwordController.text,
                                  ),
                                ),

                              // Register Button
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
                                  onPressed: _isLoading ? null : registerUser,
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
                                            'CREATE ACCOUNT',
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

                              // Sign In Section
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
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) => SignInPage(),
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
                                        'Already have an account? ',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      Text(
                                        'Sign In',
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

  // Password strength indicator widget
  Widget _buildPasswordStrengthIndicator(String password) {
    int strength = 0;
    Color color = Colors.red;
    String text = 'Very Weak';

    if (password.length >= 8) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[a-z]').hasMatch(password)) strength++;
    if (RegExp(r'\d').hasMatch(password)) strength++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;

    switch (strength) {
      case 1:
        color = Colors.red;
        text = 'Very Weak';
        break;
      case 2:
        color = Colors.orange;
        text = 'Weak';
        break;
      case 3:
        color = Colors.yellow[700]!;
        text = 'Fair';
        break;
      case 4:
        color = Colors.lightGreen;
        text = 'Good';
        break;
      case 5:
        color = Colors.green;
        text = 'Strong';
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password Strength: $text',
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        Container(
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: Colors.grey[300],
          ),
          child: Row(
            children: List.generate(5, (index) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: index < strength ? color : Colors.grey[300],
                  ),
                ),
              );
            }),
          ),
        ),
        SizedBox(height: 4),
        if (strength < 3)
          Text(
            'Tip: Add uppercase, lowercase, numbers & special characters',
            style: TextStyle(fontSize: 10, color: Colors.orange),
          ),
      ],
    );
  }
}
