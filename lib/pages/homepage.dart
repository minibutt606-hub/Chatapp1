import 'dart:async';
import 'dart:io';
import 'package:chatapp/models/chatroommodel.dart';
import 'package:chatapp/models/firebase_helper.dart';
import 'package:chatapp/models/usermodel.dart';
import 'package:chatapp/pages/home_tabs/calls_tab.dart';
import 'package:chatapp/pages/home_tabs/chats_tab.dart';
import 'package:chatapp/pages/home_tabs/communities_tab.dart';
import 'package:chatapp/pages/home_tabs/updates_tab.dart';
import 'package:chatapp/pages/settings_page.dart';
import 'package:chatapp/pages/settings_subpages/linked_devices_page.dart';
import 'package:chatapp/pages/new_group_page.dart';
import 'package:chatapp/pages/serachpage.dart';
import 'package:chatapp/utils/camera_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

class Homepage extends StatefulWidget {
  final UserModel userModel;
  final User firebaseUser;

  Homepage({Key? key, required this.userModel, required this.firebaseUser})
    : super(key: key);

  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> with WidgetsBindingObserver {
  StreamSubscription? deliverySubscription;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    setUserStatus(true);
    setupDeliveryListener();
    onUserLogin();
  }

  void onUserLogin() {
    if (ZegoUIKitPrebuiltCallInvitationService().isInit) return;
    ZegoUIKitPrebuiltCallInvitationService().init(
      appID: 195474778, // From CallPage
      appSign:
          '6c4514bc689bb1969eb9d91089a1b44cddceb31107df2361ff238bab5b8d8c17', // From CallPage
      userID: widget.userModel.uid!,
      userName: widget.userModel.fullname ?? "User",
      plugins: [ZegoUIKitSignalingPlugin()],
    );
  }

