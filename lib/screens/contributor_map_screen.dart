import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import 'package:safedrive/providers/auth_provider.dart';
import 'package:safedrive/utils/image_utils.dart';
import 'dart:async';

class ContributorMapScreen extends StatefulWidget {
  const ContributorMapScreen({super.key});

  @override
  State<ContributorMapScreen> createState() => _ContributorMapScreenState();
}

class _ContributorMapScreenState extends State<ContributorMapScreen> {
  static const double bloqueioRaioMax = 200;

  GoogleMapController? _mapController;
  LatLng? _currentLatLng;
  LatLng? _selectedLatLng;
  Marker? _temporaryMarker;
  late StreamSubscription<Position> _positionSubscription;
  Set<Marker> _markerSet = {};

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
  }

  void _startLocationUpdates() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever)
      return;

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
      setState(() {
        _selectedLatLng = latLng;
        _temporaryMarker = Marker(
          markerId: const MarkerId('temporary_marker'),
          position: latLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        );
        _markerSet.add(_temporaryMarker!);
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

  void _openBlockForm() async {
    if (_selectedLatLng == null) return;

    List<Placemark> placemarks = await placemarkFromCoordinates(
      _selectedLatLng!.latitude,
      _selectedLatLng!.longitude,
    );

    String address = '';
    if (placemarks.isNotEmpty) {
      final p = placemarks.first;
      address = '${p.street}, ${p.subLocality}, ${p.locality}';
    }

    final _formKey = GlobalKey<FormState>();
    String? _selectedType;
    String? _description;
    String? _duration;
    final List<File> _photos = [];

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
                    child: Form(
                      key: _formKey,
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
                              onChanged: (value) => _selectedType = value,
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
                              onChanged: (value) => _description = value,
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
                              onChanged: (value) => _duration = value,
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final file = await pickAndCompressImage();
                                    if (file != null) {
                                      setModalState(() => _photos.add(file));
                                    }
                                  },
                                  icon: const Icon(Icons.camera_alt),
                                  label: const Text("Adicionar Foto"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4CE5B1),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text("${_photos.length} imagem(ns)"),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              children:
                                  _photos.map((file) {
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
                                                () => _photos.remove(file),
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
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  setState(() {
                                    _temporaryMarker = null;
                                    _selectedLatLng = null;
                                  });
                                  Navigator.of(context).pop();
                                  // Future.delayed(
                                  //   Duration(milliseconds: 300),
                                  //   () {
                                  //     setState(() {
                                  //       _temporaryMarker = null;
                                  //       _selectedLatLng = null;
                                  //     });
                                  //   },
                                  // );
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
                child: GoogleMap(
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
                  markers: _markerSet.isNotEmpty ? _markerSet : {},
                ),
              ),
      floatingActionButton: FloatingActionButton(
        backgroundColor:
            _selectedLatLng != null ? const Color(0xFF4CE5B1) : Colors.grey,
        onPressed: _selectedLatLng != null ? _openBlockForm : null,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
