import 'dart:io';
import 'package:chatapp/models/chatroommodel.dart';
import 'package:chatapp/models/usermodel.dart';
import 'package:chatapp/pages/chatroompage.dart';
import 'package:chatapp/services/chat_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class GroupDetailsPage extends StatefulWidget {
  final UserModel currentUser;
  final List<UserModel> selectedUsers;

  const GroupDetailsPage({
    Key? key,
    required this.currentUser,
    required this.selectedUsers,
  }) : super(key: key);

  @override
  State<GroupDetailsPage> createState() => _GroupDetailsPageState();
}

class _GroupDetailsPageState extends State<GroupDetailsPage> {
  TextEditingController groupNameController = TextEditingController();
  File? groupPic;
  bool isLoading = false;

  void selectImage() async {
    XFile? selectedImage = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (selectedImage != null) {
      setState(() {
        groupPic = File(selectedImage.path);
      });
    }
  }

  void createGroup() async {
    String groupName = groupNameController.text.trim();
    if (groupName.isEmpty) {
      Get.snackbar("Error", "Please enter a group name");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      String chatroomId = const Uuid().v1();
      Map<String, bool> participants = {widget.currentUser.uid!: true};

      for (var user in widget.selectedUsers) {
        participants[user.uid!] = true;
      }

      String? uploadedGroupPic;
      if (groupPic != null) {
        uploadedGroupPic = await ChatService.uploadFile(
          groupPic!,
          "group_pics/$chatroomId.jpg",
          type: "image",
        );
      }

      Chatroommodel newGroup = Chatroommodel(
        chatroomid: chatroomId,
        participants: participants,
        isGroup: true,
        groupName: groupName,
        groupPic: uploadedGroupPic ?? "",
        adminId: widget.currentUser.uid,
        lastMessage: "Group created",
        lastMessageTime: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection("chatrooms")
          .doc(chatroomId)
          .set(newGroup.toMap());

      Get.back(); // Go back to NewGroupPage
      Get.back(); // Go back to Homepage/Search

      // Navigate to the newly created group chat
      Get.to(
        () => Chatroompage(
          targetUser: widget.currentUser,
          userModel: widget.currentUser,
          chatRoom: newGroup,
        ),
      );
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("New Group")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              GestureDetector(
                onTap: selectImage,
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: groupPic != null ? FileImage(groupPic!) : null,
                  child: groupPic == null
                      ? const Icon(Icons.camera_alt, size: 40)
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: groupNameController,
                decoration: const InputDecoration(hintText: "Enter group name"),
              ),
              const SizedBox(height: 20),
              Text(
                "Participants: ${widget.selectedUsers.length}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.selectedUsers.length,
                itemBuilder: (context, index) {
                  UserModel user = widget.selectedUsers[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          (user.profilepic != null &&
                              user.profilepic!.isNotEmpty)
                          ? NetworkImage(user.profilepic!)
                          : null,
                      onBackgroundImageError:
                          (user.profilepic != null &&
                              user.profilepic!.isNotEmpty)
                          ? (_, __) {}
                          : null,
                      child: (user.profilepic == null || user.profilepic!.isEmpty)
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(user.fullname ?? ""),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: isLoading ? null : createGroup,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.check, color: Colors.white),
      ),
    );
  }
}
