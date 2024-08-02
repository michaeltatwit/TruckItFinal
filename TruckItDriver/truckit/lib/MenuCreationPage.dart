import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'menu_server.dart';

/*
 * This file allows users to create and edit menus for their food trucks. It interacts with Firestore to save and retrieve menu data.
 * The main widget is MenuCreationPage, which displays sections of the menu and allows adding or removing sections and items.
 */

/*
 * Main widget for the menu creation page
 */
class MenuCreationPage extends StatefulWidget {
  final String companyId;
  final String truckId;

  MenuCreationPage({required this.companyId, required this.truckId});

  @override
  _MenuCreationPageState createState() => _MenuCreationPageState();
}

class _MenuCreationPageState extends State<MenuCreationPage> {
  final MenuServer _menuServer = MenuServer(); // Serverto handle menu operations
  final List<SectionWidget> _sections = []; // List to hold sections of the menu

  @override
  void initState() {
    super.initState();
    _loadData(); // Loads existing menu data when the wodget is initialized
  }

  /*
   * Function that loads existing menu data from Firestore and initializes the sections and items.
   * For each section, it fetches the items and adds them to the section widget.
   */
  Future<void> _loadData() async {
    var sectionsSnapshot = await _menuServer.getSections(widget.companyId, widget.truckId);
    for (var sectionDoc in sectionsSnapshot.docs) {
      var section = SectionWidget(
        companyId: widget.companyId,
        truckId: widget.truckId,
        menuServer: _menuServer,
        sectionId: sectionDoc.id,
        initialName: sectionDoc['name'],
        onDelete: () => _removeSection(sectionDoc.id),
      );
      setState(() {
        _sections.add(section);
      });
      var itemsSnapshot = await _menuServer.getMenuItems(widget.companyId, widget.truckId, sectionDoc.id);
      for (var itemDoc in itemsSnapshot.docs) {
        section.addItem(
          initialName: itemDoc['name'],
          initialPrice: itemDoc['price'],
          initialDescription: itemDoc['description'],
          itemId: itemDoc.id,
        );
      }
    }
  }

  /*
   * Function to add a new section to the menu.
   */
  void _addSection() async {
    String newSectionId = await _menuServer.createSection(widget.companyId, widget.truckId, 'New Section');
    setState(() {
      _sections.add(SectionWidget(
        companyId: widget.companyId,
        truckId: widget.truckId,
        menuServer: _menuServer,
        sectionId: newSectionId,
        onDelete: () => _removeSection(newSectionId),
      ));
    });
  }

  /*
   * Function to remove a section from the menu.
   * Deletes the section from Firestore.
   */
  void _removeSection(String sectionId) {
    setState(() {
      _sections.removeWhere((section) => section.sectionId == sectionId);
    });
    if (sectionId.isNotEmpty) {
      _menuServer.deleteSection(widget.companyId, widget.truckId, sectionId);
    }
  }

  /*
   * Function to save the menu to Firestore.
   * Iterates over all sections and saves each one.
   */
  void _saveMenu() async {
    for (var section in _sections) {
      await section.saveSection();
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Menu Saved'),
        content: Text('Your menu has been saved successfully.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  /*
   * Function to build the UI for menu creation page.
   * Includes sections and buttons for adding sections and saving the menu.
   */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Menu', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1C1C1E),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      backgroundColor: const Color(0xFF1C1C1E),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            ..._sections,
            SizedBox(height: 16.0),
            if (_sections.isEmpty)
              Center(
                child: ElevatedButton(
                  onPressed: _addSection,
                  child: Text('Add Section'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                  ),
                ),
              )
            else
              ElevatedButton(
                onPressed: _addSection,
                child: Text('Add Section'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(55.0),
        child: ElevatedButton(
          onPressed: _saveMenu,
          child: Text('Save Menu', style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1C1C1E),
            side: BorderSide(color: Colors.white, width: 1.0),
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
          ),
        ),
      ),
    );
  }
}

/*
 * Widget for a section in the menu.
 * A section can contain multiple menu items.
 */
class SectionWidget extends StatefulWidget {
  final String companyId;
  final String truckId;
  final MenuServer menuServer;
  final String sectionId;
  final String? initialName;
  final VoidCallback onDelete;

  SectionWidget({
    required this.companyId,
    required this.truckId,
    required this.menuServer,
    required this.sectionId,
    required this.onDelete,
    this.initialName,
  });

  final _SectionWidgetState _sectionState = _SectionWidgetState(); // State for the section widget

  // Method to save the section
  Future<void> saveSection() => _sectionState.saveSection();

  // Method to add an item to the section
  void addItem({
    String? initialName,
    double? initialPrice,
    String? initialDescription,
    String? itemId,
  }) {
    _sectionState.addItem(
      initialName: initialName,
      initialPrice: initialPrice,
      initialDescription: initialDescription,
      itemId: itemId,
    );
  }

