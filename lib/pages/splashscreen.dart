import 'dart:async';
import 'package:chatapp/models/usermodel.dart';
import 'package:chatapp/pages/homepage.dart';
import 'package:chatapp/pages/loginpage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class Splashscreen extends StatefulWidget {
  const Splashscreen({Key? key}) : super(key: key);

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen> {
  @override
  void initState() {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    super.initState();
    Timer(const Duration(seconds: 3), () {
      checkLoginStatus();
    });
  }

  void checkLoginStatus() async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      // Logged In
      DocumentSnapshot userData = await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUser.uid)
          .get();

      if (userData.data() != null) {
        UserModel userModel = UserModel.fromMap(
          userData.data() as Map<String, dynamic>,
        );

        Get.offAll(
          () => Homepage(userModel: userModel, firebaseUser: currentUser),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 800),
        );
      } else {
        // Document doesn't exist, go to login
        Get.offAll(
          () => Loginpage(),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 800),
        );
      }
    } else {
      // Not Logged In
      Get.offAll(
        () => Loginpage(),
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 800),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Logo centered
            Center(
              child: Image.asset(
                "assets/images/c.png",
                height: 450,
                width: 500,
                filterQuality: FilterQuality.high,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.chat,
                    size: 150,
                    color: Colors.deepPurple,
                  );
                },
              ),
            ),
            // Indicator at the bottom
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 100),
                child: const CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
