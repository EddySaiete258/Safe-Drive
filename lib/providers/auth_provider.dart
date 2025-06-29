import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:safedrive/model/user.dart';
import 'package:safedrive/screens/auth_screen.dart';
import 'package:safedrive/screens/contributor_map_screen.dart';
import 'package:safedrive/screens/otp_verification_screen.dart';
import 'package:safedrive/services/firestore_service.dart';
import 'package:safedrive/utils/custom_snackbar.dart';

class AuthProviderLocal with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final repository = FireStoreRepository();
  String? _verificationId;
  bool isLoading = false;

  Future<void> signup(
    String name,
    String phoneNumber,
    BuildContext context,
  ) async {
    isLoading = true;
    notifyListeners();
    bool userExist = await repository.userExist(phoneNumber);
    if (userExist) {
      customSnackBar(
        context,
        "Numero de telefone ja cadastrado",
        isError: true,
      );
      isLoading = false;
      notifyListeners();
      return;
    }
    UserAuth user = UserAuth(name, phoneNumber);
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
        customSnackBar(context, "Codigo enviado com sucesso");
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OTPVerificationScreen(user: user)),
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<void> verifyOTP(
    String smsCode,
    UserAuth? user,
    BuildContext context,
  ) async {
    isLoading = true;
    notifyListeners();

    try {
      print("Code to validate $smsCode");
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      await _auth.signInWithCredential(credential);

      if (user != null) {
        bool userCreated = await repository.saveUser(user);

        if (!userCreated) {
          customSnackBar(
            context,
            "Nao foi possivel efectuar o cadastrado, tente mais tarde",
            isError: true,
          );
          isLoading = false;
          notifyListeners();
          return;
        }
      }

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

    bool userExist = await repository.userExist(phoneNumber);
    if (!userExist) {
      customSnackBar(
        context,
        "Nao existe conta associada a este numero",
        isError: true,
      );
      isLoading = false;
      notifyListeners();
      return;
    }

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
          MaterialPageRoute(builder: (_) => OTPVerificationScreen()),
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<bool> isLoggedIn() async {
    var currentUser = _auth.currentUser;

    if (currentUser != null) {
      await repository.getUserID(currentUser.phoneNumber.toString());
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

  String userID() {
    return _auth.currentUser!.phoneNumber.toString();
  }
}
