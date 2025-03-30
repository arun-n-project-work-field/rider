import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

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
  late LatLng _currentLocation;
  late Set<Marker> _markers;
  late Polyline _routePolyline;

  final PolylinePoints polylinePoints = PolylinePoints();

  @override
  void initState() {
    super.initState();
    _currentLocation = const LatLng(0.0, 0.0);
    _markers = <Marker>{};
    _routePolyline =
        const Polyline(polylineId: PolylineId('route'), points: []);
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        // ignore: deprecated_member_use
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });
    _getOptimizedRoute();
  }

  Future<void> _getOptimizedRoute() async {
    final origin = _currentLocation;
    final destination = widget.warehouseLocation;
    final waypoints = widget.pickups
        .map((pickup) =>
            '${pickup['location'].latitude},${pickup['location'].longitude}')
        .join('|');

    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&waypoints=optimize:true|$waypoints&key=AIzaSyDaswwoWSpQz3ReR1mqjlZ4CpVz5HcuIZc';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        _parseRoute(data);
      } else {
        log('Error fetching route: ${data['status']}');
      }
    } else {
      log('Failed to fetch route');
    }
  }

  void _parseRoute(Map<String, dynamic> data) {
    final routes = data['routes'];
    if (routes.isNotEmpty) {
      final route = routes[0];
      final polyline = route['overview_polyline']['points'];

      List<PointLatLng> decodedPoints = polylinePoints.decodePolyline(polyline);
      List<LatLng> routePoints = decodedPoints
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();

      setState(() {
        _routePolyline = Polyline(
          polylineId: const PolylineId('route'),
          points: routePoints,
          color: Colors.blue,
          width: 5,
        );

        _markers.clear();

        _markers.add(Marker(
          markerId: const MarkerId('start'),
          position: _currentLocation,
          infoWindow:
              const InfoWindow(title: 'Start', snippet: 'Rider\'s location'),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ));

        _markers.add(Marker(
          markerId: const MarkerId('end'),
          position: widget.warehouseLocation,
          infoWindow:
              const InfoWindow(title: 'Warehouse', snippet: 'Destination'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ));

        for (int i = 0; i < widget.pickups.length; i++) {
          var pickup = widget.pickups[i];
          _markers.add(Marker(
            markerId: MarkerId('pickup_${pickup['id']}'),
            position: pickup['location'],
            infoWindow: InfoWindow(
              title: 'Waypoint ${i + 1}',
              snippet: 'Inventory: ${pickup['inventory']}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange),
          ));
        }
      });
    }
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
                  },
                  markers: _markers,
                  polylines: {_routePolyline},
                ),
    );
  }
}
