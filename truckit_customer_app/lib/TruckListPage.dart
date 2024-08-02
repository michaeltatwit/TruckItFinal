import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

/*
 * This file defines the TruckListPage widget, which displays a list of food trucks. 
 * It includes functionalities for searching, filtering, and sorting the list of trucks,
 * as well as showing the live status of each truck. The list updates dynamically based on real-time data.
 */

/*
 * Main widget for displaying the truck list page
 */
class TruckListPage extends StatefulWidget {
  @override
  _TruckListPageState createState() => _TruckListPageState();
}

/*
 * State class for TruckListPage widget
 * Manages the state of the search query, selected filters, and live statuses
 */
class _TruckListPageState extends State<TruckListPage> {
  String searchQuery = '';
  String selectedFoodType = 'All';
  String selectedSortOption = 'Alphabetical';

  // Gets the live statuses of trucks from the Firebase Realtime Database
  Stream<Map<String, bool>> getLiveStatuses() {
  return FirebaseDatabase.instance.ref('truck_locations').onValue.map((event) {
    Map<String, bool> liveStatuses = {};
    if (event.snapshot.value != null) {
      (event.snapshot.value as Map).forEach((companyId, trucks) {
        (trucks as Map).forEach((truckId, _) {
          liveStatuses['$companyId/$truckId'] = true;
        });
      });
    }
    return liveStatuses;
  });
}

