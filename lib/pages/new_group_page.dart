import 'package:chatapp/models/usermodel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'group_details_page.dart';

class NewGroupPage extends StatefulWidget {
  final UserModel userModel;
  const NewGroupPage({Key? key, required this.userModel}) : super(key: key);

  @override
  State<NewGroupPage> createState() => _NewGroupPageState();
}

class _NewGroupPageState extends State<NewGroupPage> {
  List<UserModel> selectedUsers = [];
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("New Group", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              selectedUsers.isEmpty ? "Add participants" : "${selectedUsers.length} selected",
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
        ],
      ),
      body: Column(
        children: [
          // Selected users horizontal list
          if (selectedUsers.isNotEmpty)
            Container(
              height: 110,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: selectedUsers.length,
                itemBuilder: (context, index) {
                  UserModel user = selectedUsers[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Stack(
                      children: [
                        SizedBox(
                          width: 60,
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundImage: (user.profilepic != null && user.profilepic!.isNotEmpty)
                                    ? NetworkImage(user.profilepic!)
                                    : null,
                                onBackgroundImageError: (user.profilepic != null && user.profilepic!.isNotEmpty) ? (_, __) {} : null,
                                child: (user.profilepic == null || user.profilepic!.isEmpty)
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.fullname?.split(" ")[0] ?? "",
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 25,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedUsers.remove(user);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.grey,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

          // User list
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("users")
                  .where("uid", isNotEqualTo: widget.userModel.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No users found"));
                }

                List<UserModel> users = snapshot.data!.docs
                    .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
                    .toList();

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    UserModel user = users[index];
                    bool isSelected = selectedUsers.any((u) => u.uid == user.uid);

                    return ListTile(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            selectedUsers.removeWhere((u) => u.uid == user.uid);
                          } else {
                            selectedUsers.add(user);
                          }
                        });
                      },
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            backgroundImage: (user.profilepic != null && user.profilepic!.isNotEmpty)
                                ? NetworkImage(user.profilepic!)
                                : null,
                            onBackgroundImageError: (user.profilepic != null && user.profilepic!.isNotEmpty) ? (_, __) {} : null,
                            child: (user.profilepic == null || user.profilepic!.isEmpty)
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          if (isSelected)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check, size: 12, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                      title: Text(user.fullname ?? ""),
                      subtitle: Text(user.email ?? ""),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: selectedUsers.isNotEmpty
          ? FloatingActionButton(
              onPressed: () {
                Get.to(() => GroupDetailsPage(
                      currentUser: widget.userModel,
                      selectedUsers: selectedUsers,
                    ));
              },
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.arrow_forward, color: Colors.white),
            )
          : null,
    );
  }
}
