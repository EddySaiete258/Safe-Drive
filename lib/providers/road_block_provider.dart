import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:safedrive/model/Road_block.dart';
import 'package:safedrive/services/firestore_service.dart';
import 'package:safedrive/services/preferences.dart';
import 'package:safedrive/utils/custom_snackbar.dart';

class RoadBlockProvider extends ChangeNotifier {
  final repository = FireStoreRepository();
  List<RoadBlock> roadBlocks = [];
  bool isLoading = false;
  Set<Marker> markers = {};
  LatLng? selectedLatLng;

  createRoadBlock(context, RoadBlock roadBlock, String phone) async {
    try {
      String? userId = Preference.getUserId();
      print("USER ID: $userId");
      await repository.createBlock(roadBlock, userId!);
      isLoading = false;
      notifyListeners();
      customSnackBar(context, 'Bloqueio criado com sucesso');
    } catch (e) {
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
                                  const Text(
                                    'Bloqueio',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
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

                                  // const SizedBox(height: 10),
                                  // Wrap(
                                  //   spacing: 10,
                                  //   children:
                                  //       _photos.map((file) {
                                  //         return Stack(
                                  //           children: [
                                  //             Image.file(
                                  //               file,
                                  //               width: 80,
                                  //               height: 80,
                                  //               fit: BoxFit.cover,
                                  //             ),
                                  //             Positioned(
                                  //               right: 0,
                                  //               top: 0,
                                  //               child: GestureDetector(
                                  //                 onTap: () {
                                  //                   setModalState(
                                  //                     () => _photos.remove(file),
                                  //                   );
                                  //                 },
                                  //                 child: const CircleAvatar(
                                  //                   radius: 12,
                                  //                   backgroundColor: Colors.red,
                                  //                   child: Icon(
                                  //                     Icons.close,
                                  //                     size: 14,
                                  //                     color: Colors.white,
                                  //                   ),
                                  //                 ),
                                  //               ),
                                  //             ),
                                  //           ],
                                  //         );
                                  //       }).toList(),
                                  // ),
                                  const SizedBox(height: 20),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: const Color(0xFF4CE5B1),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
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
                                    label: const Text("Fechar"),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                    ),
                  ),
            );
          },
        );
        print("FETCHED MARKER: ${newMarker.toString()}");
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
      print("POSITION: ${postion.toString()}");
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
}
