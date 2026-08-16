import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

String _normalizePhone(String input) {
  String cleaned = input.replaceAll(RegExp(r'[\s\-()]'), '');
  if (cleaned.startsWith('+91')) return cleaned;
  if (cleaned.startsWith('0')) cleaned = cleaned.substring(1);
  if (cleaned.length == 10) return '+91$cleaned';
  return cleaned;
}

class AuthNotifier extends Notifier<AsyncValue<ConfirmationResult?>> {
  @override
  AsyncValue<ConfirmationResult?> build() {
    return const AsyncValue.data(null);
  }

  FirebaseAuth get _auth => ref.read(firebaseAuthProvider);
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  Future<void> sendOtp(String phoneNumber) async {
    state = const AsyncValue.loading();
    try {
      ConfirmationResult confirmationResult = await _auth.signInWithPhoneNumber(phoneNumber);
      state = AsyncValue.data(confirmationResult);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> verifyOtp(ConfirmationResult confirmationResult, String otp) async {
    state = const AsyncValue.loading();
    try {
      UserCredential userCredential = await confirmationResult.confirm(otp);
      
      if (userCredential.user != null) {
        final uid = userCredential.user!.uid;
        final rawPhone = userCredential.user!.phoneNumber ?? '';
        final phone = _normalizePhone(rawPhone);
        final isSuper = phone.contains('9503623550');
        
        try {
          final docRef = _firestore.collection('users').doc(uid);
          final docSnap = await docRef.get();
          
          if (!docSnap.exists) {
            // Check for pre-added user record by matching phone number in Firestore
            QuerySnapshot matchQuery = await _firestore.collection('users').get();
            DocumentSnapshot? preAddedDoc;
            for (var d in matchQuery.docs) {
              if (d.id == uid) continue;
              final dData = d.data() as Map<String, dynamic>;
              final dPhone = _normalizePhone(dData['phoneNumber']?.toString() ?? d.id);
              if (phone.isNotEmpty && dPhone == phone) {
                preAddedDoc = d;
                break;
              }
            }

            if (preAddedDoc != null && preAddedDoc.exists) {
              final data = preAddedDoc.data() as Map<String, dynamic>;
              final mappedRole = data['role']?.toString().trim();
              final mappedName = data['name']?.toString().trim();

              await docRef.set({
                'uid': uid,
                'phoneNumber': phone.isNotEmpty ? phone : (data['phoneNumber'] ?? ''),
                'role': isSuper ? 'Super Admin' : (mappedRole != null && mappedRole.isNotEmpty ? mappedRole : 'viewer'),
                'name': mappedName != null && mappedName.isNotEmpty
                    ? mappedName
                    : (isSuper ? 'Super Admin (+919503623550)' : 'Society Member ($phone)'),
              }, SetOptions(merge: true));

              // Clean up temporary pre-added document if keyed under phone number
              if (preAddedDoc.id != uid) {
                try {
                  await preAddedDoc.reference.delete();
                } catch (_) {}
              }
            } else {
              await docRef.set({
                'uid': uid,
                'phoneNumber': phone,
                'role': isSuper ? 'Super Admin' : 'viewer',
                'name': isSuper ? 'Super Admin (+919503623550)' : 'Society Member (${phone.isNotEmpty ? phone : "User"})',
              }, SetOptions(merge: true));
            }
          }
        } catch (_) {}
      }
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    state = const AsyncValue.data(null);
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AsyncValue<ConfirmationResult?>>(AuthNotifier.new);

// User role provider: Super Admin vs Admin vs Viewer
final userRoleProvider = StreamProvider<String>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) {
    return Stream.value('Guest');
  }
  final userPhone = user.phoneNumber ?? '';
  if (userPhone.contains('9503623550')) {
    return Stream.value('Super Admin');
  }

  return FirebaseFirestore.instance.collection('users').snapshots().map((snapshot) {
    // 1. Direct UID match
    for (var doc in snapshot.docs) {
      if (doc.id == user.uid) {
        final role = (doc.data()['role'] as String?)?.trim();
        if (role != null && role.isNotEmpty) return role;
      }
    }

    // 2. Fallback Phone Number match
    final cleanPhone = userPhone.replaceAll(RegExp(r'[\s\-()]'), '');
    if (cleanPhone.isNotEmpty) {
      for (var doc in snapshot.docs) {
        final dPhone = (doc.data()['phoneNumber'] as String?)?.replaceAll(RegExp(r'[\s\-()]'), '') ?? doc.id;
        if (dPhone == cleanPhone) {
          final role = (doc.data()['role'] as String?)?.trim();
          if (role != null && role.isNotEmpty) return role;
        }
      }
    }

    // Default to read-only viewer for every logged in user
    return 'viewer';
  });
});

// Admin Check Provider (Admin or Super Admin)
final isAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return false;
  final phone = user.phoneNumber ?? '';
  if (phone.contains('9503623550')) return true;

  final role = (ref.watch(userRoleProvider).value ?? 'viewer').toLowerCase();
  return role == 'admin' || role == 'super admin';
});

// Super Admin Check Provider (Granted for +919503623550 or role == 'Super Admin')
final isSuperAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return false;
  final phone = user.phoneNumber ?? '';
  if (phone.contains('9503623550')) return true;

  final role = (ref.watch(userRoleProvider).value ?? 'viewer').toLowerCase();
  return role == 'super admin';
});

final usersStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance.collection('users').snapshots().map((snapshot) {
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  });
});
