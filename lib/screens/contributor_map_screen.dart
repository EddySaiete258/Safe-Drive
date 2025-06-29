import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import 'package:safedrive/model/Road_block.dart';
import 'package:safedrive/providers/auth_provider.dart';
import 'package:safedrive/providers/road_block_provider.dart';
import 'package:safedrive/utils/image_utils.dart';
import 'dart:async';

import 'package:uuid/uuid.dart';

class ContributorMapScreen extends StatefulWidget {
  const ContributorMapScreen({super.key});

  @override
  State<ContributorMapScreen> createState() => _ContributorMapScreenState();
}

class _ContributorMapScreenState extends State<ContributorMapScreen> {
  static const double bloqueioRaioMax = 200;
  String? userPhone;
  GoogleMapController? _mapController;
  LatLng? _currentLatLng;
  Marker? _temporaryMarker;
  late StreamSubscription<Position> _positionSubscription;

  @override
  void initState() {
    super.initState();
    // inicialize os providers do contexto
    _startLocationUpdates();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AuthProviderLocal>(context, listen: false);
      userPhone = provider.userID();
      final roadProvider = Provider.of<RoadBlockProvider>(
        context,
        listen: false,
      );
      roadProvider.fetchRoadBlocks(context);
    });
  }

  void _startLocationUpdates() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    final settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 15,
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen((position) {
      final newLatLng = LatLng(position.latitude, position.longitude);
      setState(() => _currentLatLng = newLatLng);
      _mapController?.animateCamera(CameraUpdate.newLatLng(newLatLng));
    });
  }

  void _onMapLongPress(LatLng latLng) async {
    if (_currentLatLng == null) return;

    double distancia = Geolocator.distanceBetween(
      _currentLatLng!.latitude,
      _currentLatLng!.longitude,
      latLng.latitude,
      latLng.longitude,
    );

    if (distancia <= bloqueioRaioMax) {
      var uuid = Uuid();
      final markerId = "${userPhone!}-${uuid.v4()}";
      final roadBlockProvider = Provider.of<RoadBlockProvider>(
        context,
        listen: false,
      );
      setState(() {
        Provider.of<RoadBlockProvider>(context, listen: false).selectedLatLng =
            latLng;
        _temporaryMarker = Marker(
          markerId: MarkerId(markerId),
          position: latLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          onTap: () {
            roadBlockProvider.removeMarker(context, MarkerId(markerId));
          },
        );
        roadBlockProvider.addTemporaryMarker(context, _temporaryMarker!);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "O ponto selecionado está muito distante. Marque mais próximo (200m).",
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<bool> _openBlockForm() async {
    if (Provider.of<RoadBlockProvider>(context, listen: false).selectedLatLng ==
        null) {
      return false;
    }

    List<Placemark> placemarks = await placemarkFromCoordinates(
      Provider.of<RoadBlockProvider>(
        context,
        listen: false,
      ).selectedLatLng!.latitude,
      Provider.of<RoadBlockProvider>(
        context,
        listen: false,
      ).selectedLatLng!.longitude,
    );

    String address = '';
    if (placemarks.isNotEmpty) {
      final p = placemarks.first;
      address = '${p.street}, ${p.subLocality}, ${p.locality}';
    }

    final formKey = GlobalKey<FormState>();
    String selectedType = "Acidente";
    String? description;
    String? duration;
    final List<File> photos = [];

    final result = await showModalBottomSheet<bool>(
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
                    child: Form(
                      key: formKey,
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
                              'Novo Bloqueio',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              initialValue: address,
                              decoration: const InputDecoration(
                                labelText: 'Localização',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.location_on),
                              ),
                              onChanged: (value) => address = value,
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Tipo de Bloqueio',
                                border: OutlineInputBorder(),
                              ),
                              items:
                                  [
                                        'Acidente',
                                        'Obra',
                                        'Manifestação',
                                        'Inundação',
                                        'Outro',
                                      ]
                                      .map(
                                        (type) => DropdownMenuItem(
                                          value: type,
                                          child: Text(type),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (value) => selectedType = value!,
                              validator:
                                  (value) =>
                                      value == null
                                          ? 'Selecione o tipo de bloqueio'
                                          : null,
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Descrição (opcional)',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                              onChanged: (value) => description = value,
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Duração Estimada',
                                border: OutlineInputBorder(),
                              ),
                              items:
                                  ['< 1h', '1–3h', '3–6h', '> 6h']
                                      .map(
                                        (d) => DropdownMenuItem(
                                          value: d,
                                          child: Text(d),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (value) => duration = value,
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final file = await pickAndCompressImage();
                                    if (file != null) {
                                      setModalState(() => photos.add(file));
                                    }
                                  },
                                  icon: const Icon(Icons.camera_alt),
                                  label: const Text("Adicionar Foto"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4CE5B1),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text("${photos.length} imagem(ns)"),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              children:
                                  photos.map((file) {
                                    return Stack(
                                      children: [
                                        Image.file(
                                          file,
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                        ),
                                        Positioned(
                                          right: 0,
                                          top: 0,
                                          child: GestureDetector(
                                            onTap: () {
                                              setModalState(
                                                () => photos.remove(file),
                                              );
                                            },
                                            child: const CircleAvatar(
                                              radius: 12,
                                              backgroundColor: Colors.red,
                                              child: Icon(
                                                Icons.close,
                                                size: 14,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                            ),
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
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              icon: const Icon(Icons.check),
                              label: const Text("Reportar"),
                              onPressed: () async {
                                RoadBlockProvider blockProvider =
                                    Provider.of<RoadBlockProvider>(
                                      context,
                                      listen: false,
                                    );
                                if (formKey.currentState!.validate()) {
                                  RoadBlock roadBlock = RoadBlock(
                                    null,
                                    blockProvider.selectedLatLng!.latitude
                                        .toString(),
                                    blockProvider.selectedLatLng!.longitude
                                        .toString(),
                                    description,
                                    address,
                                    selectedType,
                                    duration!,
                                    _temporaryMarker!.markerId.value,
                                    null,
                                  );
                                  await blockProvider.createRoadBlock(
                                    context,
                                    roadBlock,
                                    userPhone!,
                                    photos,
                                  );
                                  setState(() {
                                    _temporaryMarker = null;
                                  });
                                  Navigator.of(context).pop(true);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
            ),
          ),
    );
    return result == true;
  }

  @override
  void dispose() {
    _positionSubscription.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProviderLocal>(context, listen: false);
    final roadBlockProvider = Provider.of<RoadBlockProvider>(
      context,
      listen: true,
    );

    if (Provider.of<AuthProviderLocal>(context, listen: true).isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF4CE5B1)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(backgroundColor: Color(0xFF4CE5B1)),
      drawer: Drawer(
        backgroundColor: Color(0xFF4CE5B1),
        child: ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Safedrive', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),

            ListTile(
              title: Text(
                'Sair',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              leading: Icon(Icons.logout, color: Colors.white),
              onTap: () async {
                Navigator.pop(context);
                await authProvider.logout(context);
              },
            ),
          ],
        ),
      ),
      body:
          _currentLatLng == null
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                child: Consumer<RoadBlockProvider>(
                  builder: (context, provider, _) {
                    return provider.isLoading ? Center(child: CircularProgressIndicator(),) : GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _currentLatLng!,
                        zoom: 16,
                      ),
                      onMapCreated: (controller) => _mapController = controller,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      zoomControlsEnabled: false,
                      trafficEnabled: true,
                      onLongPress: _onMapLongPress,
                      markers:
                          provider.markers.isNotEmpty ? provider.markers : {},
                    );
                  },
                ),
              ),
      floatingActionButton: FloatingActionButton(
        backgroundColor:
            roadBlockProvider.selectedLatLng != null
                ? const Color(0xFF4CE5B1)
                : Colors.grey,
        onPressed:
            roadBlockProvider.selectedLatLng != null
                ? () async {
                  final created = await _openBlockForm();
                  if (created && context.mounted) {
                    await Provider.of<RoadBlockProvider>(
                      context,
                      listen: false,
                    ).fetchRoadBlocks(context);
                    setState(() {});
                  }
                }
                : null,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
