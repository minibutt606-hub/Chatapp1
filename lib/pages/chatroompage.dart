import 'dart:async';
import 'dart:io';
import 'package:chatapp/models/chatroommodel.dart';
import 'package:chatapp/models/firebase_helper.dart';
import 'package:chatapp/models/messagemodel.dart';
import 'package:chatapp/models/usermodel.dart';
import 'package:chatapp/pages/disappearing_messages_page.dart';
import 'package:chatapp/pages/media_links_docs_page.dart';
import 'package:chatapp/pages/mute_notifications_page.dart';
import 'package:chatapp/pages/profile_page.dart';
import 'package:chatapp/pages/report_user_page.dart';
import 'package:chatapp/pages/search_chat_page.dart';
import 'package:chatapp/services/block_user_service.dart';
import 'package:chatapp/services/chat_export_service.dart';
import 'package:chatapp/services/chat_service.dart';
import 'package:chatapp/widgets/chat_input_row.dart';
import 'package:chatapp/widgets/message_widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

class Chatroompage extends StatefulWidget {
  final UserModel targetUser;
  final Chatroommodel chatRoom;
  final UserModel userModel;

  const Chatroompage({
    Key? key,
    required this.targetUser,
    required this.chatRoom,
    required this.userModel,
  }) : super(key: key);

  @override
  State<Chatroompage> createState() => _ChatroompageState();
}

