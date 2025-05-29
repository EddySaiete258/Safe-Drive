import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:safedrive/firebase_options.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  return runApp(const SafeDriveApp());
}

class SafeDriveApp extends StatelessWidget {
  const SafeDriveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SafeDrive',
      home: SplashScreen(),
    );
  }
}
