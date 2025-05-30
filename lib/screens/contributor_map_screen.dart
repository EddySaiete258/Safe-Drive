import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';


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
  Stream<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
  }

  void _startLocationUpdates() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;

    final settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 15,
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: settings);
    _positionStream!.listen((position) {
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
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("O ponto selecionado está um pouco distante. Tente marcar mais próximo da sua localização (200m)."),
          backgroundColor: Colors.orangeAccent,
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
    final placemark = placemarks.first;
    address = '${placemark.street}, ${placemark.subLocality}, ${placemark.locality}';
  }

  final _formKey = GlobalKey<FormState>();
  String? _selectedType;
  String? _description;
  String? _duration;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
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
          child: Form(
            key: _formKey,
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
                  onChanged: (value) {
                    address = value;
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Bloqueio',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    'Acidente',
                    'Obra',
                    'Manifestação',
                    'Inundação',
                    'Outro',
                  ].map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    _selectedType = value;
                  },
                  validator: (value) =>
                      value == null ? 'Selecione o tipo de bloqueio' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Descrição (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onChanged: (value) {
                    _description = value;
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Duração Estimada',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    '< 1h',
                    '1–3h',
                    '3–6h',
                    '> 6h',
                  ].map((duration) {
                    return DropdownMenuItem(
                      value: duration,
                      child: Text(duration),
                    );
                  }).toList(),
                  onChanged: (value) {
                    _duration = value;
                  },
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
                      Navigator.of(context).pop();
                      setState(() {
                        _temporaryMarker = null;
                        _selectedLatLng = null;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentLatLng == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
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
              markers: _temporaryMarker != null ? {_temporaryMarker!} : {},
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _selectedLatLng != null
            ? const Color(0xFF4CE5B1)
            : Colors.grey,
        onPressed: _selectedLatLng != null ? _openBlockForm : null,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
