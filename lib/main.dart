import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:habi_vault/firebase_options.dart';
import 'package:habi_vault/notifiers/auth_provider.dart' as custom_auth;
import 'package:habi_vault/notifiers/theme_notifier.dart';
import 'package:habi_vault/views/auth/auth_view.dart';
import 'package:habi_vault/views/main/main_view.dart';
import 'package:google_fonts/google_fonts.dart';

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
        // Definisikan tema dasar untuk tipografi
        final textTheme = Theme.of(context).textTheme;

        return MaterialApp(
          title: 'HabiVault',
          // TEMA TERANG (LIGHT MODE)
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF8F7F2), // Linen
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF8A63D2), // Amethyst
              secondary: Color(0xFF8A63D2), // Aksen utama
              surface: Colors.white,
              onSurface: Color(0xFF2D2D2D), // Charcoal
            ),
            textTheme: GoogleFonts.manropeTextTheme(textTheme).apply(
              bodyColor: const Color(0xFF2D2D2D),
              displayColor: const Color(0xFF2D2D2D),
            ),
            useMaterial3: true,
          ),
          // TEMA GELAP (DARK MODE)
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF12151C), // Oxford Blue
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF8A63D2), // Amethyst
              secondary: Color(0xFF8A63D2), // Aksen utama
              surface: Color(
                  0xFF1F232E), // Warna kartu/permukaan yang sedikit lebih terang
              onSurface: Color(0xFFE5E7EB), // Teks abu-abu keperakan
            ),
            textTheme: GoogleFonts.manropeTextTheme(textTheme).apply(
              bodyColor: const Color(0xFFE5E7EB),
              displayColor: const Color(0xFFE5E7EB),
            ),
            useMaterial3: true,
          ),
          themeMode: themeNotifier.themeMode,
          debugShowCheckedModeBanner: false,
          home: Consumer<custom_auth.AuthProvider>(
            builder: (context, auth, _) {
              if (auth.user != null && auth.user!.emailVerified) {
                return const MainView();
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
