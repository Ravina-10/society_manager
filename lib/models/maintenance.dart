import 'package:cloud_firestore/cloud_firestore.dart';

class MaintenanceRecord {
  final String id;
  final String flatNumber;
  final String monthYear;
  final double amountDue;
  final double amountPaid;
  final String paymentType; // Cash, UPI
  final DateTime? paymentDate;
  final String status; // Paid, Pending, Partial
  final String? receiptUrl;

  MaintenanceRecord({
    required this.id,
    required this.flatNumber,
    required this.monthYear,
    required this.amountDue,
    this.amountPaid = 0.0,
    this.paymentType = 'UPI',
    this.paymentDate,
    required this.status,
    this.receiptUrl,
  });

  factory MaintenanceRecord.fromMap(Map<String, dynamic> map, String id) {
    return MaintenanceRecord(
      id: id,
      flatNumber: map['flatNumber'] ?? '',
      monthYear: map['monthYear'] ?? '',
      amountDue: (map['amountDue'] as num?)?.toDouble() ?? 0.0,
      amountPaid: (map['amountPaid'] as num?)?.toDouble() ?? 0.0,
      paymentType: map['paymentType'] ?? 'UPI',
      paymentDate: (map['paymentDate'] as Timestamp?)?.toDate(),
      status: map['status'] ?? 'Pending',
      receiptUrl: map['receiptUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'flatNumber': flatNumber,
      'monthYear': monthYear,
      'amountDue': amountDue,
      'amountPaid': amountPaid,
      'paymentType': paymentType,
      'paymentDate': paymentDate != null ? Timestamp.fromDate(paymentDate!) : null,
      'status': status,
      'receiptUrl': receiptUrl,
    };
  }
}
