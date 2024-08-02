import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Homepage.dart';

/*
 * This file contains the implementation of the TruckCreationPage.
 * It allows users to create a new truck and save its information to Firestore.
 * The page includes a form for entering the truck name and a button to submit the form.
 */

// Main widget for the truck creation page.
class TruckCreationPage extends StatefulWidget {
  final String companyId;

  TruckCreationPage({required this.companyId});

  @override
  _TruckCreationPageState createState() => _TruckCreationPageState();
}

/*
 * State class for TruckCreationPage.
 * Manages the form field for the truck name.
 * Handles truck creation and page navigation.
 */
class _TruckCreationPageState extends State<TruckCreationPage> {
  final TextEditingController _truckNameController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /*
   * Function to create a new truck.
   * Adds a new document to the 'trucks' collection in Firestore with the entered truck name.
   */
  Future<void> _createTruck() async {
    await _firestore.collection('companies').doc(widget.companyId).collection('trucks').add({
      'name': _truckNameController.text,
    });

    Navigator.pop(context);
  }

  /*
   * Function to navigate back to the Homepage.
   * Pushed the Homepage onto the navigation stack and removes all previous routes.
   */
  void _navigateToHomePage(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => Homepage()),
      (Route<dynamic> route) => false,
    );
  }

  /*
   * Build the UI for the TruckCreationPage
   * Includes a text field for the truck name and a button to creat the truck.
   */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Truck', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1C1C1E),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => _navigateToHomePage(context),
        ),
      ),
      backgroundColor: const Color(0xFF1C1C1E),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _truckNameController,
              decoration: InputDecoration(
                labelText: 'Truck Name',
                labelStyle: TextStyle(color: Colors.white),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 16.0),
            Center(
              child: ElevatedButton(
                onPressed: _createTruck,
                child: Text('Create Truck'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
