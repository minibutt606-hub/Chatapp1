import 'dart:io';
import 'package:chatapp/models/usermodel.dart';
import 'package:chatapp/utils/camera_utils.dart';
import 'package:chatapp/services/cloudinary_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MyProfilePage extends StatefulWidget {
  final UserModel userModel;

  const MyProfilePage({Key? key, required this.userModel}) : super(key: key);

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  void _editName() {
    TextEditingController controller = TextEditingController(text: widget.userModel.fullname);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Enter your name"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Your name"),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white, elevation: 0),
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await FirebaseFirestore.instance.collection("users").doc(widget.userModel.uid).update({
                  "fullname": controller.text.trim(),
                });
                widget.userModel.fullname = controller.text.trim();
                setState(() {});
                Navigator.pop(ctx);
                Get.snackbar("Success", "Name updated successfully", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green.shade100);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _editAbout() {
    TextEditingController controller = TextEditingController(text: widget.userModel.about ?? "Available");
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Add about"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "About"),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white, elevation: 0),
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await FirebaseFirestore.instance.collection("users").doc(widget.userModel.uid).update({
                  "about": controller.text.trim(),
                });
                widget.userModel.about = controller.text.trim();
                setState(() {});
                Navigator.pop(ctx);
                Get.snackbar("Success", "About updated successfully", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green.shade100);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _uploadProfilePic(File image) async {
    Get.snackbar("Uploading", "Updating profile picture...", snackPosition: SnackPosition.BOTTOM);
    String? url = await CloudinaryService.uploadFile(image.path);
    if (url != null) {
      await FirebaseFirestore.instance.collection("users").doc(widget.userModel.uid).update({
        "profilepic": url,
      });
      setState(() {
        widget.userModel.profilepic = url;
      });
      Get.snackbar("Success", "Profile photo updated", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green.shade100);
    } else {
      Get.snackbar("Error", "Failed to upload image", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade100);
    }
  }

  void _changeProfilePic() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Camera"),
              onTap: () async {
                Navigator.pop(ctx);
                File? image = await CameraUtils.takePhoto();
                if (image != null) _uploadProfilePic(image);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text("Gallery"),
              onTap: () async {
                Navigator.pop(ctx);
                File? image = await CameraUtils.pickImageFromGallery();
                if (image != null) _uploadProfilePic(image);
              },
            ),
            if (widget.userModel.profilepic?.isNotEmpty ?? false)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text("Remove photo", style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await FirebaseFirestore.instance.collection("users").doc(widget.userModel.uid).update({
                    "profilepic": "",
                  });
                  widget.userModel.profilepic = "";
                  setState(() {});
                  Get.snackbar("Success", "Profile photo removed", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green.shade100);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Profile", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        surfaceTintColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          // Profile Picture
          Center(
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () {
                     if (widget.userModel.profilepic?.isNotEmpty ?? false) {
                       Get.to(() => _FullPhoto(url: widget.userModel.profilepic!, name: widget.userModel.fullname ?? "User"));
                     }
                  },
                  child: Hero(
                    tag: "my_profile",
                    child: CircleAvatar(
                      radius: 80,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: (widget.userModel.profilepic?.isNotEmpty ?? false)
                          ? NetworkImage(widget.userModel.profilepic!)
                          : null,
                      onBackgroundImageError: (widget.userModel.profilepic?.isNotEmpty ?? false) ? (_, __) {} : null,
                      child: (widget.userModel.profilepic == null || widget.userModel.profilepic!.isEmpty)
                          ? const Icon(Icons.person, size: 80, color: Colors.white)
                          : null,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _changeProfilePic,
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: primary,
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 24),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Name
          ListTile(
            leading: Icon(Icons.person, color: Colors.grey.shade600, size: 28),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Name", style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Text(widget.userModel.fullname ?? "User", style: const TextStyle(fontSize: 16)),
              ],
            ),
            subtitle: const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text("This is not your username or pin. This name will be visible to your WhatsApp contacts.", style: TextStyle(fontSize: 13)),
            ),
            trailing: IconButton(
              icon: Icon(Icons.edit, color: primary),
              onPressed: _editName,
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 64, right: 16),
            child: Divider(height: 20),
          ),

          // About
          ListTile(
            leading: Icon(Icons.info_outline, color: Colors.grey.shade600, size: 28),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("About", style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Text(widget.userModel.about ?? "Available", style: const TextStyle(fontSize: 16)),
              ],
            ),
            trailing: IconButton(
              icon: Icon(Icons.edit, color: primary),
              onPressed: _editAbout,
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 64, right: 16),
            child: Divider(height: 20),
          ),

          // Phone
          ListTile(
            leading: Icon(Icons.phone, color: Colors.grey.shade600, size: 28),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Phone", style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Text((widget.userModel.phoneNumber?.isNotEmpty ?? false) ? widget.userModel.phoneNumber! : widget.userModel.email ?? "—", style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FullPhoto extends StatelessWidget {
  final String url;
  final String name;
  const _FullPhoto({required this.url, required this.name});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(name),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Hero(
            tag: "my_profile",
            child: Image.network(url, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white)),
          ),
        ),
      ),
    );
  }
}
