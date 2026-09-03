import 'package:chatapp/models/usermodel.dart';
import 'package:chatapp/pages/homepage.dart';
import 'package:chatapp/pages/signuppage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class Loginpage extends StatefulWidget {
  Loginpage({Key? key}) : super(key: key);

  @override
  _LoginpageState createState() => _LoginpageState();
}

class _LoginpageState extends State<Loginpage> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  void checkvalues() {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email == "" || password == "") {
      Get.snackbar(
        "Required Fields",
        "Please fill all the fields!",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } else {
      login(email, password);
    }
  }

  void login(String email, String password) async {
    setState(() {
      isLoading = true;
    });

    try {
      UserCredential credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      if (credential.user != null) {
        String uid = credential.user!.uid;

        DocumentSnapshot userData = await FirebaseFirestore.instance
            .collection("users")
            .doc(uid)
            .get();
        UserModel userModel = UserModel.fromMap(
          userData.data() as Map<String, dynamic>,
        );

        setState(() {
          isLoading = false;
        });

        Get.snackbar(
          "Welcome Back",
          "Login successful!",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        Get.offAll(
          () => Homepage(userModel: userModel, firebaseUser: credential.user!),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 500),
        );
      }
    } on FirebaseAuthException catch (ex) {
      setState(() {
        isLoading = false;
      });
      Get.snackbar(
        "Error",
        ex.message.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 30),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Image.asset(
                    "assets/images/c.png",
                    height: 300, // Significantly larger
                    width: 300,
                    filterQuality: FilterQuality.high,
                    fit: BoxFit.cover,
                  ),

                  Text(
                    "Chat App",
                    style: GoogleFonts.poppins(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: "Email Address",
                      labelStyle: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54),
                      prefixIcon: Icon(Icons.email_outlined, color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.black12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: "Password",
                      labelStyle: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54),
                      prefixIcon: Icon(Icons.lock_outline, color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.black12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2),
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 60),
                    child: SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: CupertinoButton(
                        onPressed: (isLoading)
                            ? null
                            : () {
                                checkvalues();
                              },
                        color: Theme.of(context).colorScheme.secondary,
                        disabledColor: Theme.of(context).colorScheme.secondary,
                        child: (isLoading)
                            ? const SizedBox(
                                height: 25,
                                width: 25,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : Text(
                                "Login",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Dont have an Account?",
              style: GoogleFonts.poppins(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            CupertinoButton(
              onPressed: () {
                Get.to(
                  () => Signuppage(),
                  transition: Transition.rightToLeftWithFade,
                  duration: const Duration(milliseconds: 600),
                );
              },
              child: Text(
                "Sign Up",
                style: GoogleFonts.poppins(
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
