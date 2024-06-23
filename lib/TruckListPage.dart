import 'package:flutter/material.dart';

class TruckListPage extends StatefulWidget {
  @override
  _TruckListPageState createState() => _TruckListPageState();
}

class _TruckListPageState extends State<TruckListPage> {
  final List<String> trucks = ['Truck 1', 'Truck 2', 'Truck 3', 'Truck 4'];
  String searchQuery = '';
  String selectedFoodType = 'All';
  String selectedRadius = '5 miles';
  String selectedSortOption = 'Alphabetical';

  @override
  Widget build(BuildContext context) {
    // Filters the list of trucks based on the search query and selected filters.
    List<String> filteredTrucks = trucks.where((truck) {
      return truck.toLowerCase().contains(searchQuery.toLowerCase()) &&
          (selectedFoodType == 'All' || truck.contains(selectedFoodType));
    }).toList();

    // Sorts the filtered trucks based on the selected sorting option.
    if (selectedSortOption == 'Alphabetical') {
      filteredTrucks.sort();
    } else if (selectedSortOption == 'Reverse Alphabetical') {
      filteredTrucks.sort((a, b) => b.compareTo(a));
    }

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
                    items: <String>['All', 'Mexican', 'Chinese', 'Italian', 'BBQ']
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
          // List of filtered trucks
          Expanded(
            child: ListView.builder(
              itemCount: filteredTrucks.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(filteredTrucks[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
