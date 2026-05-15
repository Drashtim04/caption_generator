import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'services/admob_service.dart';
import 'providers/caption_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding_screen.dart';
import 'utils/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final ads = AdMobService();
  // Initialize in parallel without blocking the main thread
  ads.init().then((_) => ads.loadInterstitial());

  runApp(MyApp(ads: ads));
}

class MyApp extends StatefulWidget {
  final AdMobService ads;
  const MyApp({super.key, required this.ads});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<bool> _onboardingFuture;

  @override
  void initState() {
    super.initState();
    _onboardingFuture = _seenOnboarding();
  }

  Future<bool> _seenOnboarding() async {
    // Artificial delay removed or kept minimal (user asked for 1s max)
    // If it's already fast, we don't need to add delay.
    // If it's slow, we ensure it's not blocked by other inits.
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('seen_onboarding') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CaptionProvider(ads: widget.ads)),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) {
          final sp = SettingsProvider();
          sp.loadSettings();
          return sp;
        }),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Caption Studio',
            themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: FutureBuilder<bool>(
              future: _onboardingFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return Scaffold(
                    backgroundColor: Colors.white,
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width * 0.75,
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(40),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/images/logo111.png',
                                  width: 150,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(height: 20),
                                RichText(
                                  text: TextSpan(
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                    ),
                                    children: const [
                                      TextSpan(text: "CAPTION ", style: TextStyle(color: Color(0xFF1E293B))),
                                      TextSpan(text: "STUDIO", style: TextStyle(color: Color(0xFFEC4899))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 60),
                          const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final seen = snapshot.data ?? false;
                return seen ? const MainScreen() : const OnboardingScreen();
              },
            ),
          );
        },
      ),
    );
  }
}
