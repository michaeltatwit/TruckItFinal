import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'TruckListPage.dart';
import 'map_screen.dart';


/*
 * This is the entry point for the TruckIt customer application. The file initializes Firebase,
 * authenticates the user anonymously, and sets up the main structure of the app.
 * The main widget is TruckItApp, which sets the theme and home page. The home page (MyHomePage)
 * contains an AppBar with a search icon button that navigates to the TruckListPage,
 * and a body that displays the map (MapPage).
 */


/* 
 * Main function that initializes the application
 * Ensures widgets are initialized, initializes Firebase,
 * authenticates the user anonymously before running the app
 */
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await _authenticateAnonymously();
  runApp(TruckItApp());
}


// Function to authenticate the user anonymously with Firebase
Future<void> _authenticateAnonymously() async {
  try {
    await FirebaseAuth.instance.signInAnonymously();
  } catch (e) {
    print('Failed to sign in anonymously: $e');
  }
}
/*
 * Main application widget
 * Sets up the theme and home page of the application
 */
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


/*
 * Homepage widget of the application
 * Contains the AppBar and the body which displays the map
 */
class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TruckIt'),
        backgroundColor: const Color(0xFF1C1C1E),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.grey[300]),
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
