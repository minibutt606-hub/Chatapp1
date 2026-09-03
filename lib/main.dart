import 'package:chatapp/firebase_options.dart';
import 'package:chatapp/pages/signuppage.dart';
import 'package:chatapp/pages/splashscreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/instance_manager.dart';
import 'package:get/route_manager.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chatapp/services/notification_service.dart';
import 'package:chatapp/models/usermodel.dart';
import 'package:chatapp/models/firebase_helper.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

var uuid = Uuid();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ZegoUIKitPrebuiltCallInvitationService().setNavigatorKey(navigatorKey);

  // Prevent audioplayers 6.x assertion crash
  try {
    AudioPlayer.global.setAudioContext(
      AudioContext(
        android: AudioContextAndroid(
          audioMode: AndroidAudioMode.normal,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.assistanceSonification,
          audioFocus: AndroidAudioFocus.gain,
        ),
      ),
    );
  } catch (e) {
    debugPrint("AudioContext error: $e");
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.initialize();

  User? currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    NotificationService.updateToken(currentUser.uid);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Chat App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
          surface: const Color(0xFF111B21),
        ),
        scaffoldBackgroundColor: const Color(0xFF0B141A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF202C33),
          foregroundColor: Color(0xFFE9EDEF),
          elevation: 0,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFFE9EDEF)),
          bodyMedium: TextStyle(color: Color(0xFFE9EDEF)),
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.light,
      home: const UserPresenceObserver(child: Splashscreen()),
    );
  }
}

class UserPresenceObserver extends StatefulWidget {
  final Widget child;
  const UserPresenceObserver({Key? key, required this.child}) : super(key: key);

  @override
  State<UserPresenceObserver> createState() => _UserPresenceObserverState();
}

class _UserPresenceObserverState extends State<UserPresenceObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setOnlineStatus(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _setOnlineStatus(true);
    } else {
      _setOnlineStatus(false);
    }
  }

  void _setOnlineStatus(bool isOnline) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUser.uid)
          .update({"isOnline": isOnline, "lastSeen": DateTime.now()});
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
