import 'package:cloud_firestore/cloud_firestore.dart';
// interactions with Firebase 
class MenuServer {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createCompany(String companyName) async {
    DocumentReference companyRef = await _firestore.collection('companies').add({
      'name': companyName,
    });
    return companyRef.id;
  }

  Future<String> createTruck(String companyId, String truckName) async {
    DocumentReference truckRef = await _firestore.collection('companies').doc(companyId).collection('trucks').add({
      'name': truckName,
    });
    return truckRef.id;
  }

  Future<void> createOrUpdateMenu(String companyId, String truckId, String menuName) async {
    await _firestore.collection('companies').doc(companyId).collection('trucks').doc(truckId).set({
      'menu': {'name': menuName}
    }, SetOptions(merge: true));
  }

  Future<String> createSection(String companyId, String truckId, String sectionName) async {
    DocumentReference sectionRef = await _firestore.collection('companies').doc(companyId).collection('trucks').doc(truckId).collection('sections').add({
      'name': sectionName,
    });
    return sectionRef.id;
  }

  Future<void> updateSectionName(String companyId, String truckId, String sectionId, String sectionName) async {
    await _firestore.collection('companies').doc(companyId).collection('trucks').doc(truckId).collection('sections').doc(sectionId).update({
      'name': sectionName,
    });
  }

  Future<void> deleteSection(String companyId, String truckId, String sectionId) async {
    QuerySnapshot itemsSnapshot = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('trucks')
        .doc(truckId)
        .collection('sections')
        .doc(sectionId)
        .collection('items')
        .get();

    for (DocumentSnapshot item in itemsSnapshot.docs) {
      await item.reference.delete();
    }

    await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('trucks')
        .doc(truckId)
        .collection('sections')
        .doc(sectionId)
        .delete();
  }


  Future<void> addMenuItem(String companyId, String truckId, String sectionId, String itemName, double price, String description, String imageUrl) async {
    await _firestore.collection('companies').doc(companyId).collection('trucks').doc(truckId).collection('sections').doc(sectionId).collection('items').add({
      'name': itemName,
      'price': price,
      'description': description,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateMenuItem(String companyId, String truckId, String sectionId, String itemId, String itemName, double price, String description, String imageUrl) async {
    await _firestore.collection('companies').doc(companyId).collection('trucks').doc(truckId).collection('sections').doc(sectionId).collection('items').doc(itemId).update({
      'name': itemName,
      'price': price,
      'description': description,
      'imageUrl': imageUrl,
    });
  }

  Future<void> deleteMenuItem(String companyId, String truckId, String sectionId, String itemId) async {
    await _firestore.collection('companies').doc(companyId).collection('trucks').doc(truckId).collection('sections').doc(sectionId).collection('items').doc(itemId).delete();
  }


  // Profile-related methods
  Future<void> createOrUpdateProfile(String companyId, String truckId, String description, String imageUrl) async {
    await _firestore.collection('companies').doc(companyId).collection('trucks').doc(truckId).collection('profile').doc('profile').set({
      'description': description,
      'imageUrl': imageUrl
    });
  }

  Future<DocumentSnapshot> getProfile(String companyId, String truckId) async {
    return await _firestore.collection('companies').doc(companyId).collection('trucks').doc(truckId).collection('profile').doc('profile').get();
  }

  Future<QuerySnapshot> getSections(String companyId, String truckId) async {
    return await _firestore.collection('companies').doc(companyId).collection('trucks').doc(truckId).collection('sections').get();
  }

  Future<QuerySnapshot> getMenuItems(String companyId, String truckId, String sectionId) async {
    return await _firestore.collection('companies').doc(companyId).collection('trucks').doc(truckId).collection('sections').doc(sectionId).collection('items').get();
  }
}
