import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
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

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndLocationServices();
  }

  /// Loads the custom map style.
  Future<void> _loadMapStyle(GoogleMapController controller) async {
    final String mapStyleId = 'f0710ee8169c5348';
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
                  _addMarkers(); // Add markers when the map is created
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

  /// Checks permissions and enables location services if necessary.
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

  /// Adds markers to the map.
  void _addMarkers() {
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId('marker_1'),
          position: LatLng(_currentPosition!.latitude + 0.01, _currentPosition!.longitude + 0.01),
          infoWindow: InfoWindow(
            title: 'Destination',
            snippet: 'Tap to navigate',
            onTap: () {
              _showNavigationDialog(LatLng(_currentPosition!.latitude + 0.01, _currentPosition!.longitude + 0.01));
            },
          ),
        ),
      );
    });
  }

  /// Shows a dialog to confirm navigation to the destination.
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

  /// Launches Google Maps navigation to the specified destination.
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

  /// Shows an error dialog if navigation fails.
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
