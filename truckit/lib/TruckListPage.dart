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
    List<String> filteredTrucks = trucks.where((truck) {
      // Placeholder logic for filtering, you can replace this with your own filtering logic.
      return truck.toLowerCase().contains(searchQuery.toLowerCase()) &&
          (selectedFoodType == 'All' || truck.contains(selectedFoodType));
    }).toList();

    // Sort the filtered trucks based on the selected sorting option
    if (selectedSortOption == 'Alphabetical') {
      filteredTrucks.sort();
    } else if (selectedSortOption == 'Reverse Alphabetical') {
      filteredTrucks.sort((a, b) => b.compareTo(a));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('List of Trucks'),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
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
                ),
                SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
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
                ),
                SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
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
                ),
              ],
            ),
          ),
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
