import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:firebase_database/firebase_database.dart';

/*
 * This file contains the implementation of the MapScreen for the driver app. 
 * It displays a map using Google Maps, shows the current location of the truck,
 * and allows the driver to go live with their location updates.
 */

class MapScreen extends StatefulWidget {
  final String companyId;
  final String truckId;
  final String truckName;

  const MapScreen({Key? key, required this.companyId, required this.truckId, required this.truckName}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

/*
 * State class for MapScreen.
 * Manages Google Map, location permissions, and real-time location updates.
 */
class _MapScreenState extends State<MapScreen> {
  final Location _locationController = Location();
  final Completer<GoogleMapController> _mapController = Completer<GoogleMapController>();
  LatLng? _currentPosition;
  bool _isLive = false;
  DatabaseReference? _truckLocationRef;
  StreamSubscription<LocationData>? _locationSubscription;

  // Check and request location permissions
  @override
  void initState() {
    super.initState();
    _checkPermissionsAndLocationServices();
  }

  // Cancel location updates
  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  /*
   * Load custom map style to hide points of interest on the map.
   */
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

  /*
   * Builds the UI for the MapScreen.
   * Includes the Google Map and the "Go Live" button.
   */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.truckName),
        backgroundColor: const Color(0xFF1C1C1E),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: _currentPosition == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Stack(
              children: [
                GoogleMap(
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
                ),
                Positioned(
                  bottom: 50,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 200,
                      child: FloatingActionButton.extended(
                        onPressed: () {
                          setState(() {
                            _isLive = !_isLive;
                            if (_isLive) {
                              _startLiveLocationUpdates();
                            } else {
                              _stopLiveLocationUpdates();
                            }
                          });
                        },
                        label: Text(
                          _isLive ? 'Stop' : 'Go Live',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18
                          ),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  /*
   * Checks and requests necessary permissions for location services.
   * Ensures that the app has the required permissions to access the user's location.
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

    _locationSubscription = _locationController.onLocationChanged.listen((LocationData locationData) {
      setState(() {
        _currentPosition = LatLng(locationData.latitude!, locationData.longitude!);
      });

      if (_isLive) {
        _updateLocation(locationData);
      }
    });
  }

  /*
   * Start live location updates by setting up a reference to the truck's location in Firebase Realtime Database.
   */
  void _startLiveLocationUpdates() {
    _truckLocationRef = FirebaseDatabase.instance.ref('truck_locations/${widget.companyId}/${widget.truckId}');
    print('Started live location updates: truck_locations/${widget.companyId}/${widget.truckId}');
  }

  /*
   * Stop live location updates by removing the reference to the truck's location in Firebase Realtime Database.
   */
  void _stopLiveLocationUpdates() {
    if (_truckLocationRef != null) {
      _truckLocationRef!.remove();
      print('Stopped live location updates: truck_locations/${widget.companyId}/${widget.truckId}');
    }
  }

  /*
   * Update the truck's location in Firebase Realtime Databse.
   */
  void _updateLocation(LocationData locationData) {
    if (_truckLocationRef != null) {
      _truckLocationRef!.set({
        'latitude': locationData.latitude,
        'longitude': locationData.longitude,
        'timestamp': ServerValue.timestamp,
      }).then((_) {
        print('Location updated successfully');
      }).catchError((error) {
        print('Failed to update location: $error');
      });
    }
  }
}
