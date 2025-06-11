// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:habi_vault/controllers/auth_controller.dart';
// import 'package:habi_vault/controllers/form_controller.dart';
// import 'package:habi_vault/views/auth/login_view.dart';

// class RegisterView extends StatefulWidget {
//   const RegisterView({super.key});

//   @override
//   State<RegisterView> createState() => _RegisterViewState();
// }

// class _RegisterViewState extends State<RegisterView> {
//   final AuthController _authController = AuthController();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

//   @override
//   Widget build(BuildContext context) {
//     final colors = Theme.of(context).colorScheme;
//     final textTheme = Theme.of(context).textTheme;

//     return Scaffold(
//       appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
//       body: SafeArea(
//         child: Center(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(24.0),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   // --- Header ---
//                   Text(
//                     'Create Account,',
//                     style: textTheme.headlineLarge
//                         ?.copyWith(fontWeight: FontWeight.bold),
//                   ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
//                   Text(
//                     'Start your journey with HabiVault!',
//                     style: textTheme.titleMedium
//                         ?.copyWith(color: colors.onSurfaceVariant),
//                   ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
//                   const SizedBox(height: 48),

//                   // --- Email & Password Fields ---
//                   TextFormField(
//                     controller: _emailController,
//                     decoration: const InputDecoration(
//                         labelText: 'Email',
//                         prefixIcon: Icon(Icons.email_outlined)),
//                     validator: (value) =>
//                         FormController.validateEmail(value ?? ''),
//                     keyboardType: TextInputType.emailAddress,
//                   ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.2),
//                   const SizedBox(height: 16),
//                   TextFormField(
//                     controller: _passwordController,
//                     obscureText: true,
//                     decoration: const InputDecoration(
//                         labelText: 'Password',
//                         prefixIcon: Icon(Icons.lock_outline)),
//                     validator: (value) =>
//                         FormController.validatePassword(value ?? ''),
//                   ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.2),
//                   const SizedBox(height: 32),

//                   // --- Register Button ---
//                   ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       backgroundColor: colors.primary,
//                       foregroundColor: colors.onPrimary,
//                     ),
//                     onPressed: () async {
//                       if (_formKey.currentState!.validate()) {
//                         final result = await _authController.registerWithEmail(
//                           _emailController.text,
//                           _passwordController.text,
//                         );
//                         if (context.mounted) {
//                           if (result.user != null) {
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               const SnackBar(
//                                   content: Text(
//                                       'Verification email sent! Please check your inbox.')),
//                             );
//                             Navigator.pushReplacement(
//                               context,
//                               MaterialPageRoute(
//                                   builder: (context) => const LoginView()),
//                             );
//                           } else {
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               SnackBar(
//                                   content: Text(
//                                       result.error ?? 'Registration failed')),
//                             );
//                           }
//                         }
//                       }
//                     },
//                     child: const Text('Create Account'),
//                   ).animate().fadeIn(delay: 700.ms).scale(),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
