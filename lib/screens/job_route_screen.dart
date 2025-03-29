import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class JobRouteScreen extends StatefulWidget {
  final List<Map<String, dynamic>> pickups;
  final LatLng warehouseLocation;

  const JobRouteScreen(
      {super.key, required this.pickups, required this.warehouseLocation});

  @override
  _JobRouteScreenState createState() => _JobRouteScreenState();
}

class _JobRouteScreenState extends State<JobRouteScreen> {
  late GoogleMapController mapController;
  LatLng _currentLocation = const LatLng(0.0, 0.0);
  late Set<Marker> _markers;
  late Polyline _routePolyline;

  @override
  void initState() {
    super.initState();
    _markers = <Marker>{};
    _routePolyline =
        const Polyline(polylineId: PolylineId('route'), points: []);
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          // ignore: deprecated_member_use
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      _buildRoute();
    } catch (e) {
      log('Error getting location: $e');
    }
  }

  void _buildRoute() {
    List<LatLng> routePoints = [_currentLocation];
    for (var pickup in widget.pickups) {
      routePoints.add(pickup['location']);
    }
    routePoints.add(widget.warehouseLocation);

    setState(() {
      _routePolyline = Polyline(
        polylineId: const PolylineId('route'),
        points: routePoints,
        color: Colors.blue,
        width: 5,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Job Route')),
      body:
          _currentLocation.latitude == 0.0 && _currentLocation.longitude == 0.0
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                  initialCameraPosition:
                      CameraPosition(target: _currentLocation, zoom: 14),
                  onMapCreated: (GoogleMapController controller) {
                    mapController = controller;
                    _buildRoute();
                  },
                  markers: _markers
                    ..add(Marker(
                        markerId: const MarkerId('current_location'),
                        position: _currentLocation))
                    ..add(Marker(
                        markerId: const MarkerId('warehouse'),
                        position: widget.warehouseLocation))
                    ..addAll(widget.pickups.map((pickup) => Marker(
                          markerId: MarkerId('pickup_${pickup['id']}'),
                          position: pickup['location'],
                        ))),
                  polylines: {_routePolyline},
                ),
    );
  }
}
