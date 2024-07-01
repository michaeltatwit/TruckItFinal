import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TruckListPage extends StatefulWidget {
  @override
  _TruckListPageState createState() => _TruckListPageState();
}

class _TruckListPageState extends State<TruckListPage> {
  String searchQuery = '';
  String selectedFoodType = 'All';
  String selectedRadius = '5 miles';
  String selectedSortOption = 'Alphabetical';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('List of Trucks'),
        backgroundColor: const Color(0xFF1C1C1E),
        iconTheme: IconThemeData(
          color: Colors.grey[300], // Set the back button color to match the search button color
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          // Filter dropdowns
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Dropdown for selecting food type
                  DropdownButton<String>(
                    value: selectedFoodType,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedFoodType = newValue;
                        });
                      }
                    },
                    items: <String>['All', 'Mexican', 'Chinese', 'Italian', 'BBQ', 'Ice Cream']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  SizedBox(width: 8),
                  // Dropdown for selecting search radius
                  DropdownButton<String>(
                    value: selectedRadius,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedRadius = newValue;
                        });
                      }
                    },
                    items: <String>['5 miles', '10 miles', '20 miles']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  SizedBox(width: 8),
                  // Dropdown for selecting sort option
                  DropdownButton<String>(
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
                  ),
                ],
              ),
            ),
          ),
          // List of trucks
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('companies').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  print("No data found in companies collection.");
                  return Center(child: CircularProgressIndicator());
                }

                var companies = snapshot.data!.docs;

                if (companies.isEmpty) {
                  print("No companies found.");
                }

                return ListView.builder(
                  itemCount: companies.length,
                  itemBuilder: (context, index) {
                    var company = companies[index];
                    var trucksCollection = company.reference.collection('trucks').snapshots();
                    return StreamBuilder<QuerySnapshot>(
                      stream: trucksCollection,
                      builder: (context, truckSnapshot) {
                        if (!truckSnapshot.hasData) {
                          print("No data found in trucks collection for company ${company.id}.");
                          return Center(child: CircularProgressIndicator());
                        }

                        var trucks = truckSnapshot.data!.docs;

                        if (trucks.isEmpty) {
                          print("No trucks found for company ${company.id}.");
                        }

                        return Column(
                          children: trucks.map((truck) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                              child: Card(
                                elevation: 3.0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                child: ListTile(
                                  // leading: CircleAvatar(
                                  //   backgroundImage: NetworkImage(truck['profile_image'] ?? 'https://via.placeholder.com/150'),
                                  // ),
                                  title: Text(
                                    truck['name'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18.0,
                                    ),
                                  ),
                                  // subtitle: Text(
                                  //   truck['profile'] ?? 'No profile',
                                  //   maxLines: 2,
                                  //   overflow: TextOverflow.ellipsis,
                                  // ),
                                  trailing: Icon(Icons.arrow_forward_ios),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TruckDetailPage(companyId: company.id, truck: truck),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          }).toList(),
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

class TruckDetailPage extends StatelessWidget {
  final String companyId;
  final QueryDocumentSnapshot truck;

  TruckDetailPage({required this.companyId, required this.truck});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(truck['name']),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              truck['name'],
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            // Display truck profile if available
            // Text(
            //   truck['profile'] ?? 'No profile description',
            //   style: TextStyle(fontSize: 16),
            // ),
            SizedBox(height: 16),
            Text(
              'Menu',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('companies')
                    .doc(companyId)
                    .collection('trucks')
                    .doc(truck.id)
                    .collection('sections')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    print("No data found in sections collection for truck ${truck.id}.");
                    return Center(child: CircularProgressIndicator());
                  }
                  var sections = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: sections.length,
                    itemBuilder: (context, index) {
                      var section = sections[index];
                      return ExpansionTile(
                        title: Text(section['name']),
                        children: [
                          StreamBuilder<QuerySnapshot>(
                            stream: section.reference.collection('items').snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                print("No data found in items collection for section ${section.id}.");
                                return Center(child: CircularProgressIndicator());
                              }
                              var items = snapshot.data!.docs;
                              return ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: items.length,
                                itemBuilder: (context, index) {
                                  var item = items[index];
                                  return ListTile(
                                    title: Text(item['name']),
                                    subtitle: Text(item['description']),
                                    trailing: Text('\$${item['price']}'),
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
