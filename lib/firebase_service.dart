import 'package:firebase_database/firebase_database.dart';

class FirebaseService{
  final _database = FirebaseDatabase.instance.ref();

  Future <void> updateCarNumberInput({
    required String location,
    required bool value,
  }) async {
    try {
      await _database.child('location/$location/carNumberInput').set(value);
      print('carNumberInput updated to $value at $location');
    } catch(e) {
      print('Failed to update carNumberInput: $e');
    }
  }
}