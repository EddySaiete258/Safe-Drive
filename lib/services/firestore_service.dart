import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:safedrive/model/Road_block.dart';
import 'package:safedrive/model/user.dart';

class FireStoreRepository {
  final userCollection = "Users";
  final blockCollection = "Road_blocks";
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

  Future<void> createBlock(RoadBlock roadBlock, String userId) async {
    try {
      final userRef = FirebaseFirestore.instance
          .collection(userCollection)
          .doc(userId);
      roadBlock.user = userRef;
      await _instance
          .collection(blockCollection)
          .add(RoadBlock.toMap(roadBlock));
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<String> getUserID(String phone) async {
    try {
      final querySnapshot =
          await _instance
              .collection(userCollection)
              .where('phone', isEqualTo: phone)
              .limit(1)
              .get();
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id;
      }
      throw Exception("User Not found");
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<DocumentReference<Map<String, dynamic>>?> userReference(
    String userId,
  ) async {
    return FirebaseFirestore.instance.collection(userCollection).doc(userId);
  }

  Future<QuerySnapshot> roadBlocks() async {
    return await _instance.collection(blockCollection).get();
  }

  Future<bool> deleteRoadBlock(DocumentSnapshot id) async {
    try {
      await id.reference.delete();
      return true;
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<void> uploadUserImages(List<XFile> images, String roadBlockId) async {
  List<String> downloadUrls = [];

  for (var file in images) {
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('road_block_uploads/$roadBlockId/$fileName.jpg');

    final uploadTask = await storageRef.putFile(File(file.path));
    final downloadUrl = await storageRef.getDownloadURL();
    downloadUrls.add(downloadUrl);
  }

  final roadBlockDoc = _instance.collection(blockCollection).doc(roadBlockId);

  await roadBlockDoc.set({
    'uploadedImages': FieldValue.arrayUnion(downloadUrls),
  }, SetOptions(merge: true));

  print('✅ Uploaded ${downloadUrls.length} images and linked to user $roadBlockId');
}

}
