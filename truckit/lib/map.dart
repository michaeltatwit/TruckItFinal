
import 'package:flutter/material.dart'; 
import 'package:flutter_map/flutter_map.dart'; 
import 'package:latlong2/latlong.dart'; 
  
class MapScreen extends StatefulWidget { 
  const MapScreen({super.key}); 
  
  @override 
  State<MapScreen> createState() => _MapScreenState(); 
} 
  
class _MapScreenState extends State<MapScreen> { 
  final MapController controller = MapController(); 
    
  // Change as per your need 
  LatLng latLng = const LatLng(48.8584, 2.2945);  
  
  @override 
  Widget build(BuildContext context) { 
    return FlutterMap( 
      mapController: controller, 
      options: MapOptions( 
        initialCenter: latLng, 
        initialZoom: 18, 
      ), 
      children: [ 
        TileLayer( 
          urlTemplate: "https://api.mapbox.com/styles/v1/nfaro/clx1esi0j06yh01ql0vkv68bp/tiles/256/{z}/{x}/{y}?access_token=pk.eyJ1IjoibmZhcm8iLCJhIjoiY2x4MWVnenVnMDMxMTJrcHNsdmZyczV3NCJ9.j2_bdqmJcwyndmxklsdYWw",
        ), 
      ], 
    ); 
  } 
} 
