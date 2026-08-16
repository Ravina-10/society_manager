import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController(text: '+91 ');
  final _otpController = TextEditingController();
  
  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  String _formatPhoneNumber(String input) {
    String cleaned = input.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    if (cleaned.startsWith('+')) {
      return cleaned;
    }
    if (cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }
    return '+91$cleaned';
  }

  String _getFriendlyErrorMessage(dynamic error) {
    if (error == null) return '';
    final String str = error.toString().toLowerCase();

    if (str.contains('invalid-phone-number') || str.contains('invalid phone') || str.contains('format')) {
      return 'Invalid mobile number. Please check the entered number and try again.';
    }
    if (str.contains('invalid-verification-code') || str.contains('invalid-credential') || str.contains('otp') || str.contains('code')) {
      return 'Incorrect OTP code. Please enter the valid verification code sent to your phone.';
    }
    if (str.contains('too-many-requests') || str.contains('quota')) {
      return 'Too many login attempts. Please wait a moment and try again.';
    }
    if (str.contains('session-expired')) {
      return 'OTP session has expired. Please re-enter your mobile number to get a new code.';
    }

    return 'Invalid mobile number or verification failed. Please re-check and try again.';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    ref.listen(authStateChangesProvider, (previous, next) {
      if (next.value != null) {
        context.go('/dashboard');
      }
    });

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16.0 : 24.0, vertical: 24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 20.0 : 32.0),
                child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Martand Niwas Society',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Firebase Connected',
                        style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  if (authState.hasError) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _getFriendlyErrorMessage(authState.error),
                              style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (authState.value != null) ...[
                    const Text('Enter the OTP sent to your phone'),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _otpController,
                      decoration: const InputDecoration(
                        labelText: 'OTP',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: authState.isLoading ? null : () {
                          if (_otpController.text.isNotEmpty) {
                            ref.read(authNotifierProvider.notifier).verifyOtp(
                              authState.value!, 
                              _otpController.text,
                            );
                          }
                        },
                        child: authState.isLoading
                            ? const CircularProgressIndicator()
                            : const Text('Verify OTP'),
                      ),
                    ),
                  ] else ...[
                    const Text('Login with Mobile Number'),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number',
                        hintText: '+91 9503623550',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: authState.isLoading ? null : () {
                          if (_phoneController.text.isNotEmpty) {
                            final formattedPhone = _formatPhoneNumber(_phoneController.text);
                            ref.read(authNotifierProvider.notifier).sendOtp(formattedPhone);
                          }
                        },
                        child: authState.isLoading
                            ? const CircularProgressIndicator()
                            : const Text('Send OTP'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
}
