import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:safedrive/model/Road_block.dart';
import 'package:safedrive/providers/auth_provider.dart';
import 'package:safedrive/services/firestore_service.dart';
import 'package:safedrive/services/preferences.dart';
import 'package:safedrive/utils/custom_snackbar.dart';
import 'package:http/http.dart' as http;

class RoadBlockProvider extends ChangeNotifier {
  final repository = FireStoreRepository();
  List<RoadBlock> roadBlocks = [];
  bool isLoading = false;
  Set<Marker> markers = {};
  LatLng? selectedLatLng;

  createRoadBlock(
    context,
    RoadBlock roadBlock,
    String phone,
    List<File> photos,
  ) async {
    isLoading = true;
    notifyListeners();
    try {
      String? userId = Preference.getUserId();
      userId ??= await repository.getUserID(phone);
      List<String> images = await uploadMultipleImages(photos);
      roadBlock.images = images;
      await repository.createBlock(roadBlock, userId);
      selectedLatLng = null;
      fetchRoadBlocks(context);
      customSnackBar(context, 'Bloqueio criado com sucesso');
    } catch (e) {
      print("error:: ${e.toString()}");
      isLoading = false;
      notifyListeners();
      customSnackBar(context, 'Erro: ${e.toString()}', isError: true);
    }
  }