  /*
   * Build method for the truck list page
   * Creates all objects showed in the truck list page
   */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('List of Trucks'),
        backgroundColor: const Color(0xFF1C1C1E),
        iconTheme: const IconThemeData(
          color: Color.fromARGB(255, 216, 255, 206),
        ),
      ),
      backgroundColor: const Color(0xFF1C1C1E),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Theme(
              data: ThemeData(
                primaryColor: Color.fromARGB(255, 216, 255, 206),
                textSelectionTheme: TextSelectionThemeData(
                  cursorColor: Color.fromARGB(255, 216, 255, 206),
                  selectionColor: Color.fromARGB(255, 216, 255, 206).withOpacity(0.5),
                  selectionHandleColor: Color.fromARGB(255, 216, 255, 206),
                ),
                colorScheme: ColorScheme.fromSwatch().copyWith(
                  primary: Color.fromARGB(255, 216, 255, 206),
                ),
              ),
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Search',
                  labelStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[700]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color.fromARGB(255, 216, 255, 206), width: 2.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  filled: true,
                  fillColor: Colors.black,
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
              ),
            ),
          ),
          // Filter dropdowns
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Dropdown for selecting food type
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedFoodType,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedFoodType = newValue;
                        });
                      }
                    },
                    items: <String>['All', 'Live', 'Not Live']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Color(0xFF1C1C1E),
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white, width: 1.0),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white, width: 1.0),
                      ),
                    ),
                    dropdownColor: Colors.black,
                    style: const TextStyle(color: Colors.white),
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  ),
                ),
                SizedBox(width: 8),
                // Dropdown for selecting sort option
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedSortOption,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedSortOption = newValue;
                        });
                      }
                    },
                    items: <String>['Alphabetical', 'Reverse Alphabetical']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Color(0xFF1C1C1E),
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white, width: 1.0),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white, width: 1.0),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12.0),
                    ),
                    dropdownColor: Colors.black,
                    style: const TextStyle(color: Colors.white),
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          // List of trucks
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('companies').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var companies = snapshot.data!.docs;

                return StreamBuilder<Map<String, bool>>(
                  stream: getLiveStatuses(),
                  builder: (context, liveSnapshot) {
                    if (!liveSnapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    var liveStatuses = liveSnapshot.data!;

                    return ListView.builder(
                      itemCount: companies.length,
                      itemBuilder: (context, index) {
                        var company = companies[index];
                        var trucksCollection = company.reference.collection('trucks').snapshots();

                        return StreamBuilder<QuerySnapshot>(
                          stream: trucksCollection,
                          builder: (context, truckSnapshot) {
                            if (!truckSnapshot.hasData) {
                              return Center(child: CircularProgressIndicator());
                            }

                            var trucks = truckSnapshot.data!.docs;

                            // Filter trucks by search query
                            if (searchQuery.isNotEmpty) {
                              trucks = trucks.where((truck) {
                                var truckName = truck['name'].toString().toLowerCase();
                                return truckName.contains(searchQuery.toLowerCase());
                              }).toList();
                            }

                            // Sort trucks based on selectedSortOption
                            if (selectedSortOption == 'Alphabetical') {
                              trucks.sort((a, b) => a['name'].compareTo(b['name']));
                            } else if (selectedSortOption == 'Reverse Alphabetical') {
                              trucks.sort((a, b) => b['name'].compareTo(a['name']));
                            }

                            return Column(
                              children: trucks.map((truck) {
                                return FutureBuilder<DocumentSnapshot>(
                                  future: truck.reference.collection('profile').doc('profile').get(),
                                  builder: (context, profileSnapshot) {
                                    if (!profileSnapshot.hasData) {
                                      return ListTile(
                                        title: Text(truck['name']),
                                        subtitle: Text('Loading...'),
                                      );
                                    }

                                    var profile = profileSnapshot.data;
                                    var description = profile != null && profile.exists
                                        ? profile['description'] ?? 'No description'
                                        : 'No description';
                                    var imageUrl = profile != null && profile.exists
                                        ? profile['imageUrl'] ?? ''
                                        : '';
                                    var truckId = truck.id;
                                    var companyId = company.id;
                                    var liveKey = '$companyId/$truckId';
                                    bool isLive = liveStatuses.containsKey(liveKey);

                                    // Filter logic
                                    if (selectedFoodType == 'Live' && !isLive) {
                                      return SizedBox.shrink(); // Skip rendering this truck if it's not live
                                    } else if (selectedFoodType == 'Not Live' && isLive) {
                                      return SizedBox.shrink(); // Skip rendering this truck if it's live
                                    }

                                    return Card(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      elevation: 5,
                                      color: Color.fromARGB(255, 216, 255, 206),
                                      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          radius: 30,
                                          backgroundImage: imageUrl.isNotEmpty
                                              ? NetworkImage(imageUrl)
                                              : AssetImage('assets/default_truck.png') as ImageProvider,
                                          backgroundColor: Colors.grey[200],
                                        ),
                                        title: Text(
                                          truck['name'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(description),
                                            if (isLive)
                                              Container(
                                                margin: EdgeInsets.only(top: 5),
                                                padding: EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                                                decoration: BoxDecoration(
                                                  color: Colors.red,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'Active',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.black),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => TruckDetailPage(companyId: company.id, truckId: truck.id),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                );
                              }).toList(),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/*
 * Widget for displaying the details of a specific truck
 */
class TruckDetailPage extends StatelessWidget {
  final String companyId;
  final String truckId;

  TruckDetailPage({required this.companyId, required this.truckId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Truck Details'),
        backgroundColor: const Color(0xFF1C1C1E),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: const Color(0xFF1C1C1E),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('companies').doc(companyId).collection('trucks').doc(truckId).get(),
              builder: (context, truckSnapshot) {
                if (!truckSnapshot.hasData) {
                  return Text('Loading truck details...', style: TextStyle(color: Colors.white));
                }

                var truck = truckSnapshot.data;
                var truckName = truck != null && truck.exists
                    ? truck['name'] ?? 'No name'
                    : 'No name';

                return Text(
                  truckName,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                );
              },
            ),
            SizedBox(height: 8),
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('companies').doc(companyId).collection('trucks').doc(truckId).collection('profile').doc('profile').get(),
              builder: (context, profileSnapshot) {
                if (!profileSnapshot.hasData) {
                  return Text('Loading profile...', style: TextStyle(color: Colors.white));
                }

                var profile = profileSnapshot.data;
                var description = profile != null && profile.exists
                    ? profile['description'] ?? 'No description'
                    : 'No description';

                return Text(
                  description,
                  style: TextStyle(fontSize: 16, color: Colors.white),
                );
              },
            ),
            SizedBox(height: 16),
            Text(
              'Menu',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('companies')
                    .doc(companyId)
                    .collection('trucks')
                    .doc(truckId)
                    .collection('sections')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }
                  var sections = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: sections.length,
                    itemBuilder: (context, index) {
                      var section = sections[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 16),
                          Text(
                            section['name'],
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Divider(color: Colors.white),
                          StreamBuilder<QuerySnapshot>(
                            stream: section.reference.collection('items').snapshots(),
                            builder: (context, itemSnapshot) {
                              if (!itemSnapshot.hasData) {
                                return Center(child: CircularProgressIndicator());
                              }
                              var items = itemSnapshot.data!.docs;
                              return ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: items.length,
                                itemBuilder: (context, index) {
                                  var item = items[index];
                                  return ListTile(
                                    title: Text(item['name'], style: TextStyle(color: Colors.white)),
                                    subtitle: Text(item['description'], style: TextStyle(color: Colors.white)),
                                    trailing: Text('\$${item['price']}', style: TextStyle(color: Colors.white)),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
