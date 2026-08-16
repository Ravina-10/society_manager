import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final String? paidTo;
  final String? paidBy;
  final bool isCleared;
  final String? receiptUrl;

  Expense({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    this.paidTo,
    this.paidBy,
    this.isCleared = true,
    this.receiptUrl,
  });

  factory Expense.fromMap(Map<String, dynamic> map, String id) {
    return Expense(
      id: id,
      title: map['title'] ?? '',
      category: map['category'] ?? 'Other',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paidTo: map['paidTo'],
      paidBy: map['paidBy'],
      isCleared: map['isCleared'] as bool? ?? true,
      receiptUrl: map['receiptUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'paidTo': paidTo,
      'paidBy': paidBy,
      'isCleared': isCleared,
      'receiptUrl': receiptUrl,
    };
  }
}
