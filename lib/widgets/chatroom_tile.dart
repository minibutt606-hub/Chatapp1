import 'package:chatapp/models/chatroommodel.dart';
import 'package:chatapp/models/firebase_helper.dart';
import 'package:chatapp/models/usermodel.dart';
import 'package:chatapp/pages/call_page.dart';
import 'package:chatapp/pages/chatroompage.dart';
import 'package:chatapp/pages/profile_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

class ChatroomTile extends StatefulWidget {
  final Chatroommodel chatRoomModel;
  final UserModel userModel;

  const ChatroomTile({
    Key? key,
    required this.chatRoomModel,
    required this.userModel,
  }) : super(key: key);

  @override
  State<ChatroomTile> createState() => _ChatroomTileState();
}

class _ChatroomTileState extends State<ChatroomTile> {
  UserModel? targetUser;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  void loadUser() async {
    Map<String, dynamic> participants = widget.chatRoomModel.participants!;
    List<String> participantKeys = participants.keys.toList();
    participantKeys.remove(widget.userModel.uid);

    if (participantKeys.isNotEmpty) {
      UserModel? user = await FirebaseHelper.getUserModelById(
        participantKeys[0],
      );
      if (mounted) {
        setState(() {
          targetUser = user;
        });
      }
    }
  }

  String _getFormattedDate(DateTime date) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime yesterday = today.subtract(const Duration(days: 1));
    DateTime msgDate = DateTime(date.year, date.month, date.day);

