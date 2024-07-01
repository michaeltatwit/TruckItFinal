import 'package:flutter/material.dart';
import 'package:truckit_customer_app/map_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'TruckListPage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(TruckItApp());
}

/// The main entry point of the TruckIt application.
class TruckItApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TruckIt',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: MyHomePage(),
    );
  }
}

/// The main page of the TruckIt application.
class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TruckIt'),
        backgroundColor: const Color(0xFF1C1C1E),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.grey[300]), // Change icon color to a lighter gray
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TruckListPage()),
              );
            },
          ),
        ],
      ),
      body: MapPage(),
    );
  }
}
