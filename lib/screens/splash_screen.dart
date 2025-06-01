import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safedrive/providers/auth_provider.dart';
import 'package:safedrive/screens/contributor_map_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'onboarding_screen.dart';
import 'auth_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    await Future.delayed(const Duration(seconds: 10));
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('onboarding_seen') ?? false;

    if (!mounted) return;
    final authProvider = Provider.of<AuthProviderLocal>(context, listen: false);
    
    if(authProvider.isLoggedIn()){
      Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ContributorMapScreen(),
      ),
    );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => seen ? const AuthScreen() : const OnboardingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4CE5B1),
      body: Stack(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: Image.asset(
              'assets/images/skytowers.png',
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
          Center(
            child: Image.asset(
              'assets/images/Safedrive.png',
              width: 200,
            ),
          ),
        ],
      ),
    );
  }
}
