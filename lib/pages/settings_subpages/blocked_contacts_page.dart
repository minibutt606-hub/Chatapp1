import 'package:chatapp/models/usermodel.dart';
import 'package:chatapp/services/block_user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BlockedContactsPage extends StatelessWidget {
  final UserModel userModel;
  const BlockedContactsPage({Key? key, required this.userModel}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Blocked contacts", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        surfaceTintColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection("users").doc(userModel.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final blockedMap = data?['blockedUsers'] as Map<dynamic, dynamic>? ?? {};
          final blockedIds = blockedMap.keys.where((k) => blockedMap[k] == true).cast<String>().toList();

          if (blockedIds.isEmpty) {
            return const Center(child: Text("No blocked contacts", style: TextStyle(fontSize: 16, color: Colors.grey)));
          }

          return ListView.builder(
            itemCount: blockedIds.length,
            itemBuilder: (context, index) {
              final id = blockedIds[index];
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection("users").doc(id).get(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) return const ListTile(title: Text("Loading..."));
                  
                  final tData = userSnap.data!.data() as Map<String, dynamic>?;
                  if (tData == null) return const SizedBox();
                  
                  final tName = tData['fullname'] ?? "Unknown";
                  final tPic = tData['profilepic'] ?? "";
                  
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: tPic.isNotEmpty ? NetworkImage(tPic) : null,
                      onBackgroundImageError: tPic.isNotEmpty ? (_, __) {} : null,
                      child: tPic.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
                    ),
                    title: Text(tName, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: Text("Unblock $tName?", style: const TextStyle(fontWeight: FontWeight.bold)),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white),
                              onPressed: () {
                                Navigator.pop(ctx);
                                BlockUserService.unblockUser(
                                  currentUserId: userModel.uid!,
                                  targetUserId: id,
                                  targetUserName: tName,
                                );
                              },
                              child: const Text("Unblock"),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
