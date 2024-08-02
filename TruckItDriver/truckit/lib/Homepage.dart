import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'TruckCreationPage.dart';
import 'ProfileCreationPage.dart';
import 'MapScreen.dart';
import 'MenuCreationPage.dart';
import 'RegistrationPage.dart';
import 'main.dart';

/*
 * This file represents the main home page for drivers in the TruckIt driver application. It includes
 * functionalities for viewing, editing, and deleting trucks associated with a company. The user
 * can also navigate to other screens such as the profile creation page, menu creation page, and
 * map screen. Additionally, the user can log out from the app.
 */


// Main widget for the driver homepage
class Homepage extends StatefulWidget {
  @override
  _HomepageState createState() => _HomepageState();
}

/*
 * State class for Homepage
 * Handles fetching company ID
 * Displays list of trucks
 * Page navigation
 */
class _HomepageState extends State<Homepage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? companyId;

  @override
  void initState() {
    super.initState();
    _getCompanyId();
  }

  // Function to get the company ID of the current user
  Future<void> _getCompanyId() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        companyId = userDoc['companyId'];
      });
    }
  }

  // Function to log out the user
  Future<void> _logout() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Logout'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _auth.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => MyApp()), // Navigate back to login page
        (Route<dynamic> route) => false,
      );
    }
  }

  // Function to naviagte to the profile creation page
  Future<void> _navigateToProfileCreationPage(String truckId) async {
    final imageUrl = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileCreationPage(
          companyId: companyId!,
          truckId: truckId,
        ),
      ),
    );

    if (imageUrl != null) {
      setState(() {
        // Update the state to refresh the profile image
      });
    }
  }

  // Function to show the bottom menu for editing truck profile, menu, or deleting the truck
  void _showBottomSheet(BuildContext context, String truckId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.edit, color: Colors.white),
                title: Text('Edit Profile', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToProfileCreationPage(truckId);
                },
              ),
              ListTile(
                leading: Icon(Icons.restaurant_menu, color: Colors.white),
                title: Text('Edit Menu', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MenuCreationPage(
                        companyId: companyId!,
                        truckId: truckId,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.white),
                title: Text('Delete Truck', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteTruck(truckId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

// Build method to render the homepage UI
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Disable back navigation
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Driver Homepage',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF1C1C1E),
          actions: [
            IconButton(
              icon: Icon(Icons.logout, color: Colors.white),
              onPressed: _logout,
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1C1C1E),
        body: companyId == null
            ? Center(child: CircularProgressIndicator()) // Show loading indicator while comapny ID is null
            : Column(
                children: [
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('companies')
                          .doc(companyId)
                          .collection('trucks')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Center(child: CircularProgressIndicator()); // Show loading indicatior while data is being fetched
                        }
                        var trucks = snapshot.data!.docs;
                        return ListView.builder(
                          padding: const EdgeInsets.all(8.0),
                          itemCount: trucks.length,
                          itemBuilder: (context, index) {
                            var truck = trucks[index];
                            return FutureBuilder<DocumentSnapshot>(
                              future: truck.reference.collection('profile').doc('profile').get(),
                              builder: (context, profileSnapshot) {
                                if (!profileSnapshot.hasData) {
                                  return Center(child: CircularProgressIndicator());
                                }
                                var profileData = profileSnapshot.data?.data() as Map<String, dynamic>?;
                                var imageUrl = profileData?['imageUrl'] ?? '';
                                var description = profileData?['description'] ?? 'No description';

                                // Widget for displaying truck details
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 8.0, horizontal: 16.0),
                                  color: Color(0xFF2C2C2E),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15.0),
                                  ),
                                  child: ListTile(
                                    contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                                    leading: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        GestureDetector(
                                          onTap: () => _showBottomSheet(context, truck.id),
                                          child: CircleAvatar(
                                            backgroundImage: imageUrl.isNotEmpty
                                                ? NetworkImage(imageUrl)
                                                : null,
                                            radius: 20.0,
                                            child: imageUrl.isEmpty
                                                ? const Icon(Icons.account_circle, size: 40.0, color: Colors.white)
                                                : null,
                                          ),
                                        ),
                                        SizedBox(height: 1),
                                        GestureDetector(
                                          onTap: () => _showBottomSheet(context, truck.id),
                                          child: const Text(
                                            'Edit',
                                            style: TextStyle(
                                              color: Colors.blue,
                                              fontSize: 10.0,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    title: Text(
                                      truck['name'],
                                      style: const TextStyle(color: Colors.white),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => MapScreen(
                                            companyId: companyId!,
                                            truckId: truck.id,
                                            truckName: truck['name'],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 60.0),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TruckCreationPage(companyId: companyId!),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      child: Text('Create Truck'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // Function to confirm the deletion of a truck
  Future<void> _confirmDeleteTruck(String truckId) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Truck'),
          content: Text('Are you sure you want to delete this truck?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteTruck(truckId);
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // Function to delete a truck and its associated data
  Future<void> _deleteTruck(String truckId) async {
    // Delete all sections and items within the truck
    QuerySnapshot sectionsSnapshot = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('trucks')
        .doc(truckId)
        .collection('sections')
        .get();

    for (DocumentSnapshot section in sectionsSnapshot.docs) {
      QuerySnapshot itemsSnapshot = await section.reference.collection('items').get();
      for (DocumentSnapshot item in itemsSnapshot.docs) {
        await item.reference.delete();
      }
      await section.reference.delete();
    }

    // Delete the profile
    await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('trucks')
        .doc(truckId)
        .collection('profile')
        .doc('profile')
        .delete();

    // Delete the truck document
    await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('trucks')
        .doc(truckId)
        .delete();

    // Show a SnackBar to indicate truck has been deleted
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Truck Deleted')),
    );
  }
}
