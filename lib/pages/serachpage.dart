import 'package:chatapp/models/chatroommodel.dart';
import 'package:chatapp/models/firebase_helper.dart';
import 'package:chatapp/models/usermodel.dart';
import 'package:chatapp/pages/chatroompage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Serachpage extends StatefulWidget {
  final UserModel userModel;
  const Serachpage({Key? key, required this.userModel}) : super(key: key);

  @override
  State<Serachpage> createState() => _SerachpageState();
}

class _SerachpageState extends State<Serachpage> {
  TextEditingController searchController = TextEditingController();
  bool isLoading = false;



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Search Friends", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          child: Column(
            children: [
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: "Email Address",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => setState(() {}),
                  child: const Text("SEARCH", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection("users")
                      .where("email", isEqualTo: searchController.text)
                      .where("email", isNotEqualTo: widget.userModel.email)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.active) {
                      if (snapshot.hasData) {
                        QuerySnapshot dataSnapshot = snapshot.data as QuerySnapshot;
                        if (dataSnapshot.docs.isNotEmpty) {
                          UserModel searchedUser = UserModel.fromMap(dataSnapshot.docs[0].data() as Map<String, dynamic>);
                          return ListTile(
                            onTap: isLoading ? null : () async {
                              setState(() {
                                isLoading = true;
                              });
                              try {
                                Chatroommodel? chatroomModel =
                                    await FirebaseHelper.getChatroomModel(
                                      widget.userModel,
                                      searchedUser,
                                    );
                                if (chatroomModel != null) {
                                  Get.off(() => Chatroompage(
                                    targetUser: searchedUser,
                                    userModel: widget.userModel,
                                    chatRoom: chatroomModel,
                                  ));
                                }
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    isLoading = false;
                                  });
                                }
                              }
                            },
                            leading: CircleAvatar(
                              backgroundImage: (searchedUser.profilepic?.isNotEmpty ?? false) ? NetworkImage(searchedUser.profilepic!) : null,
                              onBackgroundImageError: (searchedUser.profilepic?.isNotEmpty ?? false) ? (_, __) {} : null,
                              child: (searchedUser.profilepic == null || searchedUser.profilepic!.isEmpty) ? const Icon(Icons.person) : null,
                            ),
                            title: Text(searchedUser.fullname ?? ""),
                            subtitle: Text(searchedUser.email ?? ""),
                            trailing: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.keyboard_arrow_right),
                          );
                        } else {
                          return const Text("No results found!");
                        }
                      } else {
                        return const Center(child: CircularProgressIndicator());
                      }
                    } else {
                      return const Center(child: CircularProgressIndicator());
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
