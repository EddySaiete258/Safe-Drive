import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class NavigationMapScreen extends StatefulWidget {
  const NavigationMapScreen({super.key});

  @override
  State<NavigationMapScreen> createState() => _NavigationMapScreenState();
}

class _NavigationMapScreenState extends State<NavigationMapScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentLatLng;
  LatLng? _destinationLatLng;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  late StreamSubscription<Position> _positionSubscription;

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
  }

  void _startLocationUpdates() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) return;

    final settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen((position) {
      final newLatLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentLatLng = newLatLng;
      });
      _mapController?.animateCamera(CameraUpdate.newLatLng(newLatLng));
    });
  }

  void _onMapTap(LatLng latLng) async {
    if (_currentLatLng == null) return;

    setState(() {
      _destinationLatLng = latLng;
      _markers = {
        Marker(
          markerId: const MarkerId('destino'),
          position: latLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      };
    });

    await _fetchRoute();
  }

  Future<void> _fetchRoute() async {
    if (_currentLatLng == null || _destinationLatLng == null) return;

    final origin = '${_currentLatLng!.latitude},${_currentLatLng!.longitude}';
    final destination =
        '${_destinationLatLng!.latitude},${_destinationLatLng!.longitude}';

    const apiKey = 'AIzaSyCSAsD5WrWQw7cwVbARdBwOG6N5o43txSU';
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$apiKey');

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['routes'] != null && data['routes'].isNotEmpty) {
        final route = data['routes'][0];
        final points = route['overview_polyline']['points'];

        final polylinePoints = PolylinePoints().decodePolyline(points);
        final polylineCoordinates = polylinePoints
            .map((e) => LatLng(e.latitude, e.longitude))
            .toList();

        setState(() {
          _polylines = {
            Polyline(
              polylineId: const PolylineId('rota'),
              points: polylineCoordinates,
              color: Colors.blue,
              width: 5,
            ),
          };
        });
      }
    }
  }

  @override
  void dispose() {
    _positionSubscription.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentLatLng == null
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
                onTap: _onMapTap,
                markers: _markers,
                polylines: _polylines,
              ),
            ),
    );
  }
}
