import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:to_do_list/dashboard.dart';
import 'package:to_do_list/loginPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  // Allow prefs to be nullable so tests can create MyApp() without passing SharedPreferences
  final SharedPreferences? prefs;

  const MyApp({this.prefs, super.key});

  @override
  Widget build(BuildContext context) {
    String? token = prefs?.getString('token');

    return MaterialApp(
      title: 'To-do-list',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.black,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Only navigate to Dashboard when token is present, non-empty and not expired
      home:
          (token != null && token.isNotEmpty && !JwtDecoder.isExpired(token))
              ? Dashboard(
                token: token,
                onLogout: () async {
                  // Clear token and navigate back to login
                  await prefs?.remove('token');
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => SignInPage()),
                    (route) => false,
                  );
                },
              )
              : SignInPage(),
    );
  }
}
