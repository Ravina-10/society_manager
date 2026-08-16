import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/flat.dart';
import '../providers/flats_provider.dart';
import '../providers/auth_provider.dart';

class FlatsScreen extends ConsumerStatefulWidget {
  const FlatsScreen({super.key});

  @override
  ConsumerState<FlatsScreen> createState() => _FlatsScreenState();
}

class _FlatsScreenState extends ConsumerState<FlatsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  void _showAddEditFlatDialog([Flat? flat]) {
    final flatNumberController = TextEditingController(text: flat?.flatNumber ?? '');
    final ownerNameController = TextEditingController(text: flat?.ownerName ?? '');
    final ownerPhoneController = TextEditingController(text: flat?.ownerPhone ?? '');
    final tenantNameController = TextEditingController(text: flat?.tenantName ?? '');
    final tenantPhoneController = TextEditingController(text: flat?.tenantPhone ?? '');
    bool isOccupied = flat?.isOccupied ?? true;

    final double screenWidth = MediaQuery.of(context).size.width;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(flat == null ? 'Add New Flat Entry' : 'Edit Flat Entry (${flat.flatNumber})'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: screenWidth < 500 ? screenWidth * 0.85 : 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: flatNumberController,
                        decoration: const InputDecoration(labelText: 'Flat Number (e.g. F101)'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: ownerNameController,
                        decoration: const InputDecoration(labelText: 'Owner Full Name'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: ownerPhoneController,
                        decoration: const InputDecoration(labelText: 'Owner Phone Number'),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('Flat Occupied'),
                        value: isOccupied,
                        onChanged: (val) => setDialogState(() => isOccupied = val),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: tenantNameController,
                        decoration: const InputDecoration(labelText: 'Tenant Name (Optional)'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: tenantPhoneController,
                        decoration: const InputDecoration(labelText: 'Tenant Phone (Optional)'),
                        keyboardType: TextInputType.phone,
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
                    if (flatNumberController.text.isEmpty || ownerNameController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter flat number and owner name')),
                      );
                      return;
                    }

                    final newFlat = Flat(
                      id: flat?.id ?? flatNumberController.text.trim(),
                      flatNumber: flatNumberController.text.trim(),
                      ownerName: ownerNameController.text.trim(),
                      ownerPhone: ownerPhoneController.text.trim(),
                      tenantName: tenantNameController.text.trim().isEmpty ? null : tenantNameController.text.trim(),
                      tenantPhone: tenantPhoneController.text.trim().isEmpty ? null : tenantPhoneController.text.trim(),
                      isOccupied: isOccupied,
                    );

                    await FirebaseFirestore.instance
                        .collection('flats')
                        .doc(newFlat.id)
                        .set(newFlat.toMap(), SetOptions(merge: true));

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Flat entry saved successfully!'), backgroundColor: Colors.teal),
                      );
                    }
                  },
                  child: const Text('Save Flat'),
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
    final flatsAsync = ref.watch(flatsStreamProvider);
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
                const Text(
                  'Flats & Members Directory',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                if (isAdmin)
                  ElevatedButton.icon(
                    onPressed: () => _showAddEditFlatDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Flat Entry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search by flat number or owner name...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: flatsAsync.when(
              data: (flats) {
                final filtered = flats.where((f) {
                  return f.flatNumber.toLowerCase().contains(_searchQuery) ||
                      f.ownerName.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No flats found matching query.'));
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 320,
                    mainAxisExtent: 200,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final flat = filtered[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Flat ${flat.flatNumber}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                if (isAdmin)
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 20, color: Colors.teal),
                                        tooltip: 'Edit Flat Entry',
                                        onPressed: () => _showAddEditFlatDialog(flat),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                        tooltip: 'Delete Flat Entry',
                                        onPressed: () async {
                                          await FirebaseFirestore.instance.collection('flats').doc(flat.id).delete();
                                        },
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            const Divider(),
                            Text('👤 Owner: ${flat.ownerName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Builder(
                              builder: (context) {
                                final users = ref.watch(usersStreamProvider).value ?? [];
                                String phone = flat.ownerPhone;
                                if (phone.isEmpty) {
                                  for (var u in users) {
                                    final uName = (u['name'] as String?)?.toLowerCase() ?? '';
                                    if (uName.contains(flat.ownerName.toLowerCase())) {
                                      phone = (u['phoneNumber'] as String?) ?? '';
                                      break;
                                    }
                                  }
                                }
                                return Text(
                                  '📞 Phone: ${phone.isEmpty ? "Not Provided" : phone}',
                                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                                );
                              },
                            ),
                            if (flat.tenantName != null && flat.tenantName!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text('🔑 Tenant: ${flat.tenantName}'),
                            ],
                            const Spacer(),
                            Chip(
                              label: Text(flat.isOccupied ? 'Occupied' : 'Vacant'),
                              backgroundColor: flat.isOccupied ? Colors.green.shade100 : Colors.orange.shade100,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(child: Text('Error loading flats: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
