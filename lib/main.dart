import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roadeye/screens/home/HomeScreen.dart';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: const FirebaseOptions(
          apiKey: 'AIzaSyD8vig0Zbx6IKi1k_-vIIk0KLT0zlrnHrQ',
          appId: '1:365192131891:android:9269ad80ce8ce30525ba46',
          messagingSenderId: '365192131891',
          projectId: 'roadeye-be16'));
  DartPluginRegistrant.ensureInitialized();
  runApp(
    const MyApp(),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RoadEye',
      theme: _buildTheme(Brightness.dark),
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

ThemeData _buildTheme(brightness) {
  var baseTheme = ThemeData(
    brightness: brightness,
    useMaterial3: true,
  );

  return baseTheme.copyWith(
    textTheme: GoogleFonts.ralewayTextTheme(baseTheme.textTheme),
  );
}