    if (msgDate == today) {
      int hour = date.hour > 12
          ? date.hour - 12
          : (date.hour == 0 ? 12 : date.hour);
      String period = date.hour >= 12 ? "PM" : "AM";
      return "$hour:${date.minute.toString().padLeft(2, '0')} $period";
    } else if (msgDate == yesterday) {
      return "Yesterday";
    } else {
      return "${date.day}/${date.month}/${date.year}";
    }
  }

  void _showProfileDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    Get.to(
                      () => Scaffold(
                        backgroundColor: Colors.black,
                        appBar: AppBar(
                          backgroundColor: Colors.black,
                          iconTheme: const IconThemeData(color: Colors.white),
                          title: Text(
                            user.fullname ?? "",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        body: Center(
                          child: InteractiveViewer(
                            child: Hero(
                              tag: "profile_${user.uid}",
                              child: Image.network(
                                user.profilepic!,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.person, size: 100, color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 250,
                    height: 250,
                    color: Colors.grey[300],
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (user.profilepic != null && user.profilepic!.isNotEmpty)
                          Image.network(
                            user.profilepic!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(child: Icon(Icons.person, size: 80, color: Colors.grey)),
                          ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          alignment: Alignment.topLeft,
                          color: Colors.black26,
                          child: Text(
                            user.fullname!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 250,
                  color: context.isDarkMode ? const Color(0xFF111B21) : Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.chat,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Get.to(
                            () => Chatroompage(
                              chatRoom: widget.chatRoomModel,
                              userModel: widget.userModel,
                              targetUser: user,
                            ),
                          );
                        },
                      ),
                      ZegoSendCallInvitationButton(
                        isVideoCall: false,
                        invitees: [],
                        icon: ButtonIcon(
                          icon: Icon(
                            Icons.call,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        buttonSize: const Size(40, 40),
                      ),
                      ZegoSendCallInvitationButton(
                        isVideoCall: true,
                        invitees: [],
                        icon: ButtonIcon(
                          icon: Icon(
                            Icons.videocam,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        buttonSize: const Size(40, 40),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Get.to(
                            () => ProfilePage(
                              targetUser: user,
                              chatRoom: widget.chatRoomModel,
                              currentUser: widget.userModel,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isGroup = widget.chatRoomModel.isGroup;
    bool isFavorite =
        widget.chatRoomModel.favorites?[widget.userModel.uid] == true;

    if (!isGroup && targetUser == null) {
      return const SizedBox(height: 70);
    }

    String title = isGroup
        ? (widget.chatRoomModel.groupName ?? "Group")
        : (targetUser?.fullname ?? "");
    String? imageUrl = isGroup
        ? widget.chatRoomModel.groupPic
        : targetUser?.profilepic;

    return ListTile(
      onTap: () {
        Get.to(
          () => Chatroompage(
            chatRoom: widget.chatRoomModel,
            userModel: widget.userModel,
            targetUser: isGroup
                ? widget.userModel
                : targetUser!,
          ),
        );
      },
      onLongPress: () async {
        bool currentlyFavorite =
            widget.chatRoomModel.favorites?[widget.userModel.uid] ?? false;
        await FirebaseFirestore.instance
            .collection("chatrooms")
            .doc(widget.chatRoomModel.chatroomid)
            .update({"favorites.${widget.userModel.uid}": !currentlyFavorite});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                !currentlyFavorite
                    ? "Added to favorites"
                    : "Removed from favorites",
              ),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
      leading: GestureDetector(
        onTap: () {
          if (imageUrl != null && imageUrl.isNotEmpty) {
            if (isGroup) {
              // Show group photo preview
              Get.to(
                () => Scaffold(
                  backgroundColor: Colors.black,
                  appBar: AppBar(
                    backgroundColor: Colors.black,
                    iconTheme: const IconThemeData(color: Colors.white),
                    title: Text(title, style: const TextStyle(color: Colors.white)),
                  ),
                  body: Center(
                    child: InteractiveViewer(
                      child: Image.network(imageUrl),
                    ),
                  ),
                ),
              );
            } else {
              _showProfileDialog(context, targetUser!);
            }
          }
        },
        child: CircleAvatar(
          backgroundColor: Colors.grey[200],
          child: (imageUrl != null && imageUrl.isNotEmpty)
              ? ClipOval(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: 40,
                    height: 40,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        isGroup ? Icons.groups : Icons.person,
                        color: Colors.white,
                        size: 24,
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    },
                  ),
                )
              : Icon(
                  isGroup ? Icons.groups : Icons.person,
                  color: Colors.white,
                  size: 24,
                ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          if (isFavorite) const Icon(Icons.star, color: Colors.amber, size: 16),
        ],
      ),
      subtitle: (widget.chatRoomModel.lastMessage != "")
          ? Text(
              isGroup && widget.chatRoomModel.lastMessageSenderName != null
                  ? "${widget.chatRoomModel.lastMessageSenderName}: ${widget.chatRoomModel.lastMessage}"
                  : widget.chatRoomModel.lastMessage.toString(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : Text(
              "Say hi to your new friend!",
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
      trailing: SizedBox(
        width: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              widget.chatRoomModel.lastMessageTime != null
                  ? _getFormattedDate(widget.chatRoomModel.lastMessageTime!)
                  : "",
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 5),
            StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("chatrooms")
                  .doc(widget.chatRoomModel.chatroomid)
                  .collection("messages")
                  .where("seen", isEqualTo: false)
                  .snapshots(),
              builder: (context, unreadSnapshot) {
                if (unreadSnapshot.hasData) {
                  int count = unreadSnapshot.data!.docs
                      .where((doc) => doc["sender"] != widget.userModel.uid)
                      .length;

                  // Update unread count in DB if it changed
                  // (Optional: but useful for the filter to be reactive)
                  _syncUnreadCount(count);

                  if (count > 0) {
                    return Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        count.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }
                }
                return const SizedBox(height: 20, width: 20);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _syncUnreadCount(int count) {
    int currentInModel =
        widget.chatRoomModel.unreadCounts?[widget.userModel.uid] ?? 0;
    if (count != currentInModel) {
      FirebaseFirestore.instance
          .collection("chatrooms")
          .doc(widget.chatRoomModel.chatroomid)
          .update({"unreadCounts.${widget.userModel.uid}": count});
    }
  }
}
