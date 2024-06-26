import 'package:contactlink/screens/about_screen.dart';
import 'package:contactlink/screens/user_screen.dart';
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

class AppRoutes {
  static const String login = '/';
  static const String home = '/home';
  static const String about = '/about';
  static const String user = '/user';

  static Map<String, WidgetBuilder> define() {
    return {
      login: (context) => const LoginScreen(),
      home: (context) => const HomeScreen(),
      about: (context) => const AboutScreen(),
      user: (context) => const UserScreen(),
    };
  }
}
