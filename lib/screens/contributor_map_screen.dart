import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class ContributorMapScreen extends StatefulWidget {
  const ContributorMapScreen({super.key});

  @override
  State<ContributorMapScreen> createState() => _ContributorMapScreenState();
}

class _ContributorMapScreenState extends State<ContributorMapScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentLatLng;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied)
      return;

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentLatLng = LatLng(position.latitude, position.longitude);
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_currentLatLng!, 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                ),
              ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4CE5B1),
        onPressed: () {
          // abrir formulário de novo bloqueio
          showDataDetailsModal(context, () {});
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void showDataDetailsModal(BuildContext context, VoidCallback onDelete) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.5,
            minChildSize: 0.4,
            maxChildSize: 0.85,
            builder:
                (_, controller) => Container(
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
                        offset: Offset(0, -3),
                      ),
                    ],
                  ),
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
                      Text(
                        'Novo bloqueio',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // TODO: Adicionar os campos aqui

                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Color(0xFF4CE5B1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 24,
                          ),
                          minimumSize: Size(double.infinity, 50),
                        ),
                        label: Text("Submeter"),
                        onPressed: () {
                          Navigator.of(context).pop(); // Close modal first
                          onDelete(); // Trigger deletion
                        },
                      ),
                    ],
                  ),
                ),
          ),
    );
  }
}
