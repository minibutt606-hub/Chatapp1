import 'dart:io';
import 'package:image_cropper/image_cropper.dart';
import 'package:chatapp/models/usermodel.dart';
import 'package:chatapp/pages/homepage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chatapp/services/cloudinary_service.dart';

class Completeprofile extends StatefulWidget {
  final UserModel userModel;
  final User firebaseUser;

  const Completeprofile({
    Key? key,
    required this.userModel,
    required this.firebaseUser,
  }) : super(key: key);

  @override
  State<Completeprofile> createState() => _CompleteprofileState();
}

class _CompleteprofileState extends State<Completeprofile> {
  TextEditingController fullNameController = TextEditingController();
  File? imageFile;
  bool isLoading = false;

  void selectImage(ImageSource source) async {
    XFile? pickedFile = await ImagePicker().pickImage(source: source);

    if (pickedFile != null) {
      cropImage(pickedFile);
    }
  }

  void cropImage(XFile pickedFile) async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressQuality: 50,
      uiSettings: [
        AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Theme.of(context).colorScheme.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true),
        IOSUiSettings(
          title: 'Crop Image',
        ),
      ],
    );

    if (croppedFile != null) {
      setState(() {
        imageFile = File(croppedFile.path);
      });
    }
  }

  void showPhotoOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF233138) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          "Upload Profile Picture",
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              onTap: () {
                Navigator.pop(context);
                selectImage(ImageSource.gallery);
              },
              leading: Icon(
                Icons.photo_library,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text("Select from Gallery", style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87)),
            ),
            ListTile(
              onTap: () {
                Navigator.pop(context);
                selectImage(ImageSource.camera);
              },
              leading: Icon(Icons.camera_alt, color: Theme.of(context).colorScheme.primary),
              title: Text("Take a Photo", style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87)),
            ),
            if (imageFile != null)
              ListTile(
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    imageFile = null;
                  });
                },
                leading: const Icon(Icons.delete_sweep, color: Colors.red),
                title: const Text(
                  "Remove Photo",
                  style: TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  void checkValues() {
    String fullname = fullNameController.text.trim();

    if (fullname.isEmpty) {
      Get.snackbar("Error", "Please enter your full name");
    } else {
      uploadData();
    }
  }

  void uploadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      String imageUrl = "";

      // Upload Image to Storage if exists
      if (imageFile != null) {
        String? url = await CloudinaryService.uploadFile(imageFile!.path);
        imageUrl = url ?? "";
      } else {
        // Use a default avatar if no image is selected
        imageUrl = "https://cdn-icons-png.flaticon.com/512/149/149071.png";
      }

      // Update user documentation in Firestore
      widget.userModel.fullname = fullNameController.text.trim();
      widget.userModel.profilepic = imageUrl;

      await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.userModel.uid)
          .set(widget.userModel.toMap());

      setState(() {
        isLoading = false;
      });

      Get.snackbar(
        "Success",
        "Profile updated successfully!",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      Get.offAll(
        () => Homepage(
          userModel: widget.userModel,
          firebaseUser: widget.firebaseUser,
        ),
        transition: Transition.rightToLeftWithFade,
        duration: const Duration(milliseconds: 900),
      );
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      Get.snackbar(
        "Error",
        "Failed to update profile: ${e.toString()}",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF202C33) : Theme.of(context).colorScheme.primary,
        title: Text(
          "Complete Profile",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: ListView(
            children: [
              const SizedBox(height: 40),
              CupertinoButton(
                onPressed: () {
                  showPhotoOptions();
                },
                padding: const EdgeInsets.all(0),
                child: CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.1),
                  radius: 70,
                  backgroundImage: (imageFile != null)
                      ? FileImage(imageFile!)
                      : null,
                  child: (imageFile == null)
                      ? Hero(
                          tag: "profile_pic",
                          child: Icon(
                            Icons.person,
                            size: 60,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        )
                      : null,
                ),
              ),
              if (imageFile == null) const SizedBox(height: 10),
              if (imageFile == null)
                const Center(
                  child: Text(
                    "Tap to add photo",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              const SizedBox(height: 40),
              TextField(
                controller: fullNameController,
                style: GoogleFonts.poppins(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: "Enter Full Name",
                  hintStyle: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white38 : Colors.grey),
                  prefixIcon: Icon(Icons.person_outline, color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.black12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: CupertinoButton(
                  onPressed: (isLoading)
                      ? null
                      : () {
                          checkValues();
                        },
                  color: Theme.of(context).colorScheme.primary,
                  disabledColor: Theme.of(context).colorScheme.primary,
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
                          "Finish & Setup",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
