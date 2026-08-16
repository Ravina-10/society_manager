import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense.dart';

final expensesStreamProvider = StreamProvider<List<Expense>>((ref) {
  return FirebaseFirestore.instance.collection('expenses').orderBy('date', descending: true).snapshots().map((snapshot) {
    return snapshot.docs.map((doc) => Expense.fromMap(doc.data(), doc.id)).toList();
  });
});

class ExpensesNotifier extends Notifier<void> {
  @override
  void build() {}

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addExpense(Expense expense) async {
    await _firestore.collection('expenses').add(expense.toMap());
  }

  Future<void> updateExpense(Expense expense) async {
    await _firestore.collection('expenses').doc(expense.id).update(expense.toMap());
  }

  Future<void> deleteExpense(String id) async {
    await _firestore.collection('expenses').doc(id).delete();
  }
}

final expensesNotifierProvider = NotifierProvider<ExpensesNotifier, void>(ExpensesNotifier.new);
