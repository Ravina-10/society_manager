import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/maintenance.dart';

final maintenanceStreamProvider = StreamProvider<List<MaintenanceRecord>>((ref) {
  return FirebaseFirestore.instance.collection('maintenance').snapshots().map((snapshot) {
    return snapshot.docs.map((doc) => MaintenanceRecord.fromMap(doc.data(), doc.id)).toList();
  });
});

class MaintenanceNotifier extends Notifier<void> {
  @override
  void build() {}

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Use deterministic doc ID (M-MonthYear-FlatNumber) to prevent stacking/duplicates
  Future<void> addMaintenanceBill(MaintenanceRecord record) async {
    final docId = record.id.isNotEmpty
        ? record.id
        : 'M-${record.monthYear.replaceAll(' ', '')}-${record.flatNumber}';

    await _firestore.collection('maintenance').doc(docId).set(record.toMap(), SetOptions(merge: true));
  }

  Future<void> recordPayment(String id, {
    required double amountPaid,
    required String paymentType,
    required DateTime paymentDate,
    String? receiptUrl,
  }) async {
    final docRef = _firestore.collection('maintenance').doc(id);
    final snap = await docRef.get();
    if (snap.exists) {
      final currentDue = (snap.data()?['amountDue'] as num?)?.toDouble() ?? 0.0;
      final newStatus = amountPaid >= currentDue ? 'Paid' : (amountPaid > 0 ? 'Partial' : 'Pending');

      await docRef.update({
        'amountPaid': amountPaid,
        'paymentType': paymentType,
        'paymentDate': Timestamp.fromDate(paymentDate),
        'status': newStatus,
        'receiptUrl': receiptUrl,
      });
    }
  }

  // Reset dues for a specific month back to clean initial state
  Future<void> resetMonthDues(String monthYear, List<String> flatNumbers) async {
    final snapshot = await _firestore.collection('maintenance').where('monthYear', isEqualTo: monthYear).get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}

final maintenanceNotifierProvider = NotifierProvider<MaintenanceNotifier, void>(MaintenanceNotifier.new);
