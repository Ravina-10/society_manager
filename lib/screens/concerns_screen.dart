import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/concern.dart';
import '../providers/concerns_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/flats_provider.dart';

class ConcernsScreen extends ConsumerStatefulWidget {
  const ConcernsScreen({super.key});

  @override
  ConsumerState<ConcernsScreen> createState() => _ConcernsScreenState();
}

class _ConcernsScreenState extends ConsumerState<ConcernsScreen> {
  // Raise New Concern Dialog (Open to Everyone)
  void _showRaiseConcernDialog() {
    final flatsAsync = ref.read(flatsStreamProvider);
    final flats = flatsAsync.value ?? [];

    String selectedFlat = flats.isNotEmpty ? flats.first.flatNumber : 'F101';
    String residentName = flats.isNotEmpty ? flats.first.ownerName : 'Vitthal Mokashi';

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String category = 'Maintenance';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.report_problem, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Raise Society Concern / Complaint'),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 440,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedFlat,
                              decoration: const InputDecoration(labelText: 'Select Flat No'),
                              items: flats.map((f) {
                                return DropdownMenuItem(value: f.flatNumber, child: Text('${f.flatNumber} (${f.ownerName})'));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  final match = flats.firstWhere((f) => f.flatNumber == val);
                                  setDialogState(() {
                                    selectedFlat = val;
                                    residentName = match.ownerName;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: category,
                        decoration: const InputDecoration(labelText: 'Category'),
                        items: const [
                          DropdownMenuItem(value: 'Maintenance', child: Text('Maintenance & Repairs')),
                          DropdownMenuItem(value: 'Plumbing', child: Text('Plumbing & Water Leakage')),
                          DropdownMenuItem(value: 'Electrical', child: Text('Electrical & Passage Lighting')),
                          DropdownMenuItem(value: 'Noise/Dispute', child: Text('Noise & Resident Complaints')),
                          DropdownMenuItem(value: 'Security', child: Text('Security & Gate Entry')),
                          DropdownMenuItem(value: 'Other', child: Text('Other Issues')),
                        ],
                        onChanged: (val) => setDialogState(() => category = val!),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Subject / Issue Title',
                          hintText: 'e.g., Passage Light Bulb Blown on 2nd Floor',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Detailed Description of Concern',
                          hintText: 'Describe the issue or assistance needed...',
                        ),
                        maxLines: 4,
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
                    if (titleController.text.isEmpty || descriptionController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill subject and description')),
                      );
                      return;
                    }

                    final newConcern = Concern(
                      id: '',
                      title: titleController.text.trim(),
                      description: descriptionController.text.trim(),
                      category: category,
                      raisedBy: residentName,
                      flatNumber: selectedFlat,
                      dateRaised: DateTime.now(),
                      status: 'Open',
                    );

                    await ref.read(concernsNotifierProvider.notifier).raiseConcern(newConcern);

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Concern submitted successfully! Management notified.'), backgroundColor: Colors.teal),
                      );
                    }
                  },
                  child: const Text('Submit Concern'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Admin Reply / Comment Dialog (Restricted to Admin & Super Admin)
  void _showAdminReplyDialog(Concern concern) {
    final commentController = TextEditingController();
    String currentStatus = concern.status;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Admin Response - ${concern.flatNumber} (${concern.title})'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 440,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Raised By: ${concern.raisedBy} (${concern.flatNumber})', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(concern.description),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: currentStatus,
                        decoration: const InputDecoration(labelText: 'Update Concern Status'),
                        items: const [
                          DropdownMenuItem(value: 'Open', child: Text('🔴 Open (Needs Attention)')),
                          DropdownMenuItem(value: 'In Progress', child: Text('🟧 In Progress (Work Underway)')),
                          DropdownMenuItem(value: 'Resolved', child: Text('🟢 Resolved (Issue Solved)')),
                        ],
                        onChanged: (val) => setDialogState(() => currentStatus = val!),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: commentController,
                        decoration: const InputDecoration(
                          labelText: 'Official Admin Reply / Resolution Comment',
                          hintText: 'e.g., Electrician assigned, work scheduled for tomorrow 11 AM.',
                        ),
                        maxLines: 3,
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
                    if (commentController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a reply message')),
                      );
                      return;
                    }

                    final newComment = ConcernComment(
                      author: 'Martand Niwas Management',
                      comment: commentController.text.trim(),
                      timestamp: DateTime.now(),
                      isAdminReply: true,
                    );

                    await ref.read(concernsNotifierProvider.notifier).addAdminReply(concern.id, newComment, currentStatus);

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Admin reply added and status updated!'), backgroundColor: Colors.teal),
                      );
                    }
                  },
                  child: const Text('Save Reply'),
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
    final concernsAsync = ref.watch(concernsStreamProvider);
    final userRoleAsync = ref.watch(userRoleProvider);

    final String role = userRoleAsync.value ?? 'Admin';
    final bool isAdmin = role.toLowerCase() == 'admin' || role.toLowerCase() == 'super admin';

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
                      'Society Helpdesk & Raised Concerns',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAdmin
                          ? 'Admin Access: Reply, comment, & resolve concerns.'
                          : 'Resident Helpdesk: Everyone can raise a concern.',
                      style: TextStyle(color: isAdmin ? Colors.teal : Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _showRaiseConcernDialog,
                  icon: const Icon(Icons.add_alert),
                  label: const Text('Raise Concern'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: concernsAsync.when(
              data: (concerns) {
                if (concerns.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                        const SizedBox(height: 12),
                        const Text('No active resident concerns raised! All clear.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _showRaiseConcernDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Submit First Concern'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: concerns.length,
                  itemBuilder: (context, index) {
                    final c = concerns[index];

                    Color statusColor = Colors.red;
                    if (c.status == 'In Progress') {
                      statusColor = Colors.orange;
                    } else if (c.status == 'Resolved') {
                      statusColor = Colors.green;
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: statusColor.withValues(alpha: 0.15),
                                  radius: 18,
                                  child: Icon(
                                    c.status == 'Resolved' ? Icons.check_circle : Icons.warning_amber_rounded,
                                    color: statusColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c.title,
                                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'Raised by ${c.raisedBy} (${c.flatNumber}) | Category: ${c.category}',
                                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Chip(
                                  label: Text(c.status),
                                  backgroundColor: statusColor.withValues(alpha: 0.15),
                                  labelStyle: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                // ONLY ADMIN & SUPER ADMIN CAN REPLY OR COMMENT
                                if (isAdmin) ...[
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: () => _showAdminReplyDialog(c),
                                    icon: const Icon(Icons.reply, size: 14),
                                    label: const Text('Reply / Update Status', style: TextStyle(fontSize: 11)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                      minimumSize: const Size(0, 32),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    tooltip: 'Delete Concern Entry',
                                    onPressed: () => ref.read(concernsNotifierProvider.notifier).deleteConcern(c.id),
                                  ),
                                ],
                              ],
                            ),
                            const Divider(height: 20),
                            Text(
                              c.description,
                              style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black87),
                            ),
                            const SizedBox(height: 12),

                            // Admin Comments / Replies Thread
                            if (c.comments.isNotEmpty) ...[
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
                                    const Text('Management Committee Response:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.teal)),
                                    const SizedBox(height: 6),
                                    ...c.comments.map((cm) {
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 6.0),
                                        child: Text(
                                          '💬 ${cm.author}: ${cm.comment}',
                                          style: const TextStyle(fontSize: 13, color: Colors.black87),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Date Raised: ${c.dateRaised.day}/${c.dateRaised.month}/${c.dateRaised.year}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                Text('Status: ${c.status}', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(child: Text('Error loading concerns: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
