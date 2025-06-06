import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:safedrive/model/user.dart';

class FireStoreRepository {
  FirebaseAuth auth = FirebaseAuth.instance;
  final userCollection = "Users";
  final FirebaseFirestore _instance = FirebaseFirestore.instance;

  Future<bool> userExist(String phone) async {
    try {
      final querySnapshot =
          await _instance
              .collection(userCollection)
              .where('phone', isEqualTo: phone)
              .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<bool> saveUser(UserAuth user) async {
    try {
      await _instance.collection(userCollection).add(UserAuth.toMap(user));
      return true;
    } catch (e) {
      return false;
    }
  }
}
