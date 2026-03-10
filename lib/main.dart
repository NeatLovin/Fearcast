import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'screens/home_page.dart';
import 'screens/popular_page.dart';
import 'utilities/constants.dart';
import 'services/firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'l10n/l10n.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initializeNotifications() async {
  final List<AndroidNotificationChannel> channels = [
    AndroidNotificationChannel(
      'calm_channel',
      'Calm Notification',
      description: 'Notifications for upcoming jumpscares',
      importance: Importance.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('calm_sound'),
      vibrationPattern: Int64List.fromList([0, 500, 1000, 500]),
      enableLights: true,
    ),
    AndroidNotificationChannel(
      'goofy_channel',
      'Goofy Notification',
      description: 'Notifications for upcoming jumpscares',
      importance: Importance.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('goofy_sound'),
      vibrationPattern: Int64List.fromList([0, 500, 1000, 500]),
      enableLights: true,
    ),
    AndroidNotificationChannel(
      'groovy_channel',
      'Groovy Notification',
      description: 'Notifications for upcoming jumpscares',
      importance: Importance.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('groovy_sound'),
      vibrationPattern: Int64List.fromList([0, 500, 1000, 500]),
      enableLights: true,
    ),
    AndroidNotificationChannel(
      'scream_channel',
      'Scream Notification',
      description: 'Amplify the scare',
      importance: Importance.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('scream_sound'),
      vibrationPattern: Int64List.fromList([0, 500, 1000, 500]),
      enableLights: true,
    ),
    AndroidNotificationChannel(
      'static_channel',
      'Static Notification',
      description: 'Amplify the scare',
      importance: Importance.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('static_sound'),
      vibrationPattern: Int64List.fromList([0, 500, 1000, 500]),
      enableLights: true,
    ),
    AndroidNotificationChannel(
      'creak_channel',
      'Creak Notification',
      description: 'Amplify the scare',
      importance: Importance.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('creak_sound'),
      vibrationPattern: Int64List.fromList([0, 500, 1000, 500]),
      enableLights: true,
    ),
  ];

  for (var channel in channels) {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeNotifications(); 
  FirebaseUIAuth.configureProviders([
    EmailAuthProvider(),
  ]);

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static void setLocale(BuildContext context, Locale newLocale) {
    MyAppState? state = context.findAncestorStateOfType<MyAppState>();
    state?.setLocale(newLocale);
  }

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en');

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('settings')
            .doc(user.uid)
            .get();
            
        if (doc.exists && doc.data()?['userLang'] != null) {
          String savedLang = doc.data()?['userLang'];
          Locale newLocale;
          switch (savedLang) {
            case 'French':
              newLocale = const Locale('fr');
              break;
            case 'German':
              newLocale = const Locale('de');
              break;
            case 'Italian':
              newLocale = const Locale('it');
              break;
            case 'Spanish':
              newLocale = const Locale('es');
              break;
            case 'Portuguese':
              newLocale = const Locale('pt');
              break;
            default:
              newLocale = const Locale('en');
          }
          setState(() {
            _locale = newLocale;
          });
        }
      }
    } catch (e) {
      // En cas d'erreur, on garde l'anglais par défaut
    }
  }

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fearcast',
      theme: ThemeData(
        colorScheme: appColorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: surfaceColor,
        textTheme: const TextTheme(
          headlineMedium: headlineMediumStyle,
          bodyMedium: bodyMediumStyle,
        ),
      ),
      supportedLocales: L10n.all,
      locale: _locale,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        AppLocalizations.delegate,
      ],
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          return const PopularPage();
        } else {
          return const HomePage();
        }
      },
    );
  }
}
