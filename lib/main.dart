import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:habi_vault/firebase_options.dart';
import 'package:habi_vault/notifiers/auth_provider.dart' as custom_auth;
import 'package:habi_vault/notifiers/theme_notifier.dart';
import 'package:habi_vault/views/auth/auth_view.dart';
// import 'package:habi_vault/views/auth/verification_view.dart';
import 'package:habi_vault/views/dashboard/dashboard_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    // Gunakan MultiProvider untuk mendaftarkan semua provider kita
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider(create: (_) => custom_auth.AuthProvider()),
      ],
      child: const HabiVaultApp(),
    ),
  );
}

class HabiVaultApp extends StatelessWidget {
  const HabiVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return MaterialApp(
          title: 'HabiVault',
          theme: ThemeData(
            brightness: Brightness.light,
            colorSchemeSeed: Colors.blue,
            useMaterial3: true,
            inputDecorationTheme: const InputDecorationTheme(
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorSchemeSeed: Colors.blue,
            useMaterial3: true,
            inputDecorationTheme: const InputDecorationTheme(
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
          ),
          themeMode: themeNotifier.themeMode,
          debugShowCheckedModeBanner: false,
          home: Consumer<custom_auth.AuthProvider>(
            builder: (context, auth, _) {
              if (auth.user != null && auth.user!.emailVerified) {
                return const DashboardView();
              } else {
                return const AuthView();
              }
            },
          ),
        );
      },
    );
  }
}
