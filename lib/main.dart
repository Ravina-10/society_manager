import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: SocietyManagerApp()));
}

class SocietyManagerApp extends ConsumerWidget {
  const SocietyManagerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final baseTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      useMaterial3: true,
      fontFamily: GoogleFonts.dmSans().fontFamily,
    );

    return MaterialApp.router(
      title: 'Society Manager',
      debugShowCheckedModeBanner: false,
      theme: baseTheme.copyWith(
        textTheme: GoogleFonts.dmSansTextTheme(baseTheme.textTheme),
        primaryTextTheme: GoogleFonts.dmSansTextTheme(baseTheme.primaryTextTheme),
      ),
      routerConfig: router,
    );
  }
}

