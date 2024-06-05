import 'package:flutter/material.dart';
import 'TruckListPage.dart';
import 'map.dart';

void main() {
  runApp(TruckItApp());
}

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

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TruckIt'),
        backgroundColor: const Color(0xFF1C1C1E),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TruckListPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: MapScreen(),
          ),
        ],
      ),
    );
  }
}