class _ChatroompageState extends State<Chatroompage>
    with WidgetsBindingObserver {
  TextEditingController messageController = TextEditingController();
  StreamSubscription? seenSubscription;
  bool isRecording = false;
  DateTime? recordingStartTime;
  bool showEmoji = false;
  FocusNode focusNode = FocusNode();
  final record = AudioRecorder();

  File? uploadingImageTemp;
  bool isUploading = false;
  String uploadingType = "image"; // "image" or "audio"
  double _fontSize = 16;
  String? _wallpaperPath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPreferences();
    setUserStatus(true);
    markMessagesAsSeen();
    focusNode.addListener(() {
      if (focusNode.hasFocus) setState(() => showEmoji = false);
    });
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    String fontSizePref = prefs.getString('font_size') ?? "Medium";
    _wallpaperPath = prefs.getString('chat_wallpaper');

    setState(() {
      if (fontSizePref == "Small")
        _fontSize = 13;
      else if (fontSizePref == "Large")
        _fontSize = 20;
      else
        _fontSize = 16;
    });
  }

  @override
  void dispose() {
    focusNode.dispose();
    record.dispose();
    seenSubscription?.cancel();
    setUserStatus(false);
    ChatService.updateTypingStatus(
      widget.chatRoom.chatroomid!,
      widget.userModel.uid!,
      "",
    );
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed)
      setUserStatus(true);
    else
      setUserStatus(false);
  }

  void setUserStatus(bool isOnline) {
    FirebaseFirestore.instance
        .collection("users")
        .doc(widget.userModel.uid)
        .update({"isOnline": isOnline});
  }

  void markMessagesAsSeen() {
    seenSubscription = FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(widget.chatRoom.chatroomid)
        .collection("messages")
        .where("seen", isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
          for (var doc in snapshot.docs) {
            // ONLY mark as seen if the message was sent by SOMEONE ELSE
            if (doc["sender"] != widget.userModel.uid) {
              doc.reference.update({
                "seen": true,
                "seenBy": FieldValue.arrayUnion([widget.userModel.uid]),
              });
            }
          }
        });
  }

  void sendMessage() {
    String msg = messageController.text.trim();
    if (msg.isNotEmpty) {
      ChatService.sendMessage(
        chatroomId: widget.chatRoom.chatroomid!,
        senderId: widget.userModel.uid!,
        text: msg,
        senderName: widget.userModel.fullname,
      );
      messageController.clear();
      setState(() {});
      ChatService.updateTypingStatus(
        widget.chatRoom.chatroomid!,
        widget.userModel.uid!,
        "",
      );
    }
  }

  void sendAudio(String path, int duration) async {
    setState(() {
      uploadingImageTemp = File(path);
      isUploading = true;
      uploadingType = "audio";
    });
    String audioUrl = await ChatService.uploadFile(
      File(path),
      "chat_audio/${widget.chatRoom.chatroomid}/${DateTime.now().millisecondsSinceEpoch}.m4a",
      type: "audio",
    );
    ChatService.sendMessage(
      chatroomId: widget.chatRoom.chatroomid!,
      senderId: widget.userModel.uid!,
      text: "Voice message",
      type: "audio",
      imageUrl: audioUrl,
      duration: duration,
      senderName: widget.userModel.fullname,
    );
    if (mounted) {
      setState(() {
        uploadingImageTemp = null;
        isUploading = false;
      });
    }
  }

  Future<void> sendImage(ImageSource source) async {
    PermissionStatus status = source == ImageSource.camera
        ? await Permission.camera.request()
        : await Permission.photos.request();
    if (status.isDenied) return;

    final XFile? pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile == null) return;

    setState(() {
      uploadingImageTemp = File(pickedFile.path);
      isUploading = true;
    });

    String imageUrl = await ChatService.uploadFile(
      File(pickedFile.path),
      "chat_images/${widget.chatRoom.chatroomid}/${DateTime.now().millisecondsSinceEpoch}.jpg",
      type: "image",
    );
    ChatService.sendMessage(
      chatroomId: widget.chatRoom.chatroomid!,
      senderId: widget.userModel.uid!,
      text: "Photo",
      type: "image",
      imageUrl: imageUrl,
      senderName: widget.userModel.fullname,
    );

    if (mounted) {
      setState(() {
        uploadingImageTemp = null;
        isUploading = false;
      });
    }
  }

  Future<void> sendVideo() async {
    final XFile? pickedFile = await ImagePicker().pickVideo(
      source: ImageSource.gallery,
    );
    if (pickedFile == null) return;

    String videoUrl = await ChatService.uploadFile(
      File(pickedFile.path),
      "chat_videos/${widget.chatRoom.chatroomid}/${DateTime.now().millisecondsSinceEpoch}.mp4",
      type: "video",
    );

    ChatService.sendMessage(
      chatroomId: widget.chatRoom.chatroomid!,
      senderId: widget.userModel.uid!,
      text: "Video",
      type: "video",
      imageUrl: videoUrl,
      senderName: widget.userModel.fullname,
    );
  }

  void toggleRecording() async {
    if (isRecording) {
      final path = await record.stop();
      int duration = 0;
      if (recordingStartTime != null) {
        duration = DateTime.now().difference(recordingStartTime!).inSeconds;
      }
      setState(() => isRecording = false);
      if (path != null) sendAudio(path, duration);
    } else {
      if (await record.hasPermission()) {
        final path =
            '${Directory.systemTemp.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await record.start(const RecordConfig(), path: path);
        recordingStartTime = DateTime.now();
        setState(() => isRecording = true);
      }
    }
  }

  void pickFile(FileType type) async {
    Get.back();
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: type);
    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      String fileName = result.files.single.name;
      String fileUrl = await ChatService.uploadFile(
        file,
        "chat_files/${widget.chatRoom.chatroomid}/${DateTime.now().millisecondsSinceEpoch}_$fileName",
        type: type == FileType.audio ? "audio" : "document",
      );
      ChatService.sendMessage(
        chatroomId: widget.chatRoom.chatroomid!,
        senderId: widget.userModel.uid!,
        text: fileName,
        type: type == FileType.audio ? "audio" : "document",
        imageUrl: fileUrl,
      );
    }
  }

  void shareLocation() async {
    Get.back();
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    Position position = await Geolocator.getCurrentPosition();
    ChatService.sendMessage(
      chatroomId: widget.chatRoom.chatroomid!,
      senderId: widget.userModel.uid!,
      text: "Pinned Location",
      type: "location",
      imageUrl:
          "https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}",
    );
  }

  void shareContact() async {
    Get.back();
    // Show a simple contact picker (fetching from all users)
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Contact"),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: StreamBuilder(
            stream: FirebaseFirestore.instance.collection("users").snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              var users = snapshot.data!.docs;
              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  var user = UserModel.fromMap(users[index].data());
                  if (user.uid == widget.userModel.uid) return const SizedBox();
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: (user.profilepic?.isNotEmpty ?? false)
                          ? NetworkImage(user.profilepic!)
                          : null,
                      onBackgroundImageError: (user.profilepic?.isNotEmpty ?? false) ? (_, __) {} : null,
                      child: (user.profilepic == null || user.profilepic!.isEmpty)
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(user.fullname ?? ""),
                    onTap: () {
                      Navigator.pop(context);
                      ChatService.sendMessage(
                        chatroomId: widget.chatRoom.chatroomid!,
                        senderId: widget.userModel.uid!,
                        text: user.fullname!,
                        type: "contact",
                        imageUrl:
                            user.uid, // Storing target user UID in imageUrl
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 350,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: GridView.count(
          crossAxisCount: 3,
          padding: const EdgeInsets.all(20),
          mainAxisSpacing: 10,
          children: [
            _buildAction(
              Icons.insert_drive_file,
              "Document",
              Colors.indigo,
              () => pickFile(FileType.any),
            ),
            _buildAction(Icons.camera_alt, "Camera", Colors.pink, () {
              Get.back();
              sendImage(ImageSource.camera);
            }),
            _buildAction(Icons.photo, "Gallery", Colors.purple, () {
              Get.back();
              sendImage(ImageSource.gallery);
            }),
            _buildAction(Icons.videocam, "Video", Colors.red, () {
              Get.back();
              sendVideo();
            }),
            _buildAction(
              Icons.headset,
              "Audio",
              Colors.orange,
              () => pickFile(FileType.audio),
            ),
            _buildAction(
              Icons.location_on,
              "Location",
              Colors.green,
              shareLocation,
            ),
            _buildAction(
              Icons.person,
              "Contact",
              Theme.of(context).colorScheme.primary,
              shareContact,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAction(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  void _showMoreOptions() {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromLTRB(
      overlay.size.width - 200,
      kToolbarHeight + MediaQuery.of(context).padding.top,
      10,
      0,
    );

    showMenu<String>(
      context: context,
      position: position,
      elevation: 8,
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF233138)
          : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        _menuItem(Icons.flag_outlined, "report", "Report", Colors.red),
        _menuItem(Icons.block, "block", "Block", Colors.red),
        const PopupMenuDivider(),
        _menuItem(
          Icons.delete_sweep_outlined,
          "clear",
          "Clear chat",
          Colors.red,
        ),
        _menuItem(
          Icons.share_outlined,
          "export",
          "Export chat",
          Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFFE9EDEF)
              : Colors.black87,
        ),
        _menuItem(
          Icons.add_to_home_screen,
          "shortcut",
          "Add shortcut",
          Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFFE9EDEF)
              : Colors.black87,
        ),
      ],
    ).then((val) async {
      if (val == null) return;
      switch (val) {
        case "clear":
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                "Clear chat?",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: const Text(
                "All messages will be deleted. This cannot be undone.",
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
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text("Clear"),
                ),
              ],
            ),
          );
          if (ok == true) ChatService.clearChat(widget.chatRoom.chatroomid!);
          break;
        case "export":
          ChatExportService.exportChat(
            context: context,
            chatRoom: widget.chatRoom,
            currentUserId: widget.userModel.uid!,
            targetUserName: widget.targetUser.fullname ?? "User",
          );
          break;
        case "report":
          Get.to(
            () => ReportUserPage(
              targetUser: widget.targetUser,
              currentUser: widget.userModel,
            ),
          );
          break;
        case "block":
          BlockUserService.blockUser(
            currentUserId: widget.userModel.uid!,
            targetUserId: widget.targetUser.uid!,
            targetUserName: widget.targetUser.fullname ?? "User",
            context: context,
          );
          break;
        case "shortcut":
          Get.snackbar(
            "Shortcut",
            "Long-press the app icon to find this chat.",
            snackPosition: SnackPosition.BOTTOM,
          );
          break;
      }
    });
  }

  void _showMainMenu() {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromLTRB(
      overlay.size.width - 220,
      kToolbarHeight + MediaQuery.of(context).padding.top,
      10,
      0,
    );

    showMenu<String>(
      context: context,
      position: position,
      elevation: 8,
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF233138)
          : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: <PopupMenuEntry<String>>[
        _menuItem(
          Icons.person_outline,
          "contact",
          "View contact",
          Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFFE9EDEF)
              : Colors.black87,
        ),
        _menuItem(
          Icons.photo_library_outlined,
          "media",
          "Media, links and docs",
          Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFFE9EDEF)
              : Colors.black87,
        ),
        _menuItem(
          Icons.search,
          "search",
          "Search",
          Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFFE9EDEF)
              : Colors.black87,
        ),
        _menuItem(
          Icons.notifications_outlined,
          "mute",
          "Mute notifications",
          Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFFE9EDEF)
              : Colors.black87,
        ),
        _menuItem(
          Icons.timer_outlined,
          "disappearing",
          "Disappearing messages",
          Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFFE9EDEF)
              : Colors.black87,
        ),
        PopupMenuItem<String>(
          value: "more",
          child: Row(
            children: [
              Icon(
                Icons.more_horiz,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFE9EDEF)
                    : Colors.grey.shade600,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                "More",
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFE9EDEF)
                      : Colors.black87,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_right,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFE9EDEF)
                    : Colors.grey,
                size: 20,
              ),
            ],
          ),
        ),
      ],
    ).then((val) {
      if (val == null) return;
      switch (val) {
        case "contact":
          Get.to(
            () => ProfilePage(
              targetUser: widget.targetUser,
              chatRoom: widget.chatRoom,
              currentUser: widget.userModel,
            ),
          );
          break;
        case "media":
          Get.to(() => MediaLinksDocsPage(chatRoom: widget.chatRoom));
          break;
        case "search":
          Get.to(
            () => SearchChatPage(
              chatRoom: widget.chatRoom,
              currentUserId: widget.userModel.uid!,
            ),
          );
          break;
        case "mute":
          Get.to(
            () => MuteNotificationsPage(
              chatRoom: widget.chatRoom,
              currentUserId: widget.userModel.uid!,
            ),
          );
          break;
        case "disappearing":
          Get.to(() => DisappearingMessagesPage(chatRoom: widget.chatRoom));
          break;

        case "more":
          _showMoreOptions();
          break;
      }
    });
  }

  // ── helper to build icon menu items ─────────────────────────────────
  PopupMenuItem<String> _menuItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 14, color: color)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF202C33)
            : Theme.of(context).colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: GestureDetector(
          onTap: () {
            Get.to(
              () => ProfilePage(
                targetUser: widget.targetUser,
                chatRoom: widget.chatRoom,
                currentUser: widget.userModel,
              ),
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey[200],
                child:
                    (widget.chatRoom.isGroup
                        ? (widget.chatRoom.groupPic != null &&
                              widget.chatRoom.groupPic!.isNotEmpty)
                        : (widget.targetUser.profilepic != null &&
                              widget.targetUser.profilepic!.isNotEmpty))
                    ? ClipOval(
                        child: Image.network(
                          widget.chatRoom.isGroup
                              ? widget.chatRoom.groupPic!
                              : widget.targetUser.profilepic!,
                          fit: BoxFit.cover,
                          width: 36,
                          height: 36,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              widget.chatRoom.isGroup
                                  ? Icons.groups
                                  : Icons.person,
                              color: Colors.white,
                              size: 18,
                            );
                          },
                        ),
                      )
                    : Icon(
                        widget.chatRoom.isGroup ? Icons.groups : Icons.person,
                        color: Colors.white,
                        size: 18,
                      ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (widget.chatRoom.isGroup
                              ? widget.chatRoom.groupName
                              : widget.targetUser.fullname) ??
                          "",
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    widget.chatRoom.isGroup
                        ? const Text(
                            "Group",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                          )
                        : StreamBuilder(
                            stream: FirebaseFirestore.instance
                                .collection("users")
                                .doc(widget.targetUser.uid)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData ||
                                  snapshot.data?.data() == null)
                                return const SizedBox();
                              UserModel user = UserModel.fromMap(
                                snapshot.data!.data() as Map<String, dynamic>,
                              );
                              bool isTyping =
                                  user.typingStatus ==
                                  widget.chatRoom.chatroomid;
                              bool isOnline = user.isOnline ?? false;
                              String statusText = "";
                              if (isTyping) {
                                statusText = "typing...";
                              } else if (isOnline) {
                                statusText = "online";
                              } else if (user.lastSeen != null) {
                                final now = DateTime.now();
                                final difference = now.difference(
                                  user.lastSeen!,
                                );
                                if (difference.inDays == 0 &&
                                    now.day == user.lastSeen!.day) {
                                  final hour = user.lastSeen!.hour > 12
                                      ? user.lastSeen!.hour - 12
                                      : (user.lastSeen!.hour == 0
                                            ? 12
                                            : user.lastSeen!.hour);
                                  final ampm = user.lastSeen!.hour >= 12
                                      ? "PM"
                                      : "AM";
                                  final minute = user.lastSeen!.minute
                                      .toString()
                                      .padLeft(2, '0');
                                  statusText =
                                      "last seen at $hour:$minute $ampm";
                                } else if (difference.inDays == 1 ||
                                    (difference.inDays == 0 &&
                                        now.day != user.lastSeen!.day)) {
                                  statusText = "last seen yesterday";
                                } else {
                                  statusText =
                                      "last seen on ${user.lastSeen!.day}/${user.lastSeen!.month}/${user.lastSeen!.year}";
                                }
                              }

                              return Text(
                                statusText,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white70,
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Video call button — Zego internally renders at 74×74 so we clip it
          // Video call button — Zego internally renders at 74×74 so we clip it
          SizedBox(
            width: 40,
            height: 40,
            child: ClipRect(
              child: OverflowBox(
                maxWidth: 74,
                maxHeight: 74,
                alignment: Alignment.center,
                child: ZegoSendCallInvitationButton(
                  isVideoCall: true,
                  invitees: widget.chatRoom.isGroup!
                      ? widget.chatRoom.participants!.keys
                          .where((uid) => uid != widget.userModel.uid)
                          .map((uid) => ZegoUIKitUser(id: uid, name: "Group Participant"))
                          .toList()
                      : [
                          ZegoUIKitUser(
                            id: widget.targetUser.uid!,
                            name: widget.targetUser.fullname ?? "User",
                          ),
                        ],
                  icon: ButtonIcon(
                    icon: const Icon(
                      Icons.videocam,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  buttonSize: const Size(74, 74),
                  iconSize: const Size(22, 22),
                  onPressed:
                      (
                        String code,
                        String message,
                        List<String> errorInvitees,
                      ) {
                        FirebaseHelper.saveCallLog(
                          senderId: widget.userModel.uid!,
                          receiverId: widget.chatRoom.isGroup! ? "group_${widget.chatRoom.chatroomid}" : widget.targetUser.uid!,
                          receiverName: widget.chatRoom.isGroup! ? (widget.chatRoom.groupName ?? "Group") : (widget.targetUser.fullname ?? "User"),
                          isVideo: true,
                        );
                      },
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Voice call button
          // Voice call button
          SizedBox(
            width: 40,
            height: 40,
            child: ClipRect(
              child: OverflowBox(
                maxWidth: 74,
                maxHeight: 74,
                alignment: Alignment.center,
                child: ZegoSendCallInvitationButton(
                  isVideoCall: false,
                  invitees: widget.chatRoom.isGroup!
                      ? widget.chatRoom.participants!.keys
                          .where((uid) => uid != widget.userModel.uid)
                          .map((uid) => ZegoUIKitUser(id: uid, name: "Group Participant"))
                          .toList()
                      : [
                          ZegoUIKitUser(
                            id: widget.targetUser.uid!,
                            name: widget.targetUser.fullname ?? "User",
                          ),
                        ],
                  icon: ButtonIcon(
                    icon: const Icon(
                      Icons.call,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  buttonSize: const Size(74, 74),
                  iconSize: const Size(22, 22),
                  onPressed:
                      (
                        String code,
                        String message,
                        List<String> errorInvitees,
                      ) {
                        FirebaseHelper.saveCallLog(
                          senderId: widget.userModel.uid!,
                          receiverId: widget.chatRoom.isGroup! ? "group_${widget.chatRoom.chatroomid}" : widget.targetUser.uid!,
                          receiverName: widget.chatRoom.isGroup! ? (widget.chatRoom.groupName ?? "Group") : (widget.targetUser.fullname ?? "User"),
                          isVideo: false,
                        );
                      },
                ),
              ),
            ),
          ),
          // More menu
          IconButton(
            padding: EdgeInsets.zero,
            onPressed: _showMainMenu,
            icon: const Icon(Icons.more_vert, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: WillPopScope(
        onWillPop: () async {
          if (showEmoji) {
            setState(() => showEmoji = false);
            return false;
          }
          return true;
        },
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF0B141A)
                : const Color(0xFFEFE7DE),
            image: _wallpaperPath != null
                ? DecorationImage(
                    image: NetworkImage(_wallpaperPath!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: Column(
            children: [
              Expanded(
                child: StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection("chatrooms")
                      .doc(widget.chatRoom.chatroomid)
                      .collection("messages")
                      .orderBy("createdon", descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const Center(child: CircularProgressIndicator());
                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 20,
                      ),
                      itemCount:
                          snapshot.data!.docs.length + (isUploading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (isUploading && index == 0) {
                          return Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: EdgeInsets.all(
                                uploadingType == "audio" ? 10 : 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: uploadingType == "audio"
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(
                                          width: 32,
                                          height: 32,
                                          child: Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          "Sending voice...",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    )
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: SizedBox(
                                        width: 220,
                                        height: 180,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Image.file(
                                              uploadingImageTemp!,
                                              width: 220,
                                              height: 180,
                                              fit: BoxFit.cover,
                                            ),
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: const BoxDecoration(
                                                color: Colors.black45,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Padding(
                                                padding: EdgeInsets.all(6.0),
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2.5,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                            ),
                          );
                        }

                        // Shift index if uploading bubble is present
                        int actualIndex = isUploading ? index - 1 : index;
                        return MessageWidget(
                          currentMessage: Messagemodel.fromMap(
                            snapshot.data!.docs[actualIndex].data(),
                          ),
                          widget: widget,
                          fontSize: _fontSize,
                        );
                      },
                    );
                  },
                ),
              ),
              // Typing Indicator
              StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection("users")
                    .where(
                      "typingStatus",
                      isEqualTo: widget.chatRoom.chatroomid,
                    )
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    // Filter out the current user
                    var typingUsers = snapshot.data!.docs
                        .where((doc) => doc.id != widget.userModel.uid)
                        .toList();

                    if (typingUsers.isNotEmpty) {
                      String typingText = "";
                      if (typingUsers.length == 1) {
                        typingText =
                            "${typingUsers[0]['fullname']} is typing...";
                      } else {
                        typingText =
                            "${typingUsers.length} people are typing...";
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            Text(
                              typingText,
                              style: const TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const JumpingDots(numberOfDots: 3),
                          ],
                        ),
                      );
                    }
                  }
                  return const SizedBox.shrink();
                },
              ),
              // Input bar with bottom safe area
              Container(
                color: Colors.grey[100],
                child: ChatInputRow(
                  messageController: messageController,
                  focusNode: focusNode,
                  showEmoji: showEmoji,
                  isRecording: isRecording,
                  onToggleEmoji: () {
                    focusNode.unfocus();
                    setState(() => showEmoji = !showEmoji);
                  },
                  onAttachment: showAttachmentMenu,
                  onCamera: () => sendImage(ImageSource.camera),
                  onSendMessage: sendMessage,
                  onToggleRecording: toggleRecording,
                  onChanged: (val) {
                    setState(() {});
                    ChatService.updateTypingStatus(
                      widget.chatRoom.chatroomid!,
                      widget.userModel.uid!,
                      val.isNotEmpty ? widget.chatRoom.chatroomid! : "",
                    );
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

class JumpingDots extends StatefulWidget {
  final int numberOfDots;
  const JumpingDots({Key? key, this.numberOfDots = 3}) : super(key: key);
  @override
  _JumpingDotsState createState() => _JumpingDotsState();
}

class _JumpingDotsState extends State<JumpingDots>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  final List<double> _offsets = [];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.numberOfDots, (index) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0,
        end: -5,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    }).toList();

    for (int i = 0; i < widget.numberOfDots; i++) {
      _offsets.add(0.0);
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(widget.numberOfDots, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              transform: Matrix4.translationValues(
                0,
                _animations[index].value,
                0,
              ),
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}

class MessageWidget extends StatelessWidget {
  final Messagemodel currentMessage;
  final Chatroompage widget;
  final double fontSize;
  const MessageWidget({
    Key? key,
    required this.currentMessage,
    required this.widget,
    required this.fontSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isMe = currentMessage.sender == widget.userModel.uid;
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    Color bubbleColor = isMe
        ? (isDark
              ? const Color(0xFF005C4B)
              : Theme.of(context).colorScheme.primary)
        : (isDark ? const Color(0xFF202C33) : Colors.grey[200]!);
    Color textColor = isMe
        ? Colors.white
        : (isDark ? Colors.white : Colors.black87);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && widget.chatRoom.isGroup!)
            FutureBuilder(
              future: FirebaseHelper.getUserModelById(currentMessage.sender!),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  UserModel senderUser = snapshot.data as UserModel;
                  return GestureDetector(
                    onTap: () {
                      Get.to(
                        () => ProfilePage(
                          targetUser: senderUser,
                          chatRoom: widget.chatRoom,
                          currentUser: widget.userModel,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8, bottom: 2),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundImage:
                            (senderUser.profilepic != null &&
                                senderUser.profilepic!.isNotEmpty)
                            ? NetworkImage(senderUser.profilepic!)
                            : null,
                        onBackgroundImageError:
                            (senderUser.profilepic != null &&
                                senderUser.profilepic!.isNotEmpty)
                            ? (_, __) {}
                            : null,
                        child:
                            (senderUser.profilepic == null ||
                                senderUser.profilepic!.isEmpty)
                            ? const Icon(Icons.person, size: 16)
                            : null,
                      ),
                    ),
                  );
                }
                return const SizedBox(width: 40);
              },
            ),
          Container(
            padding: const EdgeInsets.all(10),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMe && widget.chatRoom.isGroup!)
                  FutureBuilder(
                    future: FirebaseHelper.getUserModelById(
                      currentMessage.sender!,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        UserModel senderUser = snapshot.data as UserModel;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Text(
                            senderUser.fullname ?? "",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                if (currentMessage.type == "image" &&
                    currentMessage.imageUrl != null &&
                    currentMessage.imageUrl!.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      Get.to(
                        () => Scaffold(
                          backgroundColor: Colors.black,
                          appBar: AppBar(
                            backgroundColor: Colors.black,
                            iconTheme: const IconThemeData(color: Colors.white),
                            title: Text(
                              isMe ? "You" : widget.targetUser.fullname ?? "",
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          body: Center(
                            child: InteractiveViewer(
                              child: Hero(
                                tag: currentMessage.messageid!,
                                child: Image.network(
                                  currentMessage.imageUrl!,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return Container(
                                      width: 250,
                                      height: 200,
                                      color: Colors.grey[900],
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Hero(
                        tag: currentMessage.messageid!,
                        child: Image.network(
                          currentMessage.imageUrl!,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return SizedBox(
                              width: 220,
                              height: 180,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  child,
                                  const CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                  ),
                                ],
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image),
                        ),
                      ),
                    ),
                  )
                else if (currentMessage.type == "video" &&
                    currentMessage.imageUrl != null &&
                    currentMessage.imageUrl!.isNotEmpty)
                  VideoMessageWidget(url: currentMessage.imageUrl!, isMe: isMe)
                else if (currentMessage.type == "audio" &&
                    currentMessage.imageUrl != null &&
                    currentMessage.imageUrl!.isNotEmpty)
                  AudioMessageWidget(
                    url: currentMessage.imageUrl!,
                    isMe: isMe,
                    totalDuration: currentMessage.duration,
                  )
                else if (currentMessage.type == "document")
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.insert_drive_file, color: Colors.grey),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          currentMessage.text ?? "",
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  )
                else if (currentMessage.type == "location")
                  GestureDetector(
                    onTap: () async {
                      final Uri url = Uri.parse(currentMessage.imageUrl!);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on,
                          color: isMe ? Colors.white : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Pinned Location",
                          style: TextStyle(
                            color: textColor,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (currentMessage.type == "contact")
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.black12 : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person,
                              color: isMe ? Colors.white : Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              currentMessage.text ?? "",
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        TextButton(
                          onPressed: () async {
                            UserModel? contactUser =
                                await FirebaseHelper.getUserModelById(
                                  currentMessage.imageUrl!,
                                );
                            if (contactUser != null) {
                              Get.to(
                                () => ProfilePage(
                                  targetUser: contactUser,
                                  chatRoom: widget.chatRoom,
                                  currentUser: widget.userModel,
                                ),
                              );
                            }
                          },
                          child: Text(
                            "VIEW PROFILE",
                            style: TextStyle(
                              color: isMe
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.primary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    currentMessage.text ?? "",
                    style: TextStyle(fontSize: fontSize, color: textColor),
                  ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${currentMessage.createdon?.hour}:${currentMessage.createdon?.minute.toString().padLeft(2, '0')}",
                      style: TextStyle(
                        fontSize: 10,
                        color: isMe ? Colors.white70 : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 5),
                    if (isMe)
                      Icon(
                        Icons.done_all,
                        size: 14,
                        color: () {
                          if (widget.chatRoom.isGroup) {
                            // In a group, all participants (except sender) must have seen it
                            // Total participants minus the sender
                            int totalOthers =
                                widget.chatRoom.participants!.length - 1;
                            return (currentMessage.seenBy?.length ?? 0) >=
                                    totalOthers +
                                        1 // +1 because sender is in seenBy
                                ? Colors.blue
                                : Colors.white70;
                          } else {
                            return (currentMessage.seen ?? false)
                                ? Colors.blue
                                : Colors.white70;
                          }
                        }(),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
