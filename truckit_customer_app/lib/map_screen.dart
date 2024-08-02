import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image/image.dart' as img;
import 'package:url_launcher/url_launcher.dart';
import 'TruckListPage.dart';
import 'package:flutter/services.dart' show rootBundle;

/*
 * This file contains the implementation of the MapPage, which displays a map with the current
 * location of the user and the locations of food trucks. The map integrates with Google Maps,
 * uses Firebase for real-time truck location updates, and allows users to navigate to or view
 * the profile of a selected truck.
 */

// Main widget for displaying the map page
class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

/*
 * State for the MapPage widget
 * Manages the Google Map
 * Handles location permissions
 * Updates the map with real-time truck locations
 */
class _MapPageState extends State<MapPage> {
  final Location _locationController = Location();
  final Completer<GoogleMapController> _mapController = Completer<GoogleMapController>();
  LatLng? _currentPosition;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Set<Marker> _markers = {};
  StreamSubscription<DatabaseEvent>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndLocationServices();
    _startListeningToTruckLocations();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
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
    ''';

    await controller.setMapStyle(mapStyle);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: GoogleMap(
                onMapCreated: (GoogleMapController controller) {
                  _mapController.complete(controller);
                  _loadMapStyle(controller);
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

  /*
   * Check and request necessary permissions for location services
   * Ensures that the app has the required permissions to access the user's location
   */
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
  /*
   * Start listeninf to real-time updates of truck locations
   * Updates the markers on the map whenever the truck locations change in the database
   */
  void _startListeningToTruckLocations() {
    final DatabaseReference truckLocationsRef = FirebaseDatabase.instance.ref('truck_locations');

    _locationSubscription = truckLocationsRef.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        _updateMarkers(data);
      } else {
        setState(() {
          _markers.clear();
        });
      }
    });
  }

  /* 
   * Creates the custom truck icon for showing trucks on the map
   */
  Future<BitmapDescriptor> _createCustomMarkerBitmap(String imagePath) async {
    final ByteData data = await rootBundle.load(imagePath);
    final Uint8List bytes = data.buffer.asUint8List();
    final img.Image? image = img.decodeImage(bytes);
    final img.Image resizedImage = img.copyResize(image!, width: 100, height: 100);
    final ByteData byteData = ByteData.sublistView(Uint8List.fromList(img.encodePng(resizedImage)));
    return BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
  }
  
  /*
   * Update markers on the map with new truck locations
   * Iterates over the truck location data from Firebase Realtime Database and creates markers
   */
  void _updateMarkers(Map<dynamic, dynamic> data) async {
    Set<Marker> newMarkers = {};

    for (var companyId in data.keys) {
      var companyData = data[companyId];
      for (var truckId in companyData.keys) {
        var truckData = companyData[truckId];
        if (truckData != null) {
          final LatLng position = LatLng(truckData['latitude'], truckData['longitude']);
          final String truckName = await _getTruckName(companyId, truckId);
          final BitmapDescriptor markerIcon = await _createCustomMarkerBitmap('assets/image.png');
          final Marker marker = Marker(
            markerId: MarkerId('$companyId-$truckId'),
            position: position,
            icon: markerIcon,
            infoWindow: InfoWindow(
              title: truckName,
              snippet: 'Tap to navigate or view profile',
              onTap: () {
                _showNavigationOrProfileDialog(position, companyId, truckId);
              },
            ),
          );
          newMarkers.add(marker);
        }
      }
    }

    setState(() {
      _markers = newMarkers;
    });
  }

  /*
   * Fetch the name of a truck from Firestore based on company and truck IDs
   * Retreived name is to be displayed in the info window of the marker
   */
  Future<String> _getTruckName(String companyId, String truckId) async {
    try {
      DocumentSnapshot snapshot = await _firestore.collection('companies').doc(companyId).collection('trucks').doc(truckId).get();
      return snapshot['name'];
    } catch (e) {
      print('Error fetching truck name: $e');
      return 'Truck $truckId';
    }
  }

  /*
   * Show a menu to navigate to the truck location or view its profile
   */
  void _showNavigationOrProfileDialog(LatLng destination, String companyId, String truckId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Navigate or View Profile'),
          content: Text('Do you want to navigate to this destination or view the profile?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Navigate'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _launchGoogleMapsNavigation(destination);
              },
            ),
            TextButton(
              child: Text('View Profile'),
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToTruckProfile(companyId, truckId);
              },
            ),
          ],
        );
      },
    );
  }

  /*
   * Launch Google Maps for navigation to the selected truck
   * Gets URL for Google Maps and launches it, navigation to truck's location
   */
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
      print('Error launching Google Maps: $e');
      _showErrorDialog();
    }
  }

  /*
   * Show an error dialog if Google Maps fails to launch
   */
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

  /*
   * Naviagte to trucks profile page if selected in truck icon menu
   */
  void _navigateToTruckProfile(String companyId, String truckId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TruckDetailPage(companyId: companyId, truckId: truckId),
      ),
    );
  }
}
