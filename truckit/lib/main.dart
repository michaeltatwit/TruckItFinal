import 'package:flutter/material.dart';
import 'TruckListPage.dart';

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TruckIt'),
        backgroundColor: Colors.orange,
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
      body: Center(
        
      ),
    );
  }
}
