import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notice.dart';
import '../providers/notices_provider.dart';
import '../providers/auth_provider.dart';

class NoticesScreen extends ConsumerStatefulWidget {
  const NoticesScreen({super.key});

  @override
  ConsumerState<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends ConsumerState<NoticesScreen> {
  void _showAddEditNoticeDialog([Notice? noticeToEdit]) {
    final titleController = TextEditingController(text: noticeToEdit?.title ?? '');
    final contentController = TextEditingController(text: noticeToEdit?.content ?? '');
    String category = noticeToEdit?.category ?? 'General';
    String priority = noticeToEdit?.priority ?? 'Normal';
    String selectedTemplate = 'Custom';

    // Pre-built Notice Templates
    final Map<String, Map<String, String>> templates = {
      'AGM Meeting': {
        'title': 'Annual General Body Meeting (AGM) Notice',
        'category': 'Meeting',
        'priority': 'Important',
        'content':
            'Dear Society Members, all residents of Martand Niwas are requested to attend the upcoming General Body Meeting.\n\nAgenda:\n1. Monthly maintenance & financial report review\n2. Water tank cleaning schedule\n3. Security & passage lighting updates\n\nDate: Sunday | Time: 10:00 AM | Venue: Society Premises.',
      },
      'Water Supply': {
        'title': 'Scheduled Water Tank Cleaning & Water Supply Alert',
        'category': 'Maintenance',
        'priority': 'Important',
        'content':
            'Please note that overhead water tank cleaning is scheduled for tomorrow. Water supply will be temporarily paused between 10:00 AM and 2:00 PM. All members are requested to store sufficient water in advance.',
      },
      'Power Cut': {
        'title': 'Electrical Maintenance & Temporary Power Outage',
        'category': 'Maintenance',
        'priority': 'Important',
        'content':
            'MSEB scheduled maintenance work will take place tomorrow. Temporary power outage expected between 11:00 AM and 3:00 PM. Please disconnect heavy appliances during this time.',
      },
      'Pest Control': {
        'title': 'Society Passage Pest Control & Deep Cleaning',
        'category': 'General',
        'priority': 'Normal',
        'content':
            'Society common area pest control spray and staircase cleaning is scheduled for Saturday morning. Kindly keep main flat doors closed during spraying.',
      },
      'Urgent Security': {
        'title': 'Urgent Security & Visitor Entry Guidelines',
        'category': 'Emergency',
        'priority': 'Urgent',
        'content':
            'All residents are strictly requested to instruct delivery personnel and visitors to register entry at the main gate security before entry.',
      },
    };

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(noticeToEdit == null ? 'Post New Society Notice' : 'Edit Notice'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 440,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Template Selection Dropdown
                      if (noticeToEdit == null) ...[
                        const Text('Quick Notice Template (Optional):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          initialValue: selectedTemplate,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Custom', child: Text('✏️ Custom Blank Notice')),
                            DropdownMenuItem(value: 'AGM Meeting', child: Text('📢 AGM / General Meeting Notice')),
                            DropdownMenuItem(value: 'Water Supply', child: Text('💧 Water Tanker & Supply Alert')),
                            DropdownMenuItem(value: 'Power Cut', child: Text('⚡ Electrical / Power Cut Alert')),
                            DropdownMenuItem(value: 'Pest Control', child: Text('🧹 Pest Control & Cleaning')),
                            DropdownMenuItem(value: 'Urgent Security', child: Text('🚨 Urgent Security Announcement')),
                          ],
                          onChanged: (val) {
                            if (val != null && templates.containsKey(val)) {
                              final t = templates[val]!;
                              setDialogState(() {
                                selectedTemplate = val;
                                titleController.text = t['title']!;
                                contentController.text = t['content']!;
                                category = t['category']!;
                                priority = t['priority']!;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Notice Title'),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: category,
                              decoration: const InputDecoration(labelText: 'Category'),
                              items: const [
                                DropdownMenuItem(value: 'General', child: Text('General')),
                                DropdownMenuItem(value: 'Meeting', child: Text('Meeting')),
                                DropdownMenuItem(value: 'Maintenance', child: Text('Maintenance')),
                                DropdownMenuItem(value: 'Emergency', child: Text('Emergency')),
                              ],
                              onChanged: (val) => setDialogState(() => category = val!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: priority,
                              decoration: const InputDecoration(labelText: 'Priority Level'),
                              items: const [
                                DropdownMenuItem(value: 'Normal', child: Text('🟢 Normal')),
                                DropdownMenuItem(value: 'Important', child: Text('🟧 Important')),
                                DropdownMenuItem(value: 'Urgent', child: Text('🔴 Urgent')),
                              ],
                              onChanged: (val) => setDialogState(() => priority = val!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: contentController,
                        decoration: const InputDecoration(
                          labelText: 'Notice Details & Announcement Content',
                          hintText: 'Type notice details here...',
                        ),
                        maxLines: 5,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                if (noticeToEdit != null)
                  TextButton(
                    onPressed: () async {
                      await ref.read(noticesNotifierProvider.notifier).deleteNotice(noticeToEdit.id);
                      if (context.mounted) Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Delete Notice'),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isEmpty || contentController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter notice title and content')),
                      );
                      return;
                    }

                    final notice = Notice(
                      id: noticeToEdit?.id ?? '',
                      title: titleController.text.trim(),
                      content: contentController.text.trim(),
                      category: category,
                      priority: priority,
                      postedBy: 'Martand Niwas Management',
                      datePosted: noticeToEdit?.datePosted ?? DateTime.now(),
                      isActive: true,
                    );

                    try {
                      if (noticeToEdit == null) {
                        await ref.read(noticesNotifierProvider.notifier).postNotice(notice);
                      } else {
                        await ref.read(noticesNotifierProvider.notifier).updateNotice(notice);
                      }

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Notice published successfully! Visible on Noticeboard & Dashboard.'), backgroundColor: Colors.teal),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to publish notice: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  child: Text(noticeToEdit == null ? 'Publish Notice' : 'Save Changes'),
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
    final noticesAsync = ref.watch(noticesStreamProvider);
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
                      'Martand Niwas Digital Notice Board',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAdmin
                          ? 'Admin Access: Full Post, Edit & Delete Rights'
                          : 'Digital Notice Board: View Active Announcements',
                      style: TextStyle(color: isAdmin ? Colors.teal : Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                if (isAdmin)
                  ElevatedButton.icon(
                    onPressed: () => _showAddEditNoticeDialog(),
                    icon: const Icon(Icons.campaign),
                    label: const Text('Post New Notice'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: noticesAsync.when(
              data: (notices) {
                if (notices.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.campaign_outlined, size: 64, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text('No active notices published yet.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => _showAddEditNoticeDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Post First Society Notice'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: notices.length,
                  itemBuilder: (context, index) {
                    final notice = notices[index];

                    Color priorityColor = Colors.green;
                    if (notice.priority == 'Urgent') {
                      priorityColor = Colors.red;
                    } else if (notice.priority == 'Important') {
                      priorityColor = Colors.orange;
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
                                Icon(Icons.push_pin, color: priorityColor),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    notice.title,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Chip(
                                  label: Text(notice.priority),
                                  backgroundColor: priorityColor.withValues(alpha: 0.15),
                                  labelStyle: TextStyle(color: priorityColor, fontWeight: FontWeight.bold, fontSize: 11),
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                const SizedBox(width: 8),
                                Chip(
                                  label: Text(notice.category),
                                  backgroundColor: Colors.teal.shade50,
                                  labelStyle: TextStyle(color: Colors.teal.shade900, fontSize: 11),
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                if (isAdmin) ...[
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.teal),
                                    onPressed: () => _showAddEditNoticeDialog(notice),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => ref.read(noticesNotifierProvider.notifier).deleteNotice(notice.id),
                                  ),
                                ],
                              ],
                            ),
                            const Divider(height: 20),
                            Text(
                              notice.content,
                              style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.verified_user, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text('Posted by: ${notice.postedBy}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                                Text(
                                  'Date: ${notice.datePosted.day}/${notice.datePosted.month}/${notice.datePosted.year}',
                                  style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
                                ),
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
              error: (err, st) => Center(child: Text('Error loading notices: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
