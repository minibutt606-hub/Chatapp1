import 'dart:io';
import 'package:chatapp/models/chatroommodel.dart';
import 'package:chatapp/models/firebase_helper.dart';
import 'package:chatapp/models/usermodel.dart';
import 'package:chatapp/pages/disappearing_messages_page.dart';
import 'package:chatapp/pages/media_links_docs_page.dart';
import 'package:chatapp/pages/mute_notifications_page.dart';
import 'package:chatapp/pages/report_user_page.dart';
import 'package:chatapp/services/block_user_service.dart';
import 'package:chatapp/services/chat_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatelessWidget {
  final UserModel targetUser;
  final Chatroommodel chatRoom;
  final UserModel currentUser;

  const ProfilePage({
    Key? key,
    required this.targetUser,
    required this.chatRoom,
    required this.currentUser,
  }) : super(key: key);

  // ─── dialogs ────────────────────────────────────────────────────────────────
  void _clearChat(BuildContext context) async {
    final ok = await _confirmDialog(
      context,
      "Clear chat?",
      "All messages will be deleted for you. This cannot be undone.",
      "Clear",
    );
    if (ok == true) {
      await ChatService.clearChat(chatRoom.chatroomid!);
      Get.snackbar(
        "Done",
        "Chat cleared",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
      );
    }
  }

  void _deleteChat(BuildContext context) async {
    final ok = await _confirmDialog(
      context,
      "Delete chat?",
      "This chat will be deleted for you only.",
      "Delete",
    );
    if (ok == true) {
      await FirebaseFirestore.instance
          .collection("chatrooms")
          .doc(chatRoom.chatroomid)
          .update({"participants.${currentUser.uid}": false});

      Get.until((route) => Get.currentRoute == '/Homepage' || route.isFirst);
    }
  }

  void _updateGroupPic(BuildContext context) async {
    final XFile? image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (image != null) {
      Get.snackbar(
        "Uploading...",
        "Please wait while we update the group picture",
        showProgressIndicator: true,
        snackPosition: SnackPosition.BOTTOM,
      );

      String url = await ChatService.uploadFile(
        File(image.path),
        "group_pics/${chatRoom.chatroomid}.jpg",
      );

      if (url.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection("chatrooms")
            .doc(chatRoom.chatroomid)
            .update({"groupPic": url});

        Get.snackbar(
          "Success",
          "Group picture updated",
          backgroundColor: Colors.green.shade100,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  Future<bool?> _confirmDialog(
    BuildContext context,
    String title,
    String body,
    String confirmLabel,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
        content: Text(
          body,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final priv = targetUser.privacySettings ?? {};
    final bool canSeePhoto = (priv['profilePhoto'] ?? "Everyone") != "Nobody";
    final bool canSeeAbout = (priv['about'] ?? "Everyone") != "Nobody";
    final bool canSeeLastSeen = (priv['lastSeen'] ?? "Nobody") != "Nobody";

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 310,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF202C33) : primary,
            foregroundColor: Colors.white,
            title: const Text(
              "Contact info",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      isDark ? const Color(0xFF202C33) : primary,
                      isDark
                          ? const Color(0xFF111B21)
                          : primary.withValues(alpha: 0.80),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        children: [
                          GestureDetector(
                            onTap: () {
                              String? pic = chatRoom.isGroup
                                  ? chatRoom.groupPic
                                  : targetUser.profilepic;
                              if (pic != null && pic.isNotEmpty) {
                                Get.to(
                                  () => _FullPhoto(
                                    url: pic,
                                    name:
                                        (chatRoom.isGroup
                                            ? chatRoom.groupName
                                            : targetUser.fullname) ??
                                        "",
                                  ),
                                );
                              }
                            },
                            child: Hero(
                              tag:
                                  "profile_${chatRoom.isGroup ? chatRoom.chatroomid : targetUser.uid}",
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.22,
                                      ),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: SizedBox(
                                    width: 100,
                                    height: 100,
                                    child:
                                        (chatRoom.isGroup
                                            ? (chatRoom.groupPic != null &&
                                                  chatRoom.groupPic!.isNotEmpty)
                                            : (canSeePhoto &&
                                                  (targetUser
                                                          .profilepic
                                                          ?.isNotEmpty ??
                                                      false)))
                                        ? Image.network(
                                            chatRoom.isGroup
                                                ? chatRoom.groupPic!
                                                : targetUser.profilepic!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                _avatarFallback(isDark),
                                          )
                                        : _avatarFallback(isDark),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (chatRoom.isGroup &&
                              currentUser.uid == chatRoom.adminId)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => _updateGroupPic(context),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.teal,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        (chatRoom.isGroup
                                ? chatRoom.groupName
                                : targetUser.fullname) ??
                            "User",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (chatRoom.isGroup)
                        Text(
                          "Group • ${chatRoom.participants?.length ?? 0} participants",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        )
                      else if (canSeeLastSeen)
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection("users")
                              .doc(targetUser.uid)
                              .snapshots(),
                          builder: (_, snap) {
                            if (!snap.hasData)
                              return const SizedBox(height: 18);
                            final uData =
                                snap.data?.data() as Map<String, dynamic>?;
                            if (uData == null)
                              return const SizedBox(height: 18);

                            final livePriv = uData['privacySettings'] ?? {};
                            final bool liveCanSeeLastSeen =
                                (livePriv['lastSeen'] ?? "Nobody") != "Nobody";
                            if (!liveCanSeeLastSeen)
                              return const SizedBox(height: 18);

                            final u = UserModel.fromMap(uData);
                            return Text(
                              u.isOnline == true
                                  ? "Online"
                                  : "Last seen recently",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            );
                          },
                        )
                      else
                        const SizedBox(height: 18),
                      const SizedBox(height: 18),
                      if (!chatRoom.isGroup)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _QuickBtn(
                              icon: Icons.message_outlined,
                              label: "Message",
                              onTap: () => Get.back(),
                            ),
                            const SizedBox(width: 32),
                            _QuickBtn(
                              icon: Icons.call_outlined,
                              label: "Voice",
                              onTap: () => Get.back(),
                            ),
                            const SizedBox(width: 32),
                            _QuickBtn(
                              icon: Icons.videocam_outlined,
                              label: "Video",
                              onTap: () => Get.back(),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (chatRoom.isGroup) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Text(
                      "${chatRoom.participants?.length ?? 0} participants",
                      style: TextStyle(
                        color: isDark ? const Color(0xFF00A884) : primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: chatRoom.participants?.length ?? 0,
                    itemBuilder: (context, index) {
                      String userId = chatRoom.participants!.keys.elementAt(
                        index,
                      );
                      return StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection("users")
                            .doc(userId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox();
                          UserModel user = UserModel.fromMap(
                            snapshot.data!.data() as Map<String, dynamic>,
                          );
                          bool isAdmin = user.uid == chatRoom.adminId;

                          return ListTile(
                            onTap: () async {
                              if (user.uid == currentUser.uid) return;

                              // Find or create a 1-to-1 chatroom with this user
                              Chatroommodel? targetChatroom =
                                  await FirebaseHelper.getChatroomModel(
                                    currentUser,
                                    user,
                                  );

                              if (targetChatroom != null) {
                                Get.to(
                                  () => ProfilePage(
                                    targetUser: user,
                                    chatRoom: targetChatroom,
                                    currentUser: currentUser,
                                  ),
                                );
                              }
                            },
                            leading: CircleAvatar(
                              backgroundColor: isDark
                                  ? const Color(0xFF202C33)
                                  : Colors.grey[200],
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
                              child:
                                  (user.profilepic == null ||
                                      user.profilepic!.isEmpty)
                                  ? Icon(
                                      Icons.person,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.grey,
                                    )
                                  : null,
                            ),
                            title: Text(
                              user.uid == currentUser.uid
                                  ? "You"
                                  : (user.fullname ?? ""),
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            subtitle: Text(
                              user.about ?? "",
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            trailing: isAdmin
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.teal),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      "Group Admin",
                                      style: TextStyle(
                                        color: Colors.teal,
                                        fontSize: 10,
                                      ),
                                    ),
                                  )
                                : null,
                          );
                        },
                      );
                    },
                  ),
                  _divider(isDark),
                ],
                if (!chatRoom.isGroup && canSeeAbout)
                  _FlatRow(
                    icon: Icons.info_outline,
                    color: Colors.teal,
                    primary: targetUser.about ?? "Available",
                    secondary: "About",
                  ),
                if (canSeeAbout) _divider(isDark),
                _FlatRow(
                  icon: Icons.phone_outlined,
                  color: Colors.green,
                  primary: (targetUser.phoneNumber?.isNotEmpty ?? false)
                      ? targetUser.phoneNumber!
                      : targetUser.email ?? "—",
                  secondary: "Phone",
                ),
                _divider(isDark),
                _FlatArrowRow(
                  icon: Icons.photo_library_outlined,
                  color: Colors.blue,
                  label: "Media, links and docs",
                  badge: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("chatrooms")
                        .doc(chatRoom.chatroomid)
                        .collection("messages")
                        .where("type", whereIn: ["image", "video", "document"])
                        .snapshots(),
                    builder: (_, s) {
                      final n = s.data?.docs.length ?? 0;
                      return Text(
                        "$n",
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                        ),
                      );
                    },
                  ),
                  onTap: () =>
                      Get.to(() => MediaLinksDocsPage(chatRoom: chatRoom)),
                ),
                _divider(isDark),
                _FlatArrowRow(
                  icon: Icons.notifications_outlined,
                  color: Colors.orange,
                  label: "Mute notifications",
                  onTap: () => Get.to(
                    () => MuteNotificationsPage(
                      chatRoom: chatRoom,
                      currentUserId: currentUser.uid!,
                    ),
                  ),
                ),
                _divider(isDark),
                _FlatArrowRow(
                  icon: Icons.timer_outlined,
                  color: Colors.purple,
                  label: "Disappearing messages",
                  onTap: () => Get.to(
                    () => DisappearingMessagesPage(chatRoom: chatRoom),
                  ),
                ),
                _divider(isDark),
                _FlatArrowRow(
                  icon: Icons.lock_outlined,
                  color: Colors.indigo,
                  label: "Encryption",
                  sublabel: "Messages are end-to-end encrypted",
                  onTap: () => Get.snackbar(
                    "Encrypted",
                    "Your messages are secured.",
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.green.shade100,
                  ),
                ),
                _divider(isDark),
                _FlatArrowRow(
                  icon: Icons.delete_outline,
                  color: Colors.red,
                  label: "Clear chat",
                  textColor: Colors.red,
                  onTap: () => _clearChat(context),
                ),
                _divider(isDark),
                _FlatArrowRow(
                  icon: Icons.delete_forever_outlined,
                  color: Colors.red,
                  label: "Delete chat",
                  textColor: Colors.red,
                  onTap: () => _deleteChat(context),
                ),
                _divider(isDark),
                _FlatArrowRow(
                  icon: Icons.flag_outlined,
                  color: Colors.red,
                  label: "Report ${targetUser.fullname ?? 'user'}",
                  textColor: Colors.red,
                  onTap: () => Get.to(
                    () => ReportUserPage(
                      targetUser: targetUser,
                      currentUser: currentUser,
                    ),
                  ),
                ),
                _divider(isDark),
                StreamBuilder<bool>(
                  stream: BlockUserService.isBlockedStream(
                    currentUser.uid!,
                    targetUser.uid!,
                  ),
                  builder: (_, s) {
                    final isBlocked = s.data ?? false;
                    return _FlatArrowRow(
                      icon: isBlocked ? Icons.lock_open_outlined : Icons.block,
                      color: Colors.red,
                      label: isBlocked
                          ? "Unblock ${targetUser.fullname ?? 'user'}"
                          : "Block ${targetUser.fullname ?? 'user'}",
                      textColor: Colors.red,
                      onTap: isBlocked
                          ? () => BlockUserService.unblockUser(
                              currentUserId: currentUser.uid!,
                              targetUserId: targetUser.uid!,
                              targetUserName: targetUser.fullname ?? "User",
                            )
                          : () => BlockUserService.blockUser(
                              currentUserId: currentUser.uid!,
                              targetUserId: targetUser.uid!,
                              targetUserName: targetUser.fullname ?? "User",
                              context: context,
                            ),
                    );
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(bool isDark) => Divider(
    height: 1,
    indent: 56,
    color: isDark ? const Color(0xFF232D36) : Colors.grey.shade100,
  );

  Widget _avatarFallback(bool isDark) => Container(
    color: isDark ? const Color(0xFF202C33) : Colors.grey.shade300,
    child: Icon(
      Icons.person,
      size: 50,
      color: isDark ? Colors.white30 : Colors.white,
    ),
  );
}

class _FlatRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String primary;
  final String secondary;
  const _FlatRow({
    required this.icon,
    required this.color,
    required this.primary,
    required this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                primary,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                secondary,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FlatArrowRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String? sublabel;
  final Color? textColor;
  final Widget? badge;
  final VoidCallback onTap;

  const _FlatArrowRow({
    required this.icon,
    required this.color,
    required this.label,
    this.sublabel,
    this.textColor,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        label,
        style: TextStyle(
          color: textColor ?? (isDark ? Colors.white : Colors.black87),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: sublabel != null
          ? Text(
              sublabel!,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null) badge!,
          Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _QuickBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
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
            tag: "profile_photo_$url",
            child: Image.network(
              url,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.broken_image, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
