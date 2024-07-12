import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Location _locationController = Location();
  final Completer<GoogleMapController> _mapController = Completer<GoogleMapController>();
  LatLng? _currentPosition;
  Set<Marker> _markers = {};
  late DatabaseReference _truckLocationsRef;
  late StreamSubscription<DatabaseEvent> _truckLocationsSubscription;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndLocationServices();
    _initializeFirebaseDatabase();
  }

  @override
  void dispose() {
    _truckLocationsSubscription.cancel();
    super.dispose();
  }

  Future<void> _initializeFirebaseDatabase() async {
    _truckLocationsRef = FirebaseDatabase.instance.ref().child('truck_locations');
    _truckLocationsSubscription = _truckLocationsRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        _updateTruckMarkers(data);
      }
    });
  }

  void _updateTruckMarkers(Map<dynamic, dynamic> data) {
    final markers = <Marker>{};
    data.forEach((companyId, trucks) {
      trucks.forEach((truckId, location) {
        final lat = location['latitude'];
        final lng = location['longitude'];
        final marker = Marker(
          markerId: MarkerId(truckId),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: 'Truck $truckId',
            snippet: 'Tap to navigate',
            onTap: () {
              _showNavigationDialog(LatLng(lat, lng));
            },
          ),
        );
        markers.add(marker);
      });
    });
    setState(() {
      _markers = markers;
    });
  }

  Future<void> _loadMapStyle(GoogleMapController controller) async {
    final String mapStyle = '''
    [
      {
        "featureType": "poi.business",
        "stylers": [
          {
            "visibility": "off"
          }
        ]
      }
    ]
    '''; // Add your custom style JSON here if you have additional styles

    await controller.setMapStyle(mapStyle);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentPosition == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Padding(
              padding: const EdgeInsets.only(bottom: 16.0), // Adding some padding at the bottom
              child: GoogleMap(
                onMapCreated: (GoogleMapController controller) {
                  _mapController.complete(controller);
                  _loadMapStyle(controller); // Apply the map style when the map is created
                },
                initialCameraPosition: CameraPosition(
                  target: _currentPosition!,
                  zoom: 15,
                ),
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                markers: _markers,
              ),
            ),
    );
  }

  Future<void> _checkPermissionsAndLocationServices() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await _locationController.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationController.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await _locationController.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationController.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    LocationData locationData = await _locationController.getLocation();
    setState(() {
      _currentPosition = LatLng(locationData.latitude!, locationData.longitude!);
    });
  }

  void _showNavigationDialog(LatLng destination) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Navigate to Destination'),
          content: Text('Do you want to navigate to this destination?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Yes'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _launchGoogleMapsNavigation(destination); // Await the async call and add logging
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchGoogleMapsNavigation(LatLng destination) async {
    try {
      final String googleMapsUrl = 'https://www.google.com/maps/dir/?api=1&destination=${destination.latitude},${destination.longitude}&travelmode=driving';
      final Uri url = Uri.parse(googleMapsUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        _showErrorDialog();
      }
    } catch (e) {
      print('Error launching Google Maps: $e'); // Log the error
      _showErrorDialog();
    }
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text('Could not launch Google Maps for navigation.'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