  @override
  _SectionWidgetState createState() => _sectionState;
}

/*
 * State class for SectionWidget.
 * Manages the state of each section in the menu.
 * Handles adding, removing, and saving menu items within a section.
 */
class _SectionWidgetState extends State<SectionWidget> {
  final TextEditingController _sectionNameController = TextEditingController(); // Controller for section name input
  final List<MenuItemWidget> _menuItems = [];
  late String sectionId;

  @override
  void initState() {
    super.initState();
    _sectionNameController.text = widget.initialName ?? '';
    sectionId = widget.sectionId;
  }

  /*
   * Adds a menu item to the section.
   */
  void addItem({
    String? initialName,
    double? initialPrice,
    String? initialDescription,
    String? itemId,
  }) {
    setState(() {
      _menuItems.add(MenuItemWidget(
        companyId: widget.companyId,
        truckId: widget.truckId,
        sectionId: sectionId,
        menuServer: widget.menuServer,
        onDelete: () => _removeMenuItem(_menuItems.length - 1),
        initialName: initialName,
        initialPrice: initialPrice,
        initialDescription: initialDescription,
        itemId: itemId,
      ));
    });
  }

  /*
   * Removes a menu item from the section.
   */
  void _removeMenuItem(int index) {
    setState(() {
      _menuItems.removeAt(index);
    });
  }

  /*
   * Saves the section and its items to Firestore.
   */
  Future<void> saveSection() async {
    await widget.menuServer.updateSectionName(widget.companyId, widget.truckId, sectionId, _sectionNameController.text);
    for (var item in _menuItems) {
      await item.saveMenuItem();
    }
  }

  /*
   * Builds the UI section widget.
   * Includes the section name input and the list of menu items.
   */
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: Color(0xFF2C2C2E),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _sectionNameController,
                    decoration: const InputDecoration(
                      labelText: 'Section Name',
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
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.white),
                  onPressed: widget.onDelete,
                ),
              ],
            ),
            SizedBox(height: 8.0),
            ..._menuItems,
            SizedBox(height: 8.0),
            Center(
              child: ElevatedButton(
                onPressed: addItem,
                child: Text('Add Menu Item'),
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

/*
 * Widget representing an individual menu item within a section.
 */
class MenuItemWidget extends StatefulWidget {
  final String companyId;
  final String truckId;
  final String sectionId;
  final MenuServer menuServer;
  final VoidCallback onDelete;
  final String? initialName;
  final double? initialPrice;
  final String? initialDescription;
  final String? itemId;

  MenuItemWidget({
    required this.companyId,
    required this.truckId,
    required this.sectionId,
    required this.menuServer,
    required this.onDelete,
    this.initialName,
    this.initialPrice,
    this.initialDescription,
    this.itemId,
  });

  // State for the menu item widget
  final _MenuItemWidgetState _itemState = _MenuItemWidgetState();

  // Method to save the menu item
  Future<void> saveMenuItem() => _itemState.saveMenuItem();

  @override
  _MenuItemWidgetState createState() => _itemState;
}

/*
 * State class for the MenuItemWidget.
 * Manages the state of each menu item in a section.
 * Handles updating and saving menu item details.
 */
class _MenuItemWidgetState extends State<MenuItemWidget> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _imageUrl = '';

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialName ?? '';
    _priceController.text = widget.initialPrice?.toString() ?? '';
    _descriptionController.text = widget.initialDescription ?? '';
  }

  /*
   * Saves the menu to Firestore.
   */
  Future<void> saveMenuItem() async {
    if (_nameController.text.isNotEmpty && _priceController.text.isNotEmpty) {
      if (widget.itemId == null) {
        await widget.menuServer.addMenuItem(
          widget.companyId,
          widget.truckId,
          widget.sectionId,
          _nameController.text,
          double.parse(_priceController.text),
          _descriptionController.text,
          _imageUrl,
        );
      } else {
        await widget.menuServer.updateMenuItem(
          widget.companyId,
          widget.truckId,
          widget.sectionId,
          widget.itemId!,
          _nameController.text,
          double.parse(_priceController.text),
          _descriptionController.text,
          _imageUrl,
        );
      }
    }
  }

  /*
   * Builds the UI for the menu item widget.
   * Includes inouts for a name, price, and description.
   */
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: Color(0xFF2C2C2E),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Item Name',
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
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.white),
                  onPressed: widget.onDelete,
                ),
              ],
            ),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price',
                labelStyle: TextStyle(color: Colors.white),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
              keyboardType: TextInputType.number,
              style: TextStyle(color: Colors.white),
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
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
          ],
        ),
      ),
    );
  }
}
