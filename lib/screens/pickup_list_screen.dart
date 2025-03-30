import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../screens/job_route_screen.dart';

class PickupListScreen extends StatelessWidget {
  final List<Map<String, dynamic>> pickups = [
    {
      "id": 1,
      "location": const LatLng(12.971598, 77.594566),
      "time_slot": "9AM-10AM",
      "inventory": 5
    },
    {
      "id": 2,
      "location": const LatLng(12.972819, 77.595212),
      "time_slot": "9AM-10AM",
      "inventory": 3
    },
    {
      "id": 3,
      "location": const LatLng(12.963842, 77.609043),
      "time_slot": "10AM-11AM",
      "inventory": 7
    },
  ];

  final LatLng warehouseLocation = const LatLng(12.961115, 77.600000);

  PickupListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pickup List')),
      body: ListView.builder(
        itemCount: pickups.length,
        itemBuilder: (context, index) {
          var pickup = pickups[index];
          return ListTile(
            title: Text('Pickup ID: ${pickup['id']}'),
            subtitle: Text(
              'Location: ${pickup["location"].latitude}, ${pickup["location"].longitude}\n'
              'Time Slot: ${pickup['time_slot']}\n'
              'Inventory Size: ${pickup['inventory']}',
              maxLines: 5,
            ),
            trailing: IconButton(
              icon: const Icon(Icons.directions),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => JobRouteScreen(
                      pickups: pickups,
                      warehouseLocation: warehouseLocation,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
