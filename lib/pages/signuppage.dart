import 'package:chatapp/models/usermodel.dart';
import 'package:chatapp/pages/completeprofile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Signuppage extends StatefulWidget {
  Signuppage({Key? key}) : super(key: key);

  @override
  _SignuppageState createState() => _SignuppageState();
}

class _SignuppageState extends State<Signuppage> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  bool isLoading = false;

  void checkvalues() {
    String email = emailController.text.trim();
    String password = passwordController.text; // Do not trim passwords
    String confirmPassword = confirmPasswordController.text;

    if (email == "" || password == "" || confirmPassword == "") {
      Get.snackbar(
        "Required Fields",
        "Please fill all the fields!",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } else if (!GetUtils.isEmail(email)) {
      Get.snackbar(
        "Invalid Email",
        "Please enter a valid email address!",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } else if (password.length < 6) {
      Get.snackbar(
        "Weak Password",
        "Password must be at least 6 characters long!",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } else if (password != confirmPassword) {
      Get.snackbar(
        "Password Mismatch",
        "Passwords do not match exactly! Make sure there are no extra spaces.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      signup(email, password);
    }
  }

  void signup(String email, String password) async {
    setState(() {
      isLoading = true;
    });

    UserCredential? credential;
    try {
      credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        isLoading = false;
      });
      Get.snackbar(
        "Error",
        e.message.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }

    if (credential != null) {
      String uid = credential.user!.uid;
      UserModel newuser = UserModel(
        uid: uid,
        email: email,
        profilepic: "",
        fullname: "",
      );

      try {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(uid)
            .set(newuser.toMap());

        setState(() {
          isLoading = false;
        });

        Get.snackbar(
          "Success",
          "Account created successfully!",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        Get.off(
          () => Completeprofile(
            userModel: newuser,
            firebaseUser: credential!.user!,
          ),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 800),
        );
      } catch (error) {
        setState(() {
          isLoading = false;
        });
        Get.snackbar(
          "Firestore Error",
          "Ensure Firestore rules allow writes. Detail: ${error.toString()}",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
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
                    height: 300, // Matching login page
                    width: 300,
                    filterQuality: FilterQuality.high,
                    fit: BoxFit.cover,
                  ),

                  Text(
                    "Chat App",
                    style: GoogleFonts.poppins(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                      fontSize: 24, // Slightly smaller
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
                  SizedBox(height: 15),
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
                  SizedBox(height: 15),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: "Confirm Password",
                      labelStyle: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54),
                      prefixIcon: Icon(Icons.lock_reset_outlined, color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54),
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
                                "Signup",
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
              "Already have an Account?",
              style: GoogleFonts.poppins(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            CupertinoButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                "Login",
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
