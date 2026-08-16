import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense.dart';
import '../providers/expenses_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/pdf_download_web.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  // View Receipt Slip Attachment Dialog
  void _showReceiptDialog(Expense expense) {
    showDialog(
      context: context,
      builder: (context) {
        final url = expense.receiptUrl ?? '';

        return AlertDialog(
          title: Text('Bill Receipt Slip - ${expense.title}'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (url.startsWith('http://') || url.startsWith('https://') || url.startsWith('data:image'))
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            color: Colors.grey.shade100,
                            child: Column(
                              children: [
                                const Icon(Icons.description, size: 48, color: Colors.teal),
                                const SizedBox(height: 8),
                                Text('Attached Receipt File:\n$url', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.grey.shade100,
                      child: Column(
                        children: [
                          const Icon(Icons.attachment, size: 48, color: Colors.teal),
                          const SizedBox(height: 8),
                          Text('Receipt File Attachment:\n$url', textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Add / Edit Expense Dialog with Native Web File Uploading
  void _showAddEditExpenseDialog([Expense? expense]) {
    final isSuperAdmin = ref.read(isSuperAdminProvider);

    final titleController = TextEditingController(text: expense?.title ?? '');
    final amountController = TextEditingController(text: expense?.amount.toString() ?? '');
    final paidToController = TextEditingController(text: expense?.paidTo ?? '');
    final paidByController = TextEditingController(text: expense?.paidBy ?? 'Society Fund');
    final receiptUrlController = TextEditingController(text: expense?.receiptUrl ?? '');

    String category = expense?.category ?? 'Utilities';
    bool isCleared = expense?.isCleared ?? true;
    DateTime selectedDate = expense?.date ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void triggerWebFilePicker() {
              WebDownloader.pickFileWeb((dataUrl, filename) {
                setDialogState(() {
                  receiptUrlController.text = dataUrl;
                });
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Receipt image "$filename" attached!'), backgroundColor: Colors.teal),
                  );
                }
              });
            }

            return AlertDialog(
              title: Text(expense == null ? 'Add Society Expense' : 'Edit Society Expense'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 420,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Title / Description (e.g., Security Salary)'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: amountController,
                        decoration: const InputDecoration(labelText: 'Amount (₹)'),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: category,
                        decoration: const InputDecoration(labelText: 'Category'),
                        items: const [
                          DropdownMenuItem(value: 'Utilities', child: Text('Utilities (Electricity / Water)')),
                          DropdownMenuItem(value: 'Salaries', child: Text('Salaries (Security / Cleaner)')),
                          DropdownMenuItem(value: 'Maintenance', child: Text('Maintenance & Repairs')),
                          DropdownMenuItem(value: 'Other', child: Text('Other Expenses')),
                        ],
                        onChanged: (val) => setDialogState(() => category = val!),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: paidByController,
                        decoration: const InputDecoration(
                          labelText: 'Paid By (Who Paid)',
                          hintText: 'e.g., Manohar Mokashi / Society Fund',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: paidToController,
                        decoration: const InputDecoration(
                          labelText: 'Paid To / Vendor Name',
                          hintText: 'e.g., MSEB / Water Tanker Vendor',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Receipt Upload Section
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.teal.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Attach Bill Receipt Slip (Optional):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: triggerWebFilePicker,
                                    icon: const Icon(Icons.photo_library, color: Colors.white),
                                    label: const Text('📁 Upload Receipt Image / File'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (receiptUrlController.text.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: const [
                                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                                  SizedBox(width: 4),
                                  Text('Receipt slip attached successfully!', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                            const SizedBox(height: 8),
                            TextField(
                              controller: receiptUrlController,
                              decoration: const InputDecoration(
                                labelText: 'Or Receipt Image URL / Link',
                                hintText: 'https://... (Optional)',
                                isDense: true,
                              ),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: Text(isCleared ? 'Status: Cleared / Paid' : 'Status: Pending / Unpaid Bill'),
                        subtitle: Text(isCleared ? 'Payment completed' : 'Bill generated but pending payment'),
                        value: isCleared,
                        activeThumbColor: Colors.green,
                        onChanged: (val) => setDialogState(() => isCleared = val),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        title: Text('Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2025),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setDialogState(() => selectedDate = picked);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                if (expense != null && isSuperAdmin)
                  TextButton(
                    onPressed: () async {
                      await ref.read(expensesNotifierProvider.notifier).deleteExpense(expense.id);
                      if (context.mounted) Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Delete Expense'),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isEmpty || amountController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill title and amount')),
                      );
                      return;
                    }

                    final newExpense = Expense(
                      id: expense?.id ?? '',
                      title: titleController.text.trim(),
                      category: category,
                      amount: double.tryParse(amountController.text) ?? 0.0,
                      date: selectedDate,
                      paidTo: paidToController.text.trim().isEmpty ? null : paidToController.text.trim(),
                      paidBy: paidByController.text.trim().isEmpty ? 'Society Fund' : paidByController.text.trim(),
                      isCleared: isCleared,
                      receiptUrl: receiptUrlController.text.trim().isEmpty ? null : receiptUrlController.text.trim(),
                    );

                    if (expense == null) {
                      await ref.read(expensesNotifierProvider.notifier).addExpense(newExpense);
                    } else {
                      await ref.read(expensesNotifierProvider.notifier).updateExpense(newExpense);
                    }

                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text(expense == null ? 'Add Expense' : 'Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expensesStreamProvider);
    final isSuperAdmin = ref.watch(isSuperAdminProvider);
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Society Expenses',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isSuperAdmin
                          ? 'Super Admin Access: Full Add, Edit & Delete Rights'
                          : 'Standard User: Log expenses (Edit/Delete restricted to Super Admin)',
                      style: TextStyle(color: isSuperAdmin ? Colors.teal : Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                // EVERYONE CAN ADD EXPENSES
                ElevatedButton.icon(
                  onPressed: () => _showAddEditExpenseDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Expense'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: expensesAsync.when(
              data: (expenses) {
                if (expenses.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('No expenses recorded yet.'),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => _showAddEditExpenseDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Log First Society Expense'),
                        ),
                      ],
                    ),
                  );
                }

                double totalExpense = 0.0;
                double totalCleared = 0.0;
                double totalPending = 0.0;

                for (var e in expenses) {
                  totalExpense += e.amount;
                  if (e.isCleared) {
                    totalCleared += e.amount;
                  } else {
                    totalPending += e.amount;
                  }
                }

                return Column(
                  children: [
                    // Expense Metrics Row
                    isMobile
                        ? Column(
                            children: [
                              Card(
                                color: Colors.orange.shade50,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Total Logged Expenses', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500)),
                                      Text('₹$totalExpense', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                                    ],
                                  ),
                                ),
                              ),
                              Card(
                                color: Colors.green.shade50,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Total Paid (Cleared)', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500)),
                                      Text('₹$totalCleared', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                                    ],
                                  ),
                                ),
                              ),
                              Card(
                                color: Colors.red.shade50,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Total Pending Bills', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
                                      Text('₹$totalPending', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: Card(
                                  color: Colors.orange.shade50,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      children: [
                                        const Text('Total Logged Expenses', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500)),
                                        const SizedBox(height: 4),
                                        Text('₹$totalExpense', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Card(
                                  color: Colors.green.shade50,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      children: [
                                        const Text('Total Paid (Cleared)', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500)),
                                        const SizedBox(height: 4),
                                        Text('₹$totalCleared', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Card(
                                  color: Colors.red.shade50,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      children: [
                                        const Text('Total Pending Bills', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
                                        const SizedBox(height: 4),
                                        Text('₹$totalPending', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                    const SizedBox(height: 16),

                    // Expenses List
                    Expanded(
                      child: ListView.builder(
                        itemCount: expenses.length,
                        itemBuilder: (context, index) {
                          final expense = expenses[index];
                          final isCleared = expense.isCleared;
                          final hasAttachment = expense.receiptUrl != null && expense.receiptUrl!.isNotEmpty;

                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isCleared ? Colors.green.shade100 : Colors.red.shade100,
                                child: Icon(
                                  isCleared ? Icons.check_circle : Icons.pending_actions,
                                  color: isCleared ? Colors.green : Colors.red,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Text(expense.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  Chip(
                                    label: Text(isCleared ? 'Cleared' : 'Pending Bill', style: const TextStyle(fontSize: 11)),
                                    backgroundColor: isCleared ? Colors.green.shade100 : Colors.red.shade100,
                                    labelStyle: TextStyle(color: isCleared ? Colors.green.shade900 : Colors.red.shade900),
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  if (hasAttachment) ...[
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      onPressed: () => _showReceiptDialog(expense),
                                      icon: const Icon(Icons.attach_file, size: 14, color: Colors.teal),
                                      label: const Text('View Slip', style: TextStyle(fontSize: 11, color: Colors.teal)),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                        minimumSize: const Size(0, 26),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              subtitle: Text(
                                'Paid By: ${expense.paidBy ?? "Society Fund"} | Vendor: ${expense.paidTo ?? "N/A"}\nCategory: ${expense.category} | Date: ${expense.date.day}/${expense.date.month}/${expense.date.year}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '₹${expense.amount}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isCleared ? Colors.green : Colors.red,
                                    ),
                                  ),
                                  // ONLY SUPER ADMIN CAN EDIT OR DELETE EXPENSES
                                  if (isSuperAdmin) ...[
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.teal),
                                      tooltip: 'Edit Expense Entry (Super Admin Only)',
                                      onPressed: () => _showAddEditExpenseDialog(expense),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      tooltip: 'Delete Expense Entry (Super Admin Only)',
                                      onPressed: () => ref.read(expensesNotifierProvider.notifier).deleteExpense(expense.id),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(child: Text('Error loading expenses: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
