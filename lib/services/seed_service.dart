import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/flat.dart';
import '../models/maintenance.dart';

class SeedService {
  static Future<void> seedMartandNiwasData() async {
    try {
      final firestore = FirebaseFirestore.instance;

      // 1. Clean up any random/duplicate maintenance documents in Firestore
      final snapshot = await firestore.collection('maintenance').get();
      final validDocIds = {
        'M-Aug2026-F001',
        'M-Aug2026-F101',
        'M-Aug2026-F102',
        'M-Aug2026-F201',
        'M-Aug2026-F202',
        'M-Aug2026-F203',
        'M-Aug2026-F301',
        'M-Aug2026-F302',
      };

      for (var doc in snapshot.docs) {
        if (!validDocIds.contains(doc.id)) {
          try {
            await doc.reference.delete();
          } catch (_) {}
        }
      }

      // 2. Fetch existing user accounts from Firestore to cross-reference registered phone numbers
      Map<String, String> userPhones = {};
      try {
        final usersSnap = await firestore.collection('users').get();
        for (var doc in usersSnap.docs) {
          final data = doc.data();
          final phone = (data['phoneNumber'] as String?) ?? '';
          final name = (data['name'] as String?) ?? '';
          if (phone.isNotEmpty) {
            userPhones[name.toLowerCase()] = phone;
          }
        }
      } catch (_) {}

      // 3. Seed Flats Data with assigned owner mobile numbers (cross-referencing user details)
      final List<Flat> initialFlats = [
        Flat(
          id: 'F001',
          flatNumber: 'F001',
          ownerName: 'Manohar Mokashi',
          ownerPhone: userPhones['manohar mokashi'] ?? '+91 9503623550',
          isOccupied: true,
        ),
        Flat(
          id: 'F101',
          flatNumber: 'F101',
          ownerName: 'Vitthal Mokashi',
          ownerPhone: userPhones['vitthal mokashi'] ?? '+91 9822011002',
          isOccupied: true,
        ),
        Flat(
          id: 'F102',
          flatNumber: 'F102',
          ownerName: 'Tushar Mokashi',
          ownerPhone: userPhones['tushar mokashi'] ?? '+91 9762092666',
          isOccupied: true,
        ),
        Flat(
          id: 'F201',
          flatNumber: 'F201',
          ownerName: 'Mahesh Mokashi',
          ownerPhone: userPhones['mahesh mokashi'] ?? '+91 9822011004',
          isOccupied: true,
        ),
        Flat(
          id: 'F202',
          flatNumber: 'F202',
          ownerName: 'Suresh Mokashi',
          ownerPhone: userPhones['suresh mokashi'] ?? '+91 9822011005',
          isOccupied: true,
        ),
        Flat(
          id: 'F203',
          flatNumber: 'F203',
          ownerName: 'Manali Pagade',
          ownerPhone: userPhones['manali pagade'] ?? '+91 9822011006',
          isOccupied: true,
        ),
        Flat(
          id: 'F301',
          flatNumber: 'F301',
          ownerName: 'Mohit Mokashi',
          ownerPhone: userPhones['mohit mokashi'] ?? '+91 9822011007',
          isOccupied: true,
        ),
        Flat(
          id: 'F302',
          flatNumber: 'F302',
          ownerName: 'Vikas Mokashi',
          ownerPhone: userPhones['vikas mokashi'] ?? '+91 9822011008',
          isOccupied: true,
        ),
      ];

      for (var flat in initialFlats) {
        await firestore.collection('flats').doc(flat.id).set(flat.toMap(), SetOptions(merge: true));
      }

      // 4. Seed Clean Financial Year FY 2026-27 Dues for August 2026
      final List<MaintenanceRecord> initialMaintenance = [
        MaintenanceRecord(id: 'M-Aug2026-F001', flatNumber: 'F001', monthYear: 'Aug 2026', amountDue: 600, amountPaid: 0, status: 'Pending'),
        MaintenanceRecord(id: 'M-Aug2026-F101', flatNumber: 'F101', monthYear: 'Aug 2026', amountDue: 600, amountPaid: 600, paymentType: 'UPI', status: 'Paid', paymentDate: DateTime.now()),
        MaintenanceRecord(id: 'M-Aug2026-F102', flatNumber: 'F102', monthYear: 'Aug 2026', amountDue: 600, amountPaid: 0, status: 'Pending'),
        MaintenanceRecord(id: 'M-Aug2026-F201', flatNumber: 'F201', monthYear: 'Aug 2026', amountDue: 600, amountPaid: 0, status: 'Pending'),
        MaintenanceRecord(id: 'M-Aug2026-F202', flatNumber: 'F202', monthYear: 'Aug 2026', amountDue: 300, amountPaid: 300, paymentType: 'UPI', status: 'Paid', paymentDate: DateTime.now()),
        MaintenanceRecord(id: 'M-Aug2026-F203', flatNumber: 'F203', monthYear: 'Aug 2026', amountDue: 300, amountPaid: 0, status: 'Pending'),
        MaintenanceRecord(id: 'M-Aug2026-F301', flatNumber: 'F301', monthYear: 'Aug 2026', amountDue: 600, amountPaid: 600, paymentType: 'UPI', status: 'Paid', paymentDate: DateTime.now()),
        MaintenanceRecord(id: 'M-Aug2026-F302', flatNumber: 'F302', monthYear: 'Aug 2026', amountDue: 600, amountPaid: 0, status: 'Pending'),
      ];

      for (var record in initialMaintenance) {
        await firestore.collection('maintenance').doc(record.id).set(record.toMap(), SetOptions(merge: true));
      }
    } catch (_) {}
  }
}
