import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/concern.dart';

final concernsStreamProvider = StreamProvider<List<Concern>>((ref) {
  return FirebaseFirestore.instance
      .collection('concerns')
      .orderBy('dateRaised', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => Concern.fromMap(doc.data(), doc.id)).toList();
  });
});

class ConcernsNotifier extends Notifier<void> {
  @override
  void build() {}

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> raiseConcern(Concern concern) async {
    await _firestore.collection('concerns').add(concern.toMap());
  }

  Future<void> addAdminReply(String concernId, ConcernComment comment, String newStatus) async {
    final docRef = _firestore.collection('concerns').doc(concernId);
    final snapshot = await docRef.get();

    if (snapshot.exists) {
      List<dynamic> existingComments = snapshot.data()?['comments'] ?? [];
      existingComments.add(comment.toMap());

      await docRef.update({
        'comments': existingComments,
        'status': newStatus,
      });
    }
  }

  Future<void> updateConcernStatus(String concernId, String newStatus) async {
    await _firestore.collection('concerns').doc(concernId).update({'status': newStatus});
  }

  Future<void> deleteConcern(String concernId) async {
    await _firestore.collection('concerns').doc(concernId).delete();
  }
}

final concernsNotifierProvider = NotifierProvider<ConcernsNotifier, void>(ConcernsNotifier.new);
