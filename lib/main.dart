import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_setup_screen.dart'; // Added import
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:simple_chat/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService().initialize(); // Initialize NotificationService

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder:
            (context, themeProvider, _) => MaterialApp(
              title: 'SimpleChat',
              debugShowCheckedModeBanner: false,
              themeMode: themeProvider.themeMode,
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.deepPurple,
                  brightness: Brightness.light,
                ),
                // Using the default ThemeData's textTheme as a base ensures consistent inheritance
                textTheme: GoogleFonts.montserratTextTheme(
                  ThemeData(brightness: Brightness.light).textTheme,
                ),
                useMaterial3: true,
              ),
              darkTheme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.deepPurple,
                  brightness: Brightness.dark,
                ),
                // Using the default ThemeData's textTheme as a base ensures consistent inheritance
                textTheme: GoogleFonts.montserratTextTheme(
                  ThemeData(brightness: Brightness.dark).textTheme,
                ),
                useMaterial3: true,
              ),
              home: const AuthWrapper(),
            ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (authProvider.isLoading) {
          return Scaffold(
            body: Center(
              child: SpinKitPulse(
                color: Theme.of(context).colorScheme.primary,
                size: 50.0,
              ),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          // User is authenticated, check if profile setup is needed
          if (authProvider.needsProfileSetup) {
            return const ProfileSetupScreen(); // Navigate to ProfileSetupScreen
          }
          return const HomeScreen(); // Navigate to HomeScreen
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
