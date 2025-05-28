import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> onboardingData = [
    {
      'image': 'assets/images/onboardinglocation.png',
      'title': 'SAFEDRIVE',
      'desc': 'Compartilhar é proteger.\nObrigado por fazer parte dessa rede segura.',
    },
    {
      'image': 'assets/images/onboardingalert.png',
      'title': 'SAFEDRIVE',
      'desc': 'Com cada alerta enviado, as estradas ficam mais seguras para todos.\nEstamos carregando sua jornada segura!',
    },
  ];

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: onboardingData.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  child: Column(
                    children: [
                      Image.asset(onboardingData[index]['image']!, height: 300),
                      const SizedBox(height: 30),
                      Image.asset(
                        'assets/images/safedrive_black.png',
                        height: 40,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        onboardingData[index]['desc']!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      if (index == onboardingData.length - 1) ...[
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: _finishOnboarding,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CE5B1),
                            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'Começar',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ]
                    ],
                  ),
                );
              },
            ),
          ),
          _buildIndicator(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        onboardingData.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index ? Colors.green : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
