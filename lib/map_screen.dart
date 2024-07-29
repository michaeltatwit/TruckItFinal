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

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Location _locationController = Location();
  final Completer<GoogleMapController> _mapController = Completer<GoogleMapController>();
  LatLng? _currentPosition;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Set<Marker> _markers = {};
  StreamSubscription<DatabaseEvent>? _locationSubscription;
  Map<String, String> _truckNames = {};

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndLocationServices();
    _fetchTruckNames();
    _startListeningToTruckLocations();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchTruckNames() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('companies').doc('your_company_id').collection('trucks').get();
      Map<String, String> truckNames = {};
      for (var doc in snapshot.docs) {
        truckNames[doc.id] = doc['name'];
      }
      setState(() {
        _truckNames = truckNames;
      });
    } catch (e) {
      print('Error fetching truck names: $e');
    }
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

  Future<BitmapDescriptor> _createCustomMarkerBitmap(String imagePath) async {
    final ByteData data = await rootBundle.load(imagePath);
    final Uint8List bytes = data.buffer.asUint8List();
    final img.Image? image = img.decodeImage(bytes);
    final img.Image resizedImage = img.copyResize(image!, width: 100, height: 100); // Adjust width and height as needed
    final ByteData byteData = ByteData.sublistView(Uint8List.fromList(img.encodePng(resizedImage)));
    return BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
  }

  void _updateMarkers(Map<dynamic, dynamic> data) async {
    Set<Marker> newMarkers = {};

    for (var companyId in data.keys) {
      var companyData = data[companyId];
      for (var truckId in companyData.keys) {
        var truckData = companyData[truckId];
        if (truckData != null) {
          final LatLng position = LatLng(truckData['latitude'], truckData['longitude']);
          final String truckName = _truckNames[truckId] ?? 'Truck $truckId';
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

  void _navigateToTruckProfile(String companyId, String truckId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TruckDetailPage(companyId: companyId, truckId: truckId),
      ),
    );
  }
}