  @override
  void dispose() {
    deliverySubscription?.cancel();
    setUserStatus(false);
    WidgetsBinding.instance.removeObserver(this);
    ZegoUIKitPrebuiltCallInvitationService().uninit();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setUserStatus(true);
      // Re-initialise ZIM so this device is reachable for call invitations
      // (prevents error 107026: "user not registered or service exception")
      onUserLogin();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      setUserStatus(false);
    }
  }

  void setUserStatus(bool isOnline) {
    FirebaseFirestore.instance
        .collection("users")
        .doc(widget.userModel.uid)
        .update({"isOnline": isOnline});
  }

  void setupDeliveryListener() {
    deliverySubscription = FirebaseFirestore.instance
        .collection("chatrooms")
        .where("participants.${widget.userModel.uid}", isEqualTo: true)
        .snapshots()
        .listen((chatroomSnapshot) {
          for (var chatroomDoc in chatroomSnapshot.docs) {
            FirebaseFirestore.instance
                .collection("chatrooms")
                .doc(chatroomDoc.id)
                .collection("messages")
                .where("isDelivered", isEqualTo: false)
                .get()
                .then((messageSnapshot) {
                  for (var messageDoc in messageSnapshot.docs) {
                    String senderId = messageDoc.get("sender");
                    if (senderId != widget.userModel.uid) {
                      messageDoc.reference.update({"isDelivered": true});
                    }
                  }
                });
          }
        });
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return "ChatApp";
      case 1:
        return "Updates";
      case 2:
        return "Communities";
      case 3:
        return "Calls";
      default:
        return "ChatApp";
    }
  }

  List<Widget> _getAppBarActions() {
    switch (_currentIndex) {
      case 0: // Chats
        return [
          IconButton(
            onPressed: () async {
              File? photo = await CameraUtils.takePhoto();
              if (photo != null) {
                Get.snackbar(
                  "Photo Captured",
                  "Path: ${photo.path}",
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            icon: Icon(
              Icons.camera_alt_outlined,
              color: context.isDarkMode ? const Color(0xFFE9EDEF) : Colors.white,
              size: 26,
            ),
          ),
          _buildMoreMenu(), // This uses the main menu
        ];
      case 1: // Updates
        return [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: context.isDarkMode ? const Color(0xFFE9EDEF) : Colors.white),
            onSelected: (val) {
              if (val == "privacy") {
                Get.defaultDialog(
                  title: "Status privacy",
                  middleText: "Who can see my status updates",
                  textConfirm: "OK",
                  confirmTextColor: Colors.white,
                  onConfirm: () => Get.back(),
                );
              }
            },
            itemBuilder: (context) => [
              _buildPopupItem("privacy", Icons.lock_outline, "Status privacy"),
            ],
          ),
        ];
      case 2: // Communities
        return []; // No search, no more dots as requested
      case 3: // Calls
        return [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: context.isDarkMode ? const Color(0xFFE9EDEF) : Colors.white),
            color: context.isDarkMode ? const Color(0xFF233138) : Colors.white,
            surfaceTintColor: context.isDarkMode ? const Color(0xFF233138) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (val) async {
              if (val == "clear") {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text("Clear call log?", style: TextStyle(fontWeight: FontWeight.bold)),
                    content: const Text("All call history will be deleted."),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, elevation: 0),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text("Clear"),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  await FirebaseHelper.clearCallLogs(widget.userModel.uid!);
                  Get.snackbar("Cleared", "Call history deleted.",
                      snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green.shade100);
                }
              }
            },
            itemBuilder: (context) => [
              _buildPopupItem("clear", Icons.delete_outline, "Clear call log", color: Colors.red),
            ],
          ),
        ];
      default:
        return [_buildMoreMenu()];
    }
  }

  @override
  Widget build(BuildContext context) {
    Color primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: context.isDarkMode 
            ? const Color(0xFF202C33) 
            : Theme.of(context).colorScheme.primary,
        elevation: 0,
        centerTitle: false,
        title: Text(
          _getAppBarTitle(),
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: context.isDarkMode ? const Color(0xFFE9EDEF) : Colors.white,
          ),
        ),
        actions: _getAppBarActions(),
      ),
      body: _buildBody(),
      floatingActionButton: _currentIndex == 3
          ? null
          : FloatingActionButton(
              onPressed: () async {
                if (_currentIndex == 1) {
                  // Camera icon in Updates tab
                  File? photo = await CameraUtils.takePhoto();
                  if (photo != null) {
                    Get.snackbar(
                      "Status Captured",
                      "Ready to upload status",
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  }
                } else {
                  Get.to(() => Serachpage(userModel: widget.userModel));
                }
              },
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Icon(
                _currentIndex == 0
                    ? Icons.add_comment
                    : (_currentIndex == 1 ? Icons.camera_alt : Icons.groups),
                color: Colors.white,
              ),
            ),
      bottomNavigationBar: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("chatrooms")
            .where("participants.${widget.userModel.uid}", isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          int totalUnread = 0;
          if (snapshot.hasData) {
            for (var doc in snapshot.data!.docs) {
              var model = Chatroommodel.fromMap(
                doc.data(),
              );
              int count = (model.unreadCounts?[widget.userModel.uid] ?? 0)
                  .toInt();
              totalUnread += count;
            }
          }
          return BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              type: BottomNavigationBarType.fixed,
              backgroundColor: context.isDarkMode ? const Color(0xFF111B21) : Colors.white,
              selectedItemColor: context.isDarkMode ? const Color(0xFF00A884) : primaryColor,
              unselectedItemColor: context.isDarkMode ? Colors.grey[400] : Colors.grey[600],
              showUnselectedLabels: true,
            items: [
              BottomNavigationBarItem(
                icon: Badge(
                  label: Text(totalUnread.toString()),
                  isLabelVisible: totalUnread > 0,
                  child: const Icon(Icons.chat_outlined),
                ),
                activeIcon: Badge(
                  label: Text(totalUnread.toString()),
                  isLabelVisible: totalUnread > 0,
                  child: const Icon(Icons.chat),
                ),
                label: "Chats",
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.update),
                label: "Updates",
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.groups_outlined),
                label: "Communities",
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.call_outlined),
                label: "Calls",
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: IndexedStack(
        key: ValueKey<int>(_currentIndex),
        index: _currentIndex,
        children: [
          ChatsTab(userModel: widget.userModel),
          UpdatesTab(userModel: widget.userModel),
          CommunitiesTab(userModel: widget.userModel),
          CallsTab(userModel: widget.userModel),
        ],
      ),
    );
  }

  Widget _buildMoreMenu() {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: context.isDarkMode ? const Color(0xFFE9EDEF) : Colors.white),
      offset: const Offset(0, 50),
      color: context.isDarkMode ? const Color(0xFF233138) : Colors.white,
      surfaceTintColor: context.isDarkMode ? const Color(0xFF233138) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        _buildPopupItem("group", Icons.group_add_outlined, "New group"),
        _buildPopupItem("device", Icons.devices_outlined, "Linked devices"),
        _buildPopupItem("settings", Icons.settings_outlined, "Settings"),
      ],
      onSelected: (val) {
        switch (val) {
          case "group":
            Get.to(() => NewGroupPage(userModel: widget.userModel));
            break;
          case "device":
            Get.to(() => const LinkedDevicesPage());
            break;
          case "settings":
            Get.to(() => SettingsPage(userModel: widget.userModel));
            break;
        }
      },
    );
  }

  PopupMenuItem<String> _buildPopupItem(
    String value,
    IconData icon,
    String label, {
    Color? color,
  }) {
    final Color contentColor = color ?? (context.isDarkMode ? const Color(0xFFE9EDEF) : Colors.black87);
    return PopupMenuItem<String>(
      value: value,
      height: 40,
      child: Row(
        children: [
          Icon(icon, size: 18, color: contentColor),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(fontSize: 14, color: contentColor),
          ),
        ],
      ),
    );
  }
}
