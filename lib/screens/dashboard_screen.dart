import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/flats_provider.dart';
import '../providers/maintenance_provider.dart';
import '../providers/expenses_provider.dart';
import '../providers/notices_provider.dart';
import '../providers/concerns_provider.dart';
import '../services/seed_service.dart';
import 'flats_screen.dart';
import 'maintenance_screen.dart';
import 'expenses_screen.dart';
import 'notices_screen.dart';
import 'users_screen.dart';
import 'balance_sheet_screen.dart';
import 'concerns_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    try {
      SeedService.seedMartandNiwasData();
    } catch (_) {}
  }

  Widget _buildRichOverviewContent() {
    final flatsAsync = ref.watch(flatsStreamProvider);
    final maintenanceAsync = ref.watch(maintenanceStreamProvider);
    final expensesAsync = ref.watch(expensesStreamProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;
        final bool isMobile = screenWidth < 750;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Responsive Header Banner
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.teal.shade800,
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.apartment, color: Colors.teal, size: 28),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Martand Niwas Society',
                                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Management Dashboard',
                                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          if (!isMobile)
                            ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  await SeedService.seedMartandNiwasData();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Martand Niwas data synchronized successfully!')),
                                    );
                                  }
                                } catch (_) {}
                              },
                              icon: const Icon(Icons.sync, size: 18),
                              label: const Text('Sync Data'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.teal.shade900,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Overview of society flats, maintenance collections, defaulters, expenses, notices, and raised concerns.',
                        style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                      ),
                      if (isMobile) ...[
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                await SeedService.seedMartandNiwasData();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Martand Niwas data synchronized successfully!')),
                                  );
                                }
                              } catch (_) {}
                            },
                            icon: const Icon(Icons.sync, size: 18),
                            label: const Text('Sync Data'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.teal.shade900,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // KPI Metrics Grid
              LayoutBuilder(
                builder: (context, kpiConstraints) {
                  final double width = kpiConstraints.maxWidth;
                  final int crossAxisCount = width > 900 ? 4 : (width > 550 ? 2 : 1);
                  final double aspectRatio = width < 600 ? 2.4 : (width < 900 ? 2.0 : 1.8);

                  final totalFlats = flatsAsync.value?.length ?? 8;
                  final maintenanceList = maintenanceAsync.value ?? [];
                  final expensesList = expensesAsync.value ?? [];

                  double totalCollected = 0.0;
                  double totalPending = 0.0;
                  int defaultersCount = 0;

                  for (var m in maintenanceList) {
                    totalCollected += m.amountPaid;
                    totalPending += (m.amountDue - m.amountPaid);
                    if (m.status == 'Pending') defaultersCount++;
                  }

                  double totalExpenses = expensesList.fold(0.0, (sum, item) => sum + item.amount);

                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: aspectRatio,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildKpiCard('Total Flats', '$totalFlats Flats', 'Occupied: 8', Icons.home_work, Colors.blue),
                      _buildKpiCard('Total Collected', '₹$totalCollected', 'Aug 2026 Collection', Icons.account_balance_wallet, Colors.green),
                      _buildKpiCard('Pending Dues', '₹$totalPending', '$defaultersCount Defaulter Flats', Icons.warning_amber_rounded, Colors.red),
                      _buildKpiCard('Society Expenses', '₹$totalExpenses', 'Total Logged Expenses', Icons.money_off, Colors.orange),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),

              // Quick Operations Row
              const Text('Quick Operations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.report_problem, color: Colors.deepOrange),
                    label: const Text('Raise / View Concerns'),
                    onPressed: () => setState(() => _selectedIndex = 7),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.campaign, color: Colors.purple),
                    label: const Text('Post / View Notices'),
                    onPressed: () => setState(() => _selectedIndex = 4),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.receipt_long, color: Colors.teal),
                    label: const Text('Manage Dues & Payments'),
                    onPressed: () => setState(() => _selectedIndex = 2),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.menu_book, color: Colors.indigo),
                    label: const Text('Society Balance Sheet'),
                    onPressed: () => setState(() => _selectedIndex = 6),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.account_balance_wallet, color: Colors.orange),
                    label: const Text('Add / View Expenses'),
                    onPressed: () => setState(() => _selectedIndex = 3),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.apartment, color: Colors.blue),
                    label: const Text('Flats Directory'),
                    onPressed: () => setState(() => _selectedIndex = 1),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Raised Concerns & Helpdesk Section on Dashboard
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('🚨 Raised Resident Concerns & Helpdesk', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => setState(() => _selectedIndex = 7),
                    child: const Text('Open Helpdesk ->'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final concernsAsync = ref.watch(concernsStreamProvider);
                  return concernsAsync.when(
                    data: (concerns) {
                      if (concerns.isEmpty) {
                        return const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('No active resident concerns raised.'),
                          ),
                        );
                      }
                      final topConcerns = concerns.take(3).toList();
                      return Card(
                        child: Column(
                          children: topConcerns.map((c) {
                            Color sColor = c.status == 'Resolved'
                                ? Colors.green
                                : (c.status == 'In Progress' ? Colors.orange : Colors.red);
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: sColor.withValues(alpha: 0.15),
                                child: Icon(Icons.report_problem, color: sColor, size: 20),
                              ),
                              title: Text('${c.title} (${c.flatNumber})', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                'Raised by ${c.raisedBy} | ${c.description}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Chip(
                                label: Text(c.status),
                                backgroundColor: sColor.withValues(alpha: 0.1),
                                labelStyle: TextStyle(color: sColor, fontSize: 11, fontWeight: FontWeight.bold),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onTap: () => setState(() => _selectedIndex = 7),
                            );
                          }).toList(),
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (err, st) => const SizedBox.shrink(),
                  );
                },
              ),
              const SizedBox(height: 28),

              // Active Society Announcements & Notices Section on Dashboard
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('📢 Active Announcements & Notices', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => setState(() => _selectedIndex = 4),
                    child: const Text('Open Notice Board ->'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final noticesAsync = ref.watch(noticesStreamProvider);
                  return noticesAsync.when(
                    data: (notices) {
                      if (notices.isEmpty) {
                        return const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('No active notices published yet.'),
                          ),
                        );
                      }
                      final topNotices = notices.take(3).toList();
                      return Card(
                        child: Column(
                          children: topNotices.map((n) {
                            Color pColor = n.priority == 'Urgent'
                                ? Colors.red
                                : (n.priority == 'Important' ? Colors.orange : Colors.green);
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: pColor.withValues(alpha: 0.15),
                                child: Icon(Icons.campaign, color: pColor, size: 20),
                              ),
                              title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                n.content.length > 90 ? '${n.content.substring(0, 90)}...' : n.content,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Chip(
                                label: Text(n.priority),
                                backgroundColor: pColor.withValues(alpha: 0.1),
                                labelStyle: TextStyle(color: pColor, fontSize: 11, fontWeight: FontWeight.bold),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onTap: () => setState(() => _selectedIndex = 4),
                            );
                          }).toList(),
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (err, st) => const SizedBox.shrink(),
                  );
                },
              ),
              const SizedBox(height: 28),

              // Aug 2026 Dues Status Summary
              const Text('Aug 2026 Dues Status Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.flag, color: Colors.red),
                        title: const Text('Pending Dues Defaulters List', style: TextStyle(fontWeight: FontWeight.bold)),
                        trailing: TextButton(
                          onPressed: () => setState(() => _selectedIndex = 2),
                          child: const Text('View All Records ->'),
                        ),
                      ),
                      const Divider(),
                      ...[
                        {'flat': 'F001 - Manohar Mokashi', 'due': '600'},
                        {'flat': 'F102 - Tushar Mokashi', 'due': '600'},
                        {'flat': 'F201 - Mahesh Mokashi', 'due': '600'},
                        {'flat': 'F203 - Manali Pagade', 'due': '300'},
                        {'flat': 'F302 - Vikas Mokashi', 'due': '600'},
                      ].map((item) {
                        return isMobile
                            ? Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Flat ${item['flat']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Due: ₹${item['due']} | Status: Unpaid', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                        ElevatedButton.icon(
                                          onPressed: () => setState(() => _selectedIndex = 2),
                                          icon: const Icon(Icons.payment, size: 12),
                                          label: const Text('Record', style: TextStyle(fontSize: 12)),
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(),
                                  ],
                                ),
                              )
                            : ListTile(
                                title: Text('Flat ${item['flat']}'),
                                subtitle: Text('Due: ₹${item['due']} | Status: Unpaid'),
                                trailing: ElevatedButton.icon(
                                  onPressed: () => setState(() => _selectedIndex = 2),
                                  icon: const Icon(Icons.payment, size: 14),
                                  label: const Text('Record Payment'),
                                ),
                              );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKpiCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              radius: 22,
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.black54), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileDialog() {
    final user = ref.read(authStateChangesProvider).value;
    final String phone = (user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty)
        ? user.phoneNumber!
        : 'Registered User';
    final String role = ref.read(userRoleProvider).value ?? 'Resident';

    String permissions = 'Read-Only Resident / Viewer Access';
    if (role.toLowerCase() == 'super admin') {
      permissions = 'Full Read, Write, Edit & Management Access';
    } else if (role.toLowerCase() == 'admin') {
      permissions = 'Standard Admin (Management & Operations Access)';
    }

    showDialog(
      context: context,
      builder: (context) {
        final double screenWidth = MediaQuery.of(context).size.width;
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.person, color: Colors.teal),
              SizedBox(width: 8),
              Text('My Profile & Access'),
            ],
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: screenWidth < 500 ? screenWidth * 0.85 : 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Registered Mobile: $phone', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Assigned Role: $role'),
                const SizedBox(height: 8),
                Text('Permissions: $permissions'),
              ],
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

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      // 0: Rich Dashboard Overview
      _buildRichOverviewContent(),

      // 1: Flats Screen
      const FlatsScreen(),

      // 2: Maintenance & Dues Screen
      const MaintenanceScreen(),

      // 3: Expenses Screen
      const ExpensesScreen(),

      // 4: Notice Board Screen
      const NoticesScreen(),

      // 5: User Access & Role Management Screen
      const UsersScreen(),

      // 6: Society Balance Sheet Screen
      const BalanceSheetScreen(),

      // 7: Raised Concerns & Helpdesk Screen
      const ConcernsScreen(),
    ];

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth >= 900;
    final bool isMobile = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Martand Niwas Society'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: 'My Profile & Access',
            onPressed: _showProfileDialog,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              ref.read(authNotifierProvider.notifier).signOut();
            },
          )
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.teal,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Martand Niwas',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Society Management System',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Overview'),
              selected: _selectedIndex == 0,
              onTap: () {
                setState(() => _selectedIndex = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_problem, color: Colors.deepOrange),
              title: const Text('Raised Concerns & Helpdesk'),
              selected: _selectedIndex == 7,
              onTap: () {
                setState(() => _selectedIndex = 7);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.apartment),
              title: const Text('Flats & Members'),
              selected: _selectedIndex == 1,
              onTap: () {
                setState(() => _selectedIndex = 1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Maintenance & Dues'),
              selected: _selectedIndex == 2,
              onTap: () {
                setState(() => _selectedIndex = 2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.menu_book, color: Colors.indigo),
              title: const Text('Society Balance Sheet'),
              selected: _selectedIndex == 6,
              onTap: () {
                setState(() => _selectedIndex = 6);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('Expenses'),
              selected: _selectedIndex == 3,
              onTap: () {
                setState(() => _selectedIndex = 3);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.campaign),
              title: const Text('Notice Board'),
              selected: _selectedIndex == 4,
              onTap: () {
                setState(() => _selectedIndex = 4);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings, color: Colors.teal),
              title: const Text('User Roles & Access Control'),
              selected: _selectedIndex == 5,
              onTap: () {
                setState(() => _selectedIndex = 5);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('My Profile'),
              onTap: () {
                Navigator.pop(context);
                _showProfileDialog();
              },
            ),
          ],
        ),
      ),
      body: isDesktop
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) => setState(() => _selectedIndex = index),
                  labelType: NavigationRailLabelType.all,
                  selectedIconTheme: const IconThemeData(color: Colors.teal),
                  selectedLabelTextStyle: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
                  destinations: const [
                    NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('Overview')),
                    NavigationRailDestination(icon: Icon(Icons.apartment), label: Text('Flats')),
                    NavigationRailDestination(icon: Icon(Icons.receipt_long), label: Text('Dues')),
                    NavigationRailDestination(icon: Icon(Icons.account_balance_wallet), label: Text('Expenses')),
                    NavigationRailDestination(icon: Icon(Icons.campaign), label: Text('Notices')),
                    NavigationRailDestination(icon: Icon(Icons.admin_panel_settings), label: Text('Users')),
                    NavigationRailDestination(icon: Icon(Icons.menu_book), label: Text('Balance')),
                    NavigationRailDestination(icon: Icon(Icons.report_problem), label: Text('Helpdesk')),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: pages[_selectedIndex]),
              ],
            )
          : pages[_selectedIndex],
      bottomNavigationBar: isMobile
          ? BottomNavigationBar(
              currentIndex: _selectedIndex > 4 ? 0 : _selectedIndex,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Colors.teal,
              unselectedItemColor: Colors.grey,
              onTap: (index) {
                if (index == 4) {
                  // Open Drawer for all items
                  Scaffold.of(context).openDrawer();
                } else {
                  setState(() => _selectedIndex = index);
                }
              },
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Overview'),
                BottomNavigationBarItem(icon: Icon(Icons.apartment), label: 'Flats'),
                BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Dues'),
                BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Expenses'),
                BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'More'),
              ],
            )
          : null,
    );
  }
}