  Future fetchRoadBlocks(context) async {
    isLoading = true;
    notifyListeners();
    try {
      BitmapDescriptor roadblockIcon = await BitmapDescriptor.asset(
        ImageConfiguration(size: Size(48, 48)), // Adjust size as needed
        'assets/images/roadblock.png',
      );
      QuerySnapshot data = await repository.roadBlocks();
      for (DocumentSnapshot doc in data.docs) {
        var block = doc.data() as Map<String, dynamic>;
        RoadBlock newRoadblock = RoadBlock.fromMap(block);
        roadBlocks.add(newRoadblock);
        AuthProviderLocal authProvider = Provider.of<AuthProviderLocal>(
          context,
          listen: false,
        );
        String? userId = Preference.getUserId();
        userId ??= await repository.getUserID(authProvider.userID());
        DocumentReference<Map<String, dynamic>>? userRef = await repository
            .userReference(userId);
        bool canEdit = newRoadblock.user == userRef ? true : false;

        Marker newMarker = Marker(
          markerId: MarkerId(newRoadblock.markerId),
          position: LatLng(
            double.parse(newRoadblock.latitude),
            double.parse(newRoadblock.longitude),
          ),
          icon: roadblockIcon,
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder:
                  (context) => Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: StatefulBuilder(
                      builder:
                          (context, setModalState) => Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(30),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 15,
                                  spreadRadius: 5,
                                  offset: const Offset(0, -3),
                                ),
                              ],
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Bloqueio',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),

                                      IconButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        icon: Icon(Icons.close),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  TextFormField(
                                    initialValue: newRoadblock.location,
                                    decoration: const InputDecoration(
                                      labelText: 'Localização',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.location_on),
                                    ),
                                    enabled: false,
                                  ),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    decoration: const InputDecoration(
                                      labelText: 'Tipo de Bloqueio',
                                      border: OutlineInputBorder(),
                                    ),
                                    maxLines: 3,
                                    enabled: false,
                                    initialValue: newRoadblock.type,
                                  ),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    decoration: const InputDecoration(
                                      labelText: 'Descrição',
                                      border: OutlineInputBorder(),
                                    ),
                                    maxLines: 3,
                                    enabled: false,
                                    initialValue: newRoadblock.description,
                                  ),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    decoration: const InputDecoration(
                                      labelText: 'Duração Estimada',
                                      border: OutlineInputBorder(),
                                    ),
                                    maxLines: 3,
                                    enabled: false,
                                    initialValue: newRoadblock.duration,
                                  ),

                                  if (newRoadblock.images != null &&
                                      newRoadblock.images!.isNotEmpty) ...{
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 10,
                                      children:
                                          newRoadblock.images!.map((file) {
                                            return GestureDetector(
                                              onTap: () {
                                                showDialog(
                                                  context: context,
                                                  builder:
                                                      (_) => Dialog(
                                                        backgroundColor:
                                                            Colors.transparent,
                                                        insetPadding:
                                                            EdgeInsets.all(10),
                                                        child: GestureDetector(
                                                          onTap:
                                                              () => Navigator.pop(
                                                                context,
                                                              ), // toca para fechar
                                                          child: InteractiveViewer(
                                                            child: CachedNetworkImage(
                                                              imageUrl: file,
                                                              fit:
                                                                  BoxFit
                                                                      .contain,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                );
                                              },
                                              child: SizedBox(
                                                height: 80,
                                                width: 80,
                                                child: CachedNetworkImage(
                                                  imageUrl: file,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                    ),
                                  },
                                  const SizedBox(height: 20),
                                  if (canEdit) ...{
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor: Colors.red,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                          horizontal: 24,
                                        ),
                                        minimumSize: const Size(
                                          double.infinity,
                                          50,
                                        ),
                                      ),
                                      icon: const Icon(Icons.close),
                                      label: const Text("Apagar"),
                                      onPressed: () async {
                                        await Provider.of<RoadBlockProvider>(
                                          context,
                                          listen: false,
                                        ).deleteRoadBlock(context, doc);
                                        // ignore: use_build_context_synchronously
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  },
                                ],
                              ),
                            ),
                          ),
                    ),
                  ),
            );
          },
        );
        markers.add(newMarker);
      }
      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<RoadBlock?> findRoadBlock(LatLng postion) async {
    try {
      Marker marker = markers.firstWhere(
        (marker) => marker.position == postion,
      );
      if (marker.markerId.value.isNotEmpty) {
        return roadBlocks.firstWhere(
          (block) => MarkerId(block.markerId) == marker.markerId,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  addTemporaryMarker(context, Marker tempMarker) {
    try {
      markers.add(tempMarker);
      notifyListeners();
    } catch (e) {
      customSnackBar(context, "Nao foi possivel marcar a area selecionada");
      notifyListeners();
    }
  }

  removeMarker(context, MarkerId id) {
    try {
      markers.removeWhere((marker) => marker.markerId == id);
      selectedLatLng = null;
      notifyListeners();
    } catch (e) {
      customSnackBar(context, "Nao foi possivel remover o marcador");
      notifyListeners();
    }
  }

  deleteRoadBlock(context, DocumentSnapshot id) async {
    isLoading = true;
    notifyListeners();
    try {
      await repository.deleteRoadBlock(id);
      customSnackBar(context, "Bloqueio apagado com sucesso");
      isLoading = false;
      fetchRoadBlocks(context);
    } catch (e) {
      customSnackBar(
        context,
        "Nao foi possivel remover o bloqueio tente mais tarde",
        isError: true,
      );
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> uploadToCloudinary(Uint8List imageBytes) async {
    const cloudName = 'ddizbueff';
    const uploadPreset = 'upload_preset';

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request =
        http.MultipartRequest('POST', uri)
          ..fields['upload_preset'] = uploadPreset
          ..files.add(
            http.MultipartFile.fromBytes(
              'file',
              imageBytes,
              filename: 'image.jpg',
            ),
          );

    final response = await request.send();

    if (response.statusCode == 200) {
      final resBody = await response.stream.bytesToString();
      final data = json.decode(resBody);
      print(data['secure_url'].toString());
      return data['secure_url'];
    }

    return null;
  }

  Future<List<Uint8List>> convertFilesToBytes(List<File> photos) async {
    List<Uint8List> bytesList = [];

    for (File file in photos) {
      Uint8List bytes = await file.readAsBytes();
      bytesList.add(bytes);
    }

    return bytesList;
  }

  Future<List<String>> uploadMultipleImages(List<File> photos) async {
    List<String> uploadedUrls = [];
    List<Uint8List> imagesBytesList = await convertFilesToBytes(photos);
    for (var bytes in imagesBytesList) {
      final url = await uploadToCloudinary(bytes);
      if (url != null) {
        uploadedUrls.add(url);
      }
    }

    return uploadedUrls;
  }
}
