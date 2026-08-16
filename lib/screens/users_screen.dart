import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  // Add or Edit User Modal Dialog
  void _showAddEditUserDialog([Map<String, dynamic>? existingUser]) {
    final phoneController = TextEditingController(text: existingUser?['phoneNumber'] ?? existingUser?['id'] ?? '+91 ');
    final nameController = TextEditingController(text: existingUser?['name'] ?? '');
    String role = (existingUser?['role'] as String?)?.toLowerCase() ?? 'viewer';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existingUser == null ? 'Add User / Assign Role' : 'Edit User & Permissions'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 380,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Mobile Number',
                          hintText: '+91 9876543210',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'User Name / Flat Assigned',
                          hintText: 'e.g., Vitthal Mokashi (F101)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: role,
                        decoration: const InputDecoration(labelText: 'Assigned Role', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'super admin', child: Text('👑 Super Admin (Full Control)')),
                          DropdownMenuItem(value: 'admin', child: Text('⚡ Admin (Management Access)')),
                          DropdownMenuItem(value: 'viewer', child: Text('👤 Resident / Viewer (Read Only)')),
                        ],
                        onChanged: (val) => setDialogState(() => role = val!),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                if (existingUser != null)
                  TextButton(
                    onPressed: () async {
                      final phone = existingUser['phoneNumber'] ?? '';
                      if (phone.toString().contains('9503623550')) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cannot delete Primary Super Admin (+919503623550)!'), backgroundColor: Colors.red),
                        );
                        return;
                      }

                      await FirebaseFirestore.instance.collection('users').doc(existingUser['id']).delete();
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('User access revoked and deleted successfully!'), backgroundColor: Colors.teal),
                        );
                      }
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Delete User'),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (phoneController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a mobile number')),
                      );
                      return;
                    }
                    final phone = phoneController.text.trim();
                    final id = existingUser?['id'] ?? phone.replaceAll(RegExp(r'\s+'), '');

                    await FirebaseFirestore.instance.collection('users').doc(id).set({
                      'uid': id,
                      'phoneNumber': phone,
                      'name': nameController.text.trim().isEmpty ? 'Society Member' : nameController.text.trim(),
                      'role': role,
                    }, SetOptions(merge: true));

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(existingUser == null ? 'New user added successfully!' : 'User updated successfully!'),
                          backgroundColor: Colors.teal,
                        ),
                      );
                    }
                  },
                  child: Text(existingUser == null ? 'Save User' : 'Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Confirm Delete User Dialog
  void _confirmDeleteUser(Map<String, dynamic> user) {
    final phone = user['phoneNumber'] ?? user['id'] ?? '';
    final name = user['name'] ?? 'User';

    if (phone.toString().contains('9503623550')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete Primary Super Admin (+919503623550)!'), backgroundColor: Colors.red),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Revoke User Access?'),
          content: Text('Are you sure you want to delete user "$name" ($phone)? Their access will be revoked.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('users').doc(user['id']).delete();
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User deleted successfully.'), backgroundColor: Colors.teal),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('Delete User'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersStreamProvider);
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
                      'User Roles & Access Control',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isSuperAdmin
                          ? 'Super Admin Access: Assign, edit, or delete user accounts & roles.'
                          : 'User Directory & Roles Overview.',
                      style: TextStyle(color: isSuperAdmin ? Colors.teal : Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                if (isSuperAdmin)
                  ElevatedButton.icon(
                    onPressed: () => _showAddEditUserDialog(),
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add Authorized User'),
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
            child: usersAsync.when(
              data: (users) {
                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('No custom user accounts found.'),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => _showAddEditUserDialog(),
                          icon: const Icon(Icons.person_add),
                          label: const Text('Add First User'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final u = users[index];
                    final phone = u['phoneNumber'] ?? u['id'] ?? 'Unknown';
                    final name = u['name'] ?? 'User';
                    final role = (u['role'] as String?)?.toLowerCase() ?? 'viewer';
                    final isOwner = phone.toString().contains('9503623550');

                    Color roleColor = Colors.blueGrey;
                    String roleLabel = 'RESIDENT / VIEWER';
                    if (role == 'super admin' || isOwner) {
                      roleColor = Colors.purple;
                      roleLabel = 'SUPER ADMIN';
                    } else if (role == 'admin') {
                      roleColor = Colors.teal;
                      roleLabel = 'ADMIN';
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: roleColor.withValues(alpha: 0.15),
                          child: Icon(
                            role == 'viewer' ? Icons.person : Icons.admin_panel_settings,
                            color: roleColor,
                          ),
                        ),
                        title: Text('$name ($phone)', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          isOwner ? '👑 Primary Super Admin (Full Owner Rights)' : 'Role: $roleLabel',
                          style: TextStyle(color: roleColor, fontWeight: FontWeight.w500, fontSize: 12),
                        ),
                        trailing: isSuperAdmin
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  DropdownButton<String>(
                                    value: role,
                                    underline: const SizedBox.shrink(),
                                    items: const [
                                      DropdownMenuItem(value: 'super admin', child: Text('Super Admin')),
                                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                                      DropdownMenuItem(value: 'viewer', child: Text('Viewer')),
                                    ],
                                    onChanged: isOwner
                                        ? null
                                        : (newRole) async {
                                            if (newRole != null) {
                                              await FirebaseFirestore.instance.collection('users').doc(u['id']).update({'role': newRole});
                                            }
                                          },
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.teal),
                                    tooltip: 'Edit User & Role',
                                    onPressed: () => _showAddEditUserDialog(u),
                                  ),
                                  if (!isOwner)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      tooltip: 'Delete User & Revoke Access',
                                      onPressed: () => _confirmDeleteUser(u),
                                    ),
                                ],
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(child: Text('Error loading users: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
