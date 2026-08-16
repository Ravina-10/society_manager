import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/flat.dart';

final flatsStreamProvider = StreamProvider<List<Flat>>((ref) {
  return FirebaseFirestore.instance.collection('flats').snapshots().map((snapshot) {
    return snapshot.docs.map((doc) => Flat.fromMap(doc.data(), doc.id)).toList();
  });
});

class FlatsNotifier extends Notifier<void> {
  @override
  void build() {}

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addOrUpdateFlat(Flat flat) async {
    await _firestore.collection('flats').doc(flat.id).set(flat.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteFlat(String flatId) async {
    await _firestore.collection('flats').doc(flatId).delete();
  }
}

final flatsNotifierProvider = NotifierProvider<FlatsNotifier, void>(FlatsNotifier.new);
