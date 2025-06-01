import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:safedrive/screens/auth_screen.dart';
import 'package:safedrive/screens/contributor_map_screen.dart';
import 'package:safedrive/screens/otp_verification_screen.dart';

class AuthProviderLocal with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _verificationId;
  bool isLoading = false;

  Future<void> sendOTP(String phoneNumber, BuildContext context) async {
    isLoading = true;
    notifyListeners();

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-verificação (Android)
        await _auth.signInWithCredential(credential);
        isLoading = false;
        notifyListeners();
      },
      verificationFailed: (FirebaseAuthException e) {
        isLoading = false;
        notifyListeners();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: ${e.message}')));
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        isLoading = false;
        notifyListeners();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OTPVerificationScreen()),
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<void> verifyOTP(String smsCode, BuildContext context) async {
    isLoading = true;
    notifyListeners();

    try {
      print("Code to validate $smsCode");
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      await _auth.signInWithCredential(credential);
      isLoading = false;
      print("Valid Credential");
      notifyListeners();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ContributorMapScreen()),
      );
    } catch (e) {
      isLoading = false;
      notifyListeners();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro: ${e.toString()}')));
    }
  }

  Future<void> login(String phoneNumber, BuildContext context) async {
    isLoading = true;
    notifyListeners();
    print("PHONE: $phoneNumber");
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-verificação (Android)
        await _auth.signInWithCredential(credential);
        isLoading = false;
        notifyListeners();
      },
      verificationFailed: (FirebaseAuthException e) {
        isLoading = false;
        notifyListeners();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: ${e.message}')));
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        isLoading = false;
        notifyListeners();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OTPVerificationScreen()),
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
        print("verificationId: $verificationId");
      },
    );
  }

  bool isLoggedIn() {
    var currentUser = _auth.currentUser;

    if (currentUser != null) {
      return true;
    }
    return false;
  }

  Future<void> logout(context) async {
    isLoading = true;
    notifyListeners();
    try {
      await _auth.signOut();
      isLoading = false;
      notifyListeners();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    } catch (e) {
      isLoading = false;
      notifyListeners();
    }
  }
}
