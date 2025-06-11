import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:habi_vault/widgets/custom_dialog.dart';

class VerificationView extends StatelessWidget {
  const VerificationView({super.key});

  void _returnToLogin(BuildContext context) {
    Navigator.of(context).pop();
  }

  Future<void> _resendVerificationEmail(BuildContext context) async {
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      if (context.mounted) {
        showHabiVaultDialog(
          context: context,
          title: 'Success',
          message: 'Verification email has been resent to your inbox.',
          type: DialogType.success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        showHabiVaultDialog(
          context: context,
          title: 'Error',
          message: 'Failed to resend email: ${e.toString()}',
          type: DialogType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.mark_email_unread_outlined,
                size: 100,
                color: Colors.amber,
              ).animate().fade(delay: 200.ms).shake(hz: 1, duration: 800.ms),
              const SizedBox(height: 32),
              Text(
                'One Last Step!',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'A verification link has been sent to your email. Please click the link, then return here to log in.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                ),
                // Tombol ini sekarang memanggil _returnToLogin
                onPressed: () => _returnToLogin(context),
                child: const Text('Continue to Login'),
              ),
              const SizedBox(height: 24),
              const Text("Didn't receive the email?"),
              TextButton(
                onPressed: () => _resendVerificationEmail(context),
                child: const Text('Resend verification link'),
              ),
            ],
          ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2),
        ),
      ),
    );
  }
}
