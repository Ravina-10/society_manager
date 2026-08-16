import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../providers/flats_provider.dart';
import '../providers/maintenance_provider.dart';
import '../providers/expenses_provider.dart';
import '../models/flat.dart';
import '../models/maintenance.dart';
import '../models/expense.dart';
import '../utils/pdf_download_web.dart';

class BalanceSheetScreen extends ConsumerStatefulWidget {
  const BalanceSheetScreen({super.key});

  @override
  ConsumerState<BalanceSheetScreen> createState() => _BalanceSheetScreenState();
}

class _BalanceSheetScreenState extends ConsumerState<BalanceSheetScreen> {
  String _tillMonth = 'Aug 2026';

  final List<String> _monthsInOrder = [
    'Aug 2026',
    'Sep 2026',
    'Oct 2026',
    'Nov 2026',
    'Dec 2026',
    'Jan 2027',
    'Feb 2027',
    'Mar 2027',
  ];

  List<String> _getIncludedMonths() {
    int idx = _monthsInOrder.indexOf(_tillMonth);
    if (idx == -1) idx = 0;
    return _monthsInOrder.sublist(0, idx + 1);
  }

  // 1. Instant Direct PDF Download with Clean Column Widths & Expense Ledger
  Future<void> _exportPdfLedger(
    List<Flat> flats,
    List<MaintenanceRecord> maintenanceList,
    List<Expense> expensesList,
  ) async {
    try {
      final pdf = pw.Document();
      final includedMonths = _getIncludedMonths();
      final int numberOfMonths = includedMonths.length;

      double totalCollected = 0.0;
      double totalPending = 0.0;

      final List<List<String>> flatTableData = [];

      for (var flat in flats) {
        final double rate = (flat.flatNumber == 'F202' || flat.flatNumber == 'F203') ? 300.0 : 600.0;
        final double expectedDue = rate * numberOfMonths;

        final flatRecords = maintenanceList.where(
          (m) => m.flatNumber == flat.flatNumber && includedMonths.contains(m.monthYear),
        ).toList();

        double paid = 0.0;
        for (var r in flatRecords) {
          paid += r.amountPaid;
        }
        if (paid > expectedDue) paid = expectedDue;

        double pending = expectedDue - paid;
        if (pending < 0) pending = 0.0;

        totalCollected += paid;
        totalPending += pending;

        final bool isClear = pending == 0;

        flatTableData.add([
          flat.flatNumber,
          flat.ownerName,
          'Rs. ${rate.toInt()}/mo',
          'Rs. ${expectedDue.toInt()}',
          'Rs. ${paid.toInt()}',
          'Rs. ${pending.toInt()}',
          isClear ? 'All Clear' : 'Outstanding',
        ]);
      }

      double clearedExpenses = expensesList.where((e) => e.isCleared).fold(0.0, (sum, e) => sum + e.amount);
      double netBalance = totalCollected - clearedExpenses;

      // Expenses Table Data
      final List<List<String>> expenseTableData = [];
      for (var exp in expensesList) {
        final String paidBy = exp.paidBy ?? '';
        final String paidTo = exp.paidTo ?? '';

        expenseTableData.add([
          exp.title,
          exp.category,
          paidBy.isNotEmpty ? paidBy : 'Society Fund',
          paidTo.isNotEmpty ? paidTo : '-',
          'Rs. ${exp.amount.toInt()}',
          exp.isCleared ? 'Cleared' : 'Pending Bill',
        ]);
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (pw.Context context) {
            return [
              // Document Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'MARTAND NIWAS SOCIETY',
                        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900),
                      ),
                      pw.Text(
                        'Complete Financial Ledger (FY 2026-27)',
                        style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.teal100,
                      borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Text('Period: Till $_tillMonth', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.teal900)),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),

              // Overview Financial Summary Cards
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  color: PdfColors.grey100,
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Column(children: [
                      pw.Text('Total Collections', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                      pw.Text('Rs. ${totalCollected.toInt()}', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                    ]),
                    pw.Column(children: [
                      pw.Text('Pending Dues', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                      pw.Text('Rs. ${totalPending.toInt()}', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
                    ]),
                    pw.Column(children: [
                      pw.Text('Cleared Expenses', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                      pw.Text('Rs. ${clearedExpenses.toInt()}', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.orange800)),
                    ]),
                    pw.Column(children: [
                      pw.Text('Net Cash Balance', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                      pw.Text('Rs. ${netBalance.toInt()}', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
                    ]),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // 1. Flat-Wise Financial Ledger Table (Strict Column Widths to Prevent Text Wrapping)
              pw.Text('1. Flat-Wise Dues & Collections Ledger', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
              pw.SizedBox(height: 6),

              pw.TableHelper.fromTextArray(
                headers: ['Flat', 'Owner Name', 'Monthly Rate', 'Total Due', 'Total Paid', 'Pending', 'Status'],
                data: flatTableData,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.teal700),
                cellStyle: const pw.TextStyle(fontSize: 8.5),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 6),
                columnWidths: {
                  0: const pw.FixedColumnWidth(40),
                  1: const pw.FlexColumnWidth(2.5),
                  2: const pw.FixedColumnWidth(75),
                  3: const pw.FixedColumnWidth(60),
                  4: const pw.FixedColumnWidth(60),
                  5: const pw.FixedColumnWidth(60),
                  6: const pw.FixedColumnWidth(75),
                },
              ),
              pw.SizedBox(height: 20),

              // 2. Society Expenses Breakdown Table
              pw.Text('2. Society Expenses & Bills Details', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
              pw.SizedBox(height: 6),

              if (expenseTableData.isEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  alignment: pw.Alignment.center,
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300)),
                  child: pw.Text('No society expenses logged for this period yet.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                )
              else
                pw.TableHelper.fromTextArray(
                  headers: ['Expense Title', 'Category', 'Paid By', 'Paid To (Vendor)', 'Amount', 'Status'],
                  data: expenseTableData,
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.orange800),
                  cellStyle: const pw.TextStyle(fontSize: 8.5),
                  cellAlignment: pw.Alignment.centerLeft,
                  cellPadding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 6),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2.2),
                    1: const pw.FlexColumnWidth(1.5),
                    2: const pw.FlexColumnWidth(1.8),
                    3: const pw.FlexColumnWidth(1.8),
                    4: const pw.FixedColumnWidth(65),
                    5: const pw.FixedColumnWidth(75),
                  },
                ),

              pw.SizedBox(height: 16),
              pw.Divider(color: PdfColors.grey400),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Martand Niwas Society Management Web App', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  pw.Text('Generated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} ${DateTime.now().hour}:${DateTime.now().minute}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                ],
              ),
            ];
          },
        ),
      );

      final pdfBytes = await pdf.save();
      final filename = 'Martand_Niwas_Balance_Sheet_${_tillMonth.replaceAll(' ', '_')}.pdf';

      WebDownloader.downloadBytes(pdfBytes, filename, 'application/pdf');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloading $filename... Check your Downloads folder!'), backgroundColor: Colors.teal),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // 2. Direct CSV Spreadsheet Download with Expense Ledger
  void _exportCsvLedger(
    List<Flat> flats,
    List<MaintenanceRecord> maintenanceList,
    List<Expense> expensesList,
  ) {
    final includedMonths = _getIncludedMonths();
    final int numberOfMonths = includedMonths.length;

    final StringBuffer csv = StringBuffer();
    csv.writeln('MARTAND NIWAS SOCIETY BALANCE SHEET (FY 2026-27) - Period: Till $_tillMonth');
    csv.writeln('');
    csv.writeln('--- 1. FLAT-WISE MAINTENANCE LEDGER ---');
    csv.writeln('Flat No,Owner Name,Monthly Rate,Total Due (INR),Total Paid (INR),Outstanding Pending (INR),Status');

    for (var flat in flats) {
      final double rate = (flat.flatNumber == 'F202' || flat.flatNumber == 'F203') ? 300.0 : 600.0;
      final double expectedDue = rate * numberOfMonths;

      final flatRecords = maintenanceList.where(
        (m) => m.flatNumber == flat.flatNumber && includedMonths.contains(m.monthYear),
      ).toList();

      double paid = 0.0;
      for (var r in flatRecords) {
        paid += r.amountPaid;
      }
      if (paid > expectedDue) paid = expectedDue;

      double pending = expectedDue - paid;
      if (pending < 0) pending = 0.0;

      final bool isClear = pending == 0;

      csv.writeln('${flat.flatNumber},"${flat.ownerName}",$rate,$expectedDue,$paid,$pending,${isClear ? "All Clear" : "Dues Outstanding"}');
    }

    csv.writeln('');
    csv.writeln('--- 2. SOCIETY EXPENSES LEDGER ---');
    csv.writeln('Expense Title,Category,Paid By,Paid To (Vendor),Amount (INR),Status');

    for (var exp in expensesList) {
      csv.writeln('"${exp.title}","${exp.category}","${exp.paidBy}","${exp.paidTo}",${exp.amount},${exp.isCleared ? "Cleared" : "Pending Bill"}');
    }

    final bytes = utf8.encode(csv.toString());
    final filename = 'Martand_Niwas_Ledger_${_tillMonth.replaceAll(' ', '_')}.csv';

    WebDownloader.downloadBytes(bytes, filename, 'text/csv');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloading $filename...'), backgroundColor: Colors.teal),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final flatsAsync = ref.watch(flatsStreamProvider);
    final maintenanceAsync = ref.watch(maintenanceStreamProvider);
    final expensesAsync = ref.watch(expensesStreamProvider);

    final includedMonths = _getIncludedMonths();
    final int numberOfMonths = includedMonths.length;

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
                      'Society Balance Sheet & Financial Ledger',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Text('Show Dues Till Month: ', style: TextStyle(fontWeight: FontWeight.w500)),
                        DropdownButton<String>(
                          value: _tillMonth,
                          items: _monthsInOrder.map((m) {
                            return DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontWeight: FontWeight.bold)));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _tillMonth = val);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                  final flats = flatsAsync.value ?? [];
                  final maintenance = maintenanceAsync.value ?? [];
                  final expenses = expensesAsync.value ?? [];

                  if (flats.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Flats data loading... please try again.')),
                    );
                    return;
                  }

                  await _exportPdfLedger(flats, maintenance, expenses);
                },
                icon: const Icon(Icons.download),
                label: const Text('Download PDF Balance Sheet'),
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

          // Overview Financial Metrics
          Builder(
            builder: (context) {
              final flats = flatsAsync.value ?? [];
              final maintenanceList = maintenanceAsync.value ?? [];
              final expensesList = expensesAsync.value ?? [];

              double totalCollected = 0.0;
              double totalPending = 0.0;

              for (var flat in flats) {
                final double rate = (flat.flatNumber == 'F202' || flat.flatNumber == 'F203') ? 300.0 : 600.0;
                final double expectedDue = rate * numberOfMonths;

                final flatRecords = maintenanceList.where(
                  (m) => m.flatNumber == flat.flatNumber && includedMonths.contains(m.monthYear),
                ).toList();

                double paid = 0.0;
                for (var r in flatRecords) {
                  paid += r.amountPaid;
                }
                if (paid > expectedDue) paid = expectedDue;

                double pending = expectedDue - paid;
                if (pending < 0) pending = 0.0;

                totalCollected += paid;
                totalPending += pending;
              }

              double totalExpenses = expensesList.fold(0.0, (sum, e) => sum + e.amount);
              double clearedExpenses = expensesList.where((e) => e.isCleared).fold(0.0, (sum, e) => sum + e.amount);
              double netBalance = totalCollected - clearedExpenses;

              final int gridCols = screenWidth > 900 ? 4 : (screenWidth > 550 ? 2 : 1);

              return GridView.count(
                crossAxisCount: gridCols,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: screenWidth < 600 ? 2.5 : 2.0,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Collected Dues (Till $_tillMonth)', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('₹$totalCollected', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                    ),
                  ),
                  Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Pending Dues (Till $_tillMonth)', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('₹$totalPending', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                        ],
                      ),
                    ),
                  ),
                  Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Total Logged Expenses', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('₹$totalExpenses', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                        ],
                      ),
                    ),
                  ),
                  Card(
                    color: Colors.teal.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Net Cash Balance', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.w500, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('₹$netBalance', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Flat-Wise Detailed Balance Sheet Table
          Text('Flat-Wise Financial Ledger (Till $_tillMonth)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Expanded(
            child: flatsAsync.when(
              data: (flats) {
                final maintenanceList = maintenanceAsync.value ?? [];

                return Card(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Flat No', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Owner Name', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Monthly Rate', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Total Due (₹)', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Total Paid (₹)', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Outstanding Pending (₹)', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Account Status', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: flats.map((flat) {
                          final double rate = (flat.flatNumber == 'F202' || flat.flatNumber == 'F203') ? 300.0 : 600.0;
                          final double expectedDue = rate * numberOfMonths;

                          final flatRecords = maintenanceList.where(
                            (m) => m.flatNumber == flat.flatNumber && includedMonths.contains(m.monthYear),
                          ).toList();

                          double paid = 0.0;
                          for (var r in flatRecords) {
                            paid += r.amountPaid;
                          }
                          if (paid > expectedDue) paid = expectedDue;

                          double pending = expectedDue - paid;
                          if (pending < 0) pending = 0.0;

                          final bool isClear = pending == 0;

                          return DataRow(
                            cells: [
                              DataCell(Text(flat.flatNumber, style: const TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(Text(flat.ownerName)),
                              DataCell(Text('₹$rate / mo')),
                              DataCell(Text('₹$expectedDue')),
                              DataCell(Text('₹$paid', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                              DataCell(Text('₹$pending', style: TextStyle(color: isClear ? Colors.green : Colors.red, fontWeight: FontWeight.bold))),
                              DataCell(
                                Chip(
                                  label: Text(isClear ? 'All Clear' : 'Dues Outstanding'),
                                  backgroundColor: isClear ? Colors.green.shade100 : Colors.red.shade100,
                                  labelStyle: TextStyle(color: isClear ? Colors.green.shade900 : Colors.red.shade900, fontSize: 12),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(child: Text('Error loading ledger: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
