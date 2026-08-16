import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notice.dart';

final noticesStreamProvider = StreamProvider<List<Notice>>((ref) {
  return FirebaseFirestore.instance
      .collection('notices')
      .orderBy('datePosted', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => Notice.fromMap(doc.data(), doc.id)).toList();
  });
});

class NoticesNotifier extends Notifier<void> {
  @override
  void build() {}

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> postNotice(Notice notice) async {
    await _firestore.collection('notices').add(notice.toMap());
  }

  Future<void> updateNotice(Notice notice) async {
    await _firestore.collection('notices').doc(notice.id).update(notice.toMap());
  }

  Future<void> deleteNotice(String id) async {
    await _firestore.collection('notices').doc(id).delete();
  }
}

final noticesNotifierProvider = NotifierProvider<NoticesNotifier, void>(NoticesNotifier.new);
