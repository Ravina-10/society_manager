import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

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
        final phone = userCredential.user!.phoneNumber ?? '';
        final isSuper = phone.contains('9503623550');
        
        try {
          final docRef = _firestore.collection('users').doc(uid);
          final docSnap = await docRef.get();
          if (!docSnap.exists) {
            await docRef.set({
              'uid': uid,
              'phoneNumber': phone,
              'role': isSuper ? 'Super Admin' : 'Resident',
              'name': isSuper ? 'Super Admin (+919503623550)' : 'Society Member (${phone.isNotEmpty ? phone : "User"})',
            }, SetOptions(merge: true));
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

// User role provider: Super Admin vs Admin vs Resident
final userRoleProvider = StreamProvider<String>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) {
    return Stream.value('Guest');
  }
  final userPhone = user.phoneNumber ?? '';
  if (userPhone.contains('9503623550')) {
    return Stream.value('Super Admin');
  }

  return FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots().map((snapshot) {
    if (snapshot.exists) {
      final role = (snapshot.data()?['role'] as String?)?.trim();
      if (role != null && role.isNotEmpty) return role;
    }
    return 'Resident';
  });
});

// Admin Check Provider (Admin or Super Admin)
final isAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return false;
  final phone = user.phoneNumber ?? '';
  if (phone.contains('9503623550')) return true;

  final role = (ref.watch(userRoleProvider).value ?? 'Resident').toLowerCase();
  return role == 'admin' || role == 'super admin';
});

// Super Admin Check Provider (Granted for +919503623550 or role == 'Super Admin')
final isSuperAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return false;
  final phone = user.phoneNumber ?? '';
  if (phone.contains('9503623550')) return true;

  final role = ref.watch(userRoleProvider).value ?? 'Resident';
  return role.toLowerCase() == 'super admin';
});

final usersStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance.collection('users').snapshots().map((snapshot) {
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  });
});
