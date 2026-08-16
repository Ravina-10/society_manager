import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/maintenance.dart';
import '../providers/maintenance_provider.dart';
import '../providers/flats_provider.dart';
import '../providers/auth_provider.dart';

class MaintenanceScreen extends ConsumerStatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  ConsumerState<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends ConsumerState<MaintenanceScreen> {
  String _selectedMonth = 'Aug 2026';

  final List<String> _financialYearMonths = [
    'Aug 2026',
    'Sep 2026',
    'Oct 2026',
    'Nov 2026',
    'Dec 2026',
    'Jan 2027',
    'Feb 2027',
    'Mar 2027',
  ];

  // 1. Record / Edit Multi-Month Payment Modal (Loads Existing Payment History)
  void _showRecordPaymentDialog(MaintenanceRecord record) {
    final double flatRate = (record.flatNumber == 'F202' || record.flatNumber == 'F203') ? 300.0 : 600.0;
    
    // Fetch all existing records for this flat to pre-check already paid months
    final allMaintenance = ref.read(maintenanceStreamProvider).value ?? [];
    final flatRecords = allMaintenance.where((m) => m.flatNumber == record.flatNumber).toList();

    final Set<String> selectedMonths = {};
    for (var r in flatRecords) {
      if (r.status == 'Paid' || r.amountPaid >= r.amountDue) {
        selectedMonths.add(r.monthYear);
      }
    }
    // Always include selected month if opening fresh
    if (selectedMonths.isEmpty) {
      selectedMonths.add(_selectedMonth);
    }

    String paymentType = record.paymentType.isNotEmpty ? record.paymentType : 'UPI';
    DateTime selectedDate = record.paymentDate ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            double calculatedTotal = selectedMonths.length * flatRate;

            return AlertDialog(
              title: Text('Record / Edit Payment - Flat ${record.flatNumber}'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 440,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monthly Rate for Flat ${record.flatNumber}: ₹${flatRate.toInt()} / month',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                      ),
                      const SizedBox(height: 14),

                      // Existing Payment History Info
                      if (flatRecords.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Stored Payment History:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blue)),
                              const SizedBox(height: 4),
                              Text(
                                selectedMonths.isEmpty
                                    ? 'No months marked as Paid yet.'
                                    : 'Paid Months: ${selectedMonths.join(', ')} (₹${(selectedMonths.length * flatRate).toInt()} total)',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      const Text('Select / Edit Paid Months (Toggle to Add or Remove Months):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: _financialYearMonths.map((m) {
                          final isSelected = selectedMonths.contains(m);
                          return FilterChip(
                            label: Text(m),
                            selected: isSelected,
                            selectedColor: Colors.teal.shade100,
                            checkmarkColor: Colors.teal.shade900,
                            onSelected: (val) {
                              setDialogState(() {
                                if (val) {
                                  selectedMonths.add(m);
                                } else {
                                  selectedMonths.remove(m);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Selected Total Amount Summary Box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${selectedMonths.length} Month(s) Marked Paid:', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                Text(selectedMonths.isEmpty ? 'None' : selectedMonths.join(', '), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                            Text('Total: ₹${calculatedTotal.toInt()}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        initialValue: paymentType,
                        decoration: const InputDecoration(labelText: 'Payment Mode'),
                        items: const [
                          DropdownMenuItem(value: 'UPI', child: Text('UPI (PhonePe / GPay / Paytm)')),
                          DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                          DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer (NEFT/IMPS)')),
                        ],
                        onChanged: (val) => setDialogState(() => paymentType = val!),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        title: Text('Payment Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
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
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Update all months for this flat in Firestore
                    for (var month in _financialYearMonths) {
                      final docId = 'M-${month.replaceAll(' ', '')}-${record.flatNumber}';
                      final isSelected = selectedMonths.contains(month);

                      if (isSelected) {
                        final rec = MaintenanceRecord(
                          id: docId,
                          flatNumber: record.flatNumber,
                          monthYear: month,
                          amountDue: flatRate,
                          amountPaid: flatRate,
                          paymentType: paymentType,
                          status: 'Paid',
                          paymentDate: selectedDate,
                        );
                        await FirebaseFirestore.instance.collection('maintenance').doc(docId).set(rec.toMap(), SetOptions(merge: true));
                      } else {
                        // If unselected, revert month status to Pending / 0 paid
                        final rec = MaintenanceRecord(
                          id: docId,
                          flatNumber: record.flatNumber,
                          monthYear: month,
                          amountDue: flatRate,
                          amountPaid: 0.0,
                          paymentType: 'UPI',
                          status: 'Pending',
                          paymentDate: null,
                        );
                        await FirebaseFirestore.instance.collection('maintenance').doc(docId).set(rec.toMap(), SetOptions(merge: true));
                      }
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Payment record updated! ${selectedMonths.length} month(s) marked Paid (Total: ₹${calculatedTotal.toInt()}) for Flat ${record.flatNumber}.'),
                          backgroundColor: Colors.teal,
                        ),
                      );
                    }
                  },
                  child: const Text('Save Payment Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 2. Edit Entry Dialog
  void _showPenEditDialog(MaintenanceRecord record) {
    final amountDueController = TextEditingController(text: record.amountDue.toString());
    final amountPaidController = TextEditingController(text: record.amountPaid.toString());
    String paymentType = record.paymentType;
    String status = record.status;
    DateTime selectedDate = record.paymentDate ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Edit Record - Flat ${record.flatNumber} (${record.monthYear})'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 380,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: amountDueController,
                        decoration: const InputDecoration(labelText: 'Monthly Maintenance Charge (₹)'),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: amountPaidController,
                        decoration: const InputDecoration(labelText: 'Amount Paid (₹)'),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: status,
                        decoration: const InputDecoration(labelText: 'Payment Status'),
                        items: const [
                          DropdownMenuItem(value: 'Paid', child: Text('Paid (🟢 Green Badge)')),
                          DropdownMenuItem(value: 'Pending', child: Text('Pending (🔴 Unpaid)')),
                          DropdownMenuItem(value: 'Partial', child: Text('Partial (🟠 Partial Payment)')),
                        ],
                        onChanged: (val) => setDialogState(() => status = val!),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: paymentType,
                        decoration: const InputDecoration(labelText: 'Payment Mode'),
                        items: const [
                          DropdownMenuItem(value: 'UPI', child: Text('UPI (PhonePe / GPay / Paytm)')),
                          DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                          DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer (NEFT/IMPS)')),
                        ],
                        onChanged: (val) => setDialogState(() => paymentType = val!),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        title: Text('Payment Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
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
                TextButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance.collection('maintenance').doc(record.id).delete();
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Delete Entry'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final due = double.tryParse(amountDueController.text) ?? record.amountDue;
                    final paid = double.tryParse(amountPaidController.text) ?? record.amountPaid;

                    final updatedRecord = MaintenanceRecord(
                      id: record.id,
                      flatNumber: record.flatNumber,
                      monthYear: record.monthYear,
                      amountDue: due,
                      amountPaid: paid,
                      paymentType: paymentType,
                      status: status,
                      paymentDate: selectedDate,
                    );

                    await FirebaseFirestore.instance
                        .collection('maintenance')
                        .doc(record.id)
                        .set(updatedRecord.toMap(), SetOptions(merge: true));

                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Generate / Refresh Dues with Carry-Forward Logic
  void _showGenerateDuesDialog() {
    final flatsAsync = ref.read(flatsStreamProvider);
    final maintenanceAsync = ref.read(maintenanceStreamProvider);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Generate / Refresh Dues - $_selectedMonth'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sync dues for 8 flats in $_selectedMonth (FY 2026-27):'),
              const SizedBox(height: 8),
              const Text('• Standard Monthly Rate: ₹600 / month'),
              const Text('• Flat F202 & F203 Rate: ₹300 / month'),
              const SizedBox(height: 8),
              const Text(
                'Note: Unpaid dues from previous months will carry forward to this month.',
                style: TextStyle(color: Colors.teal, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final flats = flatsAsync.value ?? [];
                final allMaintenance = maintenanceAsync.value ?? [];

                int currentMonthIdx = _financialYearMonths.indexOf(_selectedMonth);
                if (currentMonthIdx == -1) currentMonthIdx = 0;

                for (var flat in flats) {
                  final double rate = (flat.flatNumber == 'F202' || flat.flatNumber == 'F203') ? 300.0 : 600.0;

                  double prevCarryForward = 0.0;
                  for (int i = 0; i < currentMonthIdx; i++) {
                    final prevMonthStr = _financialYearMonths[i];
                    final prevRecs = allMaintenance.where(
                      (m) => m.flatNumber == flat.flatNumber && m.monthYear == prevMonthStr,
                    ).toList();

                    for (var pr in prevRecs) {
                      double uncollected = pr.amountDue - pr.amountPaid;
                      if (uncollected > 0) prevCarryForward += uncollected;
                    }
                  }

                  final docId = 'M-${_selectedMonth.replaceAll(' ', '')}-${flat.flatNumber}';
                  final existingRecs = allMaintenance.where((m) => m.flatNumber == flat.flatNumber && m.monthYear == _selectedMonth).toList();
                  
                  double existingPaid = 0.0;
                  String existingType = 'UPI';
                  DateTime? existingDate;
                  String status = 'Pending';
                  double totalDue = rate + prevCarryForward;

                  if (existingRecs.isNotEmpty) {
                    final ex = existingRecs.first;
                    existingPaid = ex.amountPaid;
                    existingType = ex.paymentType;
                    existingDate = ex.paymentDate;

                    if (ex.status == 'Paid' || ex.amountPaid >= rate) {
                      status = 'Paid';
                      if (existingPaid < totalDue) {
                        existingPaid = totalDue;
                      }
                    } else if (existingPaid > 0) {
                      status = 'Partial';
                    } else {
                      status = 'Pending';
                    }
                  } else {
                    status = 'Pending';
                  }

                  final record = MaintenanceRecord(
                    id: docId,
                    flatNumber: flat.flatNumber,
                    monthYear: _selectedMonth,
                    amountDue: totalDue,
                    amountPaid: existingPaid,
                    paymentType: existingType,
                    status: status,
                    paymentDate: existingDate,
                  );

                  await ref.read(maintenanceNotifierProvider.notifier).addMaintenanceBill(record);
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Dues for $_selectedMonth refreshed successfully!')),
                  );
                }
              },
              child: const Text('Generate / Refresh Dues'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final maintenanceAsync = ref.watch(maintenanceStreamProvider);
    final isAdmin = ref.watch(isAdminProvider);
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
                      'Maintenance Dues (FY 2026-27)',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        const Text('Select Month: ', style: TextStyle(fontWeight: FontWeight.w500)),
                        DropdownButton<String>(
                          value: _selectedMonth,
                          items: _financialYearMonths.map((m) {
                            return DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontWeight: FontWeight.bold)));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedMonth = val);
                          },
                        ),
                        const SizedBox(width: 8),

                        // TOTAL MAINTENANCE COLLECTED CHIP
                        Builder(
                          builder: (context) {
                            final allRecs = maintenanceAsync.value ?? [];
                            double totalAllTimeCollected = 0.0;
                            for (var r in allRecs) {
                              totalAllTimeCollected += r.amountPaid;
                            }

                            return Chip(
                              avatar: const Icon(Icons.account_balance_wallet, size: 16, color: Colors.white),
                              label: Text(
                                'Total Amount Collected: ₹${totalAllTimeCollected.toInt()}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              backgroundColor: Colors.teal.shade800,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                if (isAdmin)
                  ElevatedButton.icon(
                    onPressed: _showGenerateDuesDialog,
                    icon: const Icon(Icons.sync),
                    label: Text('Generate Dues for $_selectedMonth'),
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
            child: maintenanceAsync.when(
              data: (allRecords) {
                final Map<String, MaintenanceRecord> monthRecordsMap = {};
                for (var r in allRecords) {
                  if (r.monthYear == _selectedMonth) {
                    monthRecordsMap[r.flatNumber] = r;
                  }
                }
                final records = monthRecordsMap.values.toList();
                records.sort((a, b) => a.flatNumber.compareTo(b.flatNumber));

                if (records.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('No dues generated for $_selectedMonth yet.', style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _showGenerateDuesDialog,
                          icon: const Icon(Icons.add),
                          label: Text('Generate Dues for 8 Flats in $_selectedMonth'),
                        ),
                      ],
                    ),
                  );
                }

                double selectedMonthCollected = 0.0;
                double selectedMonthPending = 0.0;
                int defaultersCount = 0;

                for (var r in records) {
                  selectedMonthCollected += r.amountPaid;
                  selectedMonthPending += (r.amountDue - r.amountPaid);
                  if (r.status == 'Pending' || r.status == 'Partial') defaultersCount++;
                }

                return Column(
                  children: [
                    isMobile
                        ? Column(
                            children: [
                              Card(
                                color: Colors.green.shade50,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('$_selectedMonth Collected', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500)),
                                      Text('₹${selectedMonthCollected.toInt()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
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
                                      Text('$_selectedMonth Pending', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
                                      Text('₹${selectedMonthPending.toInt()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ),
                              Card(
                                color: Colors.orange.shade50,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Defaulter Flats', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500)),
                                      Text('$defaultersCount Flats', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
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
                                  color: Colors.green.shade50,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      children: [
                                        Text('$_selectedMonth Collected', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500)),
                                        const SizedBox(height: 4),
                                        Text('₹${selectedMonthCollected.toInt()}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
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
                                        Text('$_selectedMonth Pending', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
                                        const SizedBox(height: 4),
                                        Text('₹${selectedMonthPending.toInt()}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Card(
                                  color: Colors.orange.shade50,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      children: [
                                        const Text('Defaulter Flats', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500)),
                                        const SizedBox(height: 4),
                                        Text('$defaultersCount Flats', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                    const SizedBox(height: 16),

                    // Flat Dues List
                    Expanded(
                      child: ListView.builder(
                        itemCount: records.length,
                        itemBuilder: (context, index) {
                          final record = records[index];
                          final isPaid = record.status == 'Paid';
                          final isPartial = record.status == 'Partial';

                          Color badgeColor = Colors.red;
                          String badgeText = 'Unpaid';
                          if (isPaid) {
                            badgeColor = Colors.green;
                            badgeText = 'Paid 🟢';
                          } else if (isPartial) {
                            badgeColor = Colors.orange;
                            badgeText = 'Partial 🟠';
                          }

                          final double pending = record.amountDue - record.amountPaid;

                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: isMobile
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                  backgroundColor: badgeColor.withValues(alpha: 0.15),
                                                  radius: 16,
                                                  child: Text(record.flatNumber, style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 11)),
                                                ),
                                                const SizedBox(width: 8),
                                                Text('Flat ${record.flatNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                            Chip(
                                              label: Text(badgeText, style: const TextStyle(fontSize: 11)),
                                              backgroundColor: badgeColor.withValues(alpha: 0.15),
                                              labelStyle: TextStyle(color: badgeColor, fontWeight: FontWeight.bold),
                                              padding: EdgeInsets.zero,
                                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Due: ₹${record.amountDue.toInt()} | Paid: ₹${record.amountPaid.toInt()} | Pending: ₹${pending < 0 ? 0 : pending.toInt()} (${record.paymentType})',
                                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                                        ),
                                        if (isAdmin) ...[
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              ElevatedButton.icon(
                                                onPressed: () => _showRecordPaymentDialog(record),
                                                icon: const Icon(Icons.payment, size: 14),
                                                label: const Text('Record Payment', style: TextStyle(fontSize: 12)),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                  minimumSize: Size.zero,
                                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                icon: const Icon(Icons.edit, color: Colors.teal, size: 20),
                                                tooltip: 'Edit Entry',
                                                onPressed: () => _showPenEditDialog(record),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    )
                                  : ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: badgeColor.withValues(alpha: 0.15),
                                        child: Text(record.flatNumber, style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 13)),
                                      ),
                                      title: Row(
                                        children: [
                                          Text('Flat ${record.flatNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                          const SizedBox(width: 8),
                                          Chip(
                                            label: Text(badgeText, style: const TextStyle(fontSize: 11)),
                                            backgroundColor: badgeColor.withValues(alpha: 0.15),
                                            labelStyle: TextStyle(color: badgeColor, fontWeight: FontWeight.bold),
                                            padding: EdgeInsets.zero,
                                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                        ],
                                      ),
                                      subtitle: Text(
                                        'Due: ₹${record.amountDue.toInt()} | Paid: ₹${record.amountPaid.toInt()} | Pending: ₹${pending < 0 ? 0 : pending.toInt()}\nMode: ${record.paymentType}',
                                      ),
                                      trailing: isAdmin
                                          ? Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                ElevatedButton.icon(
                                                  onPressed: () => _showRecordPaymentDialog(record),
                                                  icon: const Icon(Icons.payment, size: 14),
                                                  label: const Text('Record Payment'),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.green,
                                                    foregroundColor: Colors.white,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  icon: const Icon(Icons.edit, color: Colors.teal),
                                                  tooltip: 'Edit Entry',
                                                  onPressed: () => _showPenEditDialog(record),
                                                ),
                                              ],
                                            )
                                          : null,
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
              error: (err, st) => Center(child: Text('Error loading maintenance dues: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
