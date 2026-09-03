import 'package:chatapp/models/chatroommodel.dart';
import 'package:chatapp/models/firebase_helper.dart';
import 'package:chatapp/models/usermodel.dart';
import 'package:chatapp/pages/chatroompage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CallsTab extends StatelessWidget {
  final UserModel userModel;

  const CallsTab({Key? key, required this.userModel}) : super(key: key);

  Future<void> _openChatroom(BuildContext context, String receiverId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final targetUser = await FirebaseHelper.getUserModelById(receiverId);
      if (targetUser == null) {
        Navigator.pop(context);
        Get.snackbar("Error", "User not found",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade100);
        return;
      }

      final myId = userModel.uid!;
      final ids = [myId, receiverId]..sort();
      final chatroomId = "${ids[0]}_${ids[1]}";

      DocumentSnapshot roomDoc = await FirebaseFirestore.instance
          .collection("chatrooms")
          .doc(chatroomId)
          .get();

      Chatroommodel chatRoom;
      if (roomDoc.exists) {
        chatRoom = Chatroommodel.fromMap(roomDoc.data() as Map<String, dynamic>);
      } else {
        chatRoom = Chatroommodel(
          chatroomid: chatroomId,
          participants: {myId: true, receiverId: true},
          lastMessage: "",
        );
        await FirebaseFirestore.instance
            .collection("chatrooms")
            .doc(chatroomId)
            .set(chatRoom.toMap());
      }

      Navigator.pop(context);

      Get.to(() => Chatroompage(
            targetUser: targetUser,
            userModel: userModel,
            chatRoom: chatRoom,
          ));
    } catch (e) {
      Navigator.pop(context);
      Get.snackbar("Error", "Could not open chat: $e",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color primaryColor = isDark ? const Color(0xFF00A884) : Theme.of(context).colorScheme.primary;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("users")
          .doc(userModel.uid)
          .collection("calls")
          .orderBy("time", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.call_outlined, size: 72, color: isDark ? Colors.white10 : Colors.grey.shade200),
                const SizedBox(height: 16),
                Text("No recent calls",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white60 : Colors.black38)),
                const SizedBox(height: 6),
                Text("Your call history will appear here",
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white24 : Colors.grey.shade400)),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;

        return ListView.separated(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          itemCount: docs.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, indent: 72, color: isDark ? const Color(0xFF232D36) : Colors.grey.shade100),
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final name = data["name"] as String? ?? "Unknown";
            final timeStr = data["time_string"] as String? ?? "";
            final isVideo = data["isVideo"] as bool? ?? false;
            final isMissed = data["isMissed"] as bool? ?? false;
            final isReceived = data["isReceived"] as bool? ?? false;
            final receiverId = data["receiverId"] as String?;

            String timeLabel = timeStr;
            if (data["time"] != null) {
              final dt = (data["time"] as Timestamp).toDate();
              final now = DateTime.now();
              final diff = now.difference(dt);
              if (diff.inDays == 0) {
                timeLabel = "Today $timeStr";
              } else if (diff.inDays == 1) {
                timeLabel = "Yesterday $timeStr";
              } else {
                timeLabel = "${dt.day}/${dt.month}/${dt.year} $timeStr";
              }
            }

            final Color statusColor = isMissed ? Colors.red : (isDark ? const Color(0xFF00A884) : primaryColor);
            final IconData directionIcon = isReceived ? Icons.call_received_rounded : Icons.call_made_rounded;

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: FutureBuilder<UserModel?>(
                future: receiverId != null
                    ? FirebaseHelper.getUserModelById(receiverId)
                    : Future.value(null),
                builder: (_, snap) {
                  final pic = snap.data?.profilepic;
                  return CircleAvatar(
                    radius: 26,
                    backgroundColor: isDark ? const Color(0xFF202C33) : Colors.grey.shade200,
                    backgroundImage: (pic != null && pic.isNotEmpty) ? NetworkImage(pic) : null,
                    onBackgroundImageError: (pic != null && pic.isNotEmpty) ? (_, __) {} : null,
                    child: (pic == null || pic.isEmpty)
                        ? Icon(Icons.person, color: isDark ? Colors.white24 : Colors.grey.shade400, size: 26)
                        : null,
                  );
                },
              ),
              title: Text(name,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: isMissed ? Colors.red : (isDark ? Colors.white : Colors.black87))),
              subtitle: Row(
                children: [
                  Icon(directionIcon, size: 13, color: statusColor),
                  const SizedBox(width: 4),
                  Text(timeLabel,
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey.shade600)),
                ],
              ),
              trailing: IconButton(
                icon: Icon(
                  isVideo ? Icons.videocam_outlined : Icons.call_outlined,
                  color: isDark ? const Color(0xFF00A884) : primaryColor,
                  size: 22,
                ),
                tooltip: isVideo ? "Video call" : "Voice call",
                onPressed: receiverId != null ? () => _openChatroom(context, receiverId) : null,
              ),
              onTap: receiverId != null ? () => _openChatroom(context, receiverId) : null,
            );
          },
        );
      },
    );
  }
}
