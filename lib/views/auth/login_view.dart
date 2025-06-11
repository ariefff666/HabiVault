// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:habi_vault/controllers/auth_controller.dart';
// import 'package:habi_vault/controllers/form_controller.dart';
// import 'package:habi_vault/views/auth/register_view.dart';
// // import 'package:habi_vault/views/dashboard/dashboard_view.dart';

// class LoginView extends StatefulWidget {
//   const LoginView({super.key});

//   @override
//   State<LoginView> createState() => _LoginViewState();
// }

// class _LoginViewState extends State<LoginView> {
//   final AuthController _authController = AuthController();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

//   @override
//   Widget build(BuildContext context) {
//     final colors = Theme.of(context).colorScheme;
//     final textTheme = Theme.of(context).textTheme;

//     return Scaffold(
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
//                     'Welcome Back,',
//                     style: textTheme.headlineLarge
//                         ?.copyWith(fontWeight: FontWeight.bold),
//                   ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
//                   Text(
//                     'Log in to continue your progress!',
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

//                   // --- Login Button ---
//                   ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       backgroundColor: colors.primary,
//                       foregroundColor: colors.onPrimary,
//                     ),
//                     onPressed: () async {
//                       if (_formKey.currentState!.validate()) {
//                         await _authController.loginWithEmail(
//                           _emailController.text,
//                           _passwordController.text,
//                         );
//                         // Navigasi sudah dihandle oleh StreamBuilder di main.dart
//                       }
//                     },
//                     child: const Text('Log In'),
//                   ).animate().fadeIn(delay: 700.ms).scale(),
//                   const SizedBox(height: 16),

//                   // --- Divider & Google Login ---
//                   const Row(
//                     children: [
//                       Expanded(child: Divider()),
//                       Padding(
//                         padding: EdgeInsets.symmetric(horizontal: 8.0),
//                         child: Text('OR'),
//                       ),
//                       Expanded(child: Divider()),
//                     ],
//                   ).animate().fadeIn(delay: 800.ms),
//                   const SizedBox(height: 16),
//                   OutlinedButton.icon(
//                     icon: Image.asset('assets/icons/google_icon.png',
//                         height: 20), // Pastikan Anda punya aset ini
//                     style: OutlinedButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                     ),
//                     onPressed: () async {
//                       await _authController.loginWithGoogle();
//                     },
//                     label: const Text('Continue with Google'),
//                   ).animate().fadeIn(delay: 900.ms).scale(),
//                   const SizedBox(height: 24),

//                   // --- Register Link ---
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       const Text("Don't have an account?"),
//                       TextButton(
//                         onPressed: () {
//                           Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                   builder: (context) => const RegisterView()));
//                         },
//                         child: const Text('Register Now'),
//                       ),
//                     ],
//                   ).animate().fadeIn(delay: 1000.ms),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
