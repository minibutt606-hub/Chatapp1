import 'dart:io';
import 'package:chatapp/models/firebase_helper.dart';
import 'package:chatapp/models/status_model.dart';
import 'package:chatapp/models/usermodel.dart';
import 'package:chatapp/pages/status_view_page.dart';
import 'package:chatapp/utils/camera_utils.dart';
import 'package:chatapp/pages/home_tabs/updates_tab.dart';
import 'package:chatapp/pages/text_status_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class UpdatesTab extends StatelessWidget {
  final UserModel userModel;

  const UpdatesTab({Key? key, required this.userModel}) : super(key: key);

  Future<void> _pickAndUploadStatus(BuildContext context, bool fromGallery, {bool isVideo = false}) async {
    File? file;
    if (isVideo) {
      file = fromGallery ? await CameraUtils.pickVideoFromGallery() : await CameraUtils.takeVideo();
    } else {
      file = fromGallery ? await CameraUtils.pickImageFromGallery() : await CameraUtils.takePhoto();
    }

    if (file != null) {
      Get.snackbar("Status", "Uploading status...", snackPosition: SnackPosition.BOTTOM);
      
      await FirebaseHelper.uploadStatus(userModel, file, type: isVideo ? "video" : "image");
      
      Get.snackbar("Success", "Status uploaded!", backgroundColor: Colors.green, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _showMyStatusOptions(BuildContext context, DocumentSnapshot myDoc) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.remove_red_eye_outlined),
                title: const Text("View my status"),
                onTap: () async {
                  Navigator.pop(context);
                  // Fetch and show
                  QuerySnapshot itemsSnapshot = await FirebaseFirestore.instance
                      .collection("statuses")
                      .doc(userModel.uid)
                      .collection("items")
                      .orderBy("timestamp", descending: false)
                      .get();
                  
                  List<StatusModel> statuses = itemsSnapshot.docs.map((doc) {
                    return StatusModel.fromMap(doc.data() as Map<String, dynamic>);
                  }).toList();

                  if (statuses.isNotEmpty) {
                    Get.to(() => StatusViewPage(
                      statuses: statuses,
                      userName: "My status",
                      currentUserUid: userModel.uid,
                    ));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: const Text("Add new status"),
                onTap: () {
                  Navigator.pop(context);
                  _showStatusOptions(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showStatusOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Text("Create status", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.teal, child: Icon(Icons.edit, color: Colors.white)),
                title: const Text("Text"),
                onTap: () {
                  Navigator.pop(context);
                  Get.to(() => TextStatusPage(currentUser: userModel));
                },
              ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.purple, child: Icon(Icons.camera_alt, color: Colors.white)),
                title: const Text("Camera (Photo/Video)"),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadStatus(context, false, isVideo: false); // In real app, camera can take both, here we default to photo
                },
              ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.photo_library, color: Colors.white)),
                title: const Text("Photo from Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadStatus(context, true, isVideo: false);
                },
              ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.red, child: Icon(Icons.videocam, color: Colors.white)),
                title: const Text("Video from Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadStatus(context, true, isVideo: true);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showStatusPrivacySettings(BuildContext context) {
    if (userModel.privacySettings == null) {
      userModel.privacySettings = {};
    }
    String currentStatusPrivacy = userModel.privacySettings!["status"] ?? "My contacts";
    String initialValue = currentStatusPrivacy;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Text(
                      "Status privacy",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: Text(
                      "Who can see my status updates",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ...["My contacts", "My contacts except...", "Only share with..."].map((option) {
                    return RadioListTile<String>(
                      title: Text(option),
                      value: option,
                      groupValue: currentStatusPrivacy,
                      activeColor: Theme.of(context).colorScheme.primary,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => currentStatusPrivacy = val);
                          // Usually in WhatsApp the except/share options open contact pickers.
                          // Here we'll just save it directly for now.
                        }
                      },
                    );
                  }).toList(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: const Text(
                      "Changes to your privacy settings won't affect status updates that you've sent already.",
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
    ).then((_) {
      // Save on close if changed
      if (currentStatusPrivacy != initialValue) {
        if (userModel.privacySettings == null) {
          userModel.privacySettings = {};
        }
        userModel.privacySettings!["status"] = currentStatusPrivacy;
        FirebaseFirestore.instance.collection("users").doc(userModel.uid).update({
          "privacySettings.status": currentStatusPrivacy,
        });
        Get.snackbar(
          "Settings Updated",
          "Status privacy updated to $currentStatusPrivacy",
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color primaryColor = isDark ? const Color(0xFF00A884) : Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "textStatusFab",
            mini: true,
            backgroundColor: isDark ? const Color(0xFF202C33) : Colors.grey.shade200,
            foregroundColor: isDark ? const Color(0xFF00A884) : Colors.teal.shade800,
            onPressed: () => Get.to(() => TextStatusPage(currentUser: userModel)),
            child: const Icon(Icons.edit),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "cameraStatusFab",
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            onPressed: () => _showStatusOptions(context),
            child: const Icon(Icons.camera_alt),
          ),
        ],
      ),
      body: ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Status",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
            ],
          ),
        ),
        SizedBox(
          height: 180,
          child: StreamBuilder(
            // First, get all chatrooms where current user is a participant
            stream: FirebaseFirestore.instance
                .collection("chatrooms")
                .where("participants.${userModel.uid}", isEqualTo: true)
                .snapshots(),
            builder: (context, chatroomSnapshot) {
              Set<String> contactUids = {userModel.uid!}; // Always include self
              if (chatroomSnapshot.hasData) {
                for (var doc in chatroomSnapshot.data!.docs) {
                  Map<String, dynamic> participants = doc.get("participants");
                  participants.keys.forEach((uid) {
                    contactUids.add(uid);
                  });
                }
              }

              return StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection("statuses")
                    .where("lastUpdated", isGreaterThan: DateTime.now().subtract(const Duration(hours: 24)))
                    .orderBy("lastUpdated", descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  List<DocumentSnapshot> allStatusDocs = snapshot.data?.docs ?? [];
                  
                  // Filter status docs to only show contacts
                  List<DocumentSnapshot> statusDocs = allStatusDocs.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    return contactUids.contains(data['uid']);
                  }).toList();
                  
                  if (snapshot.connectionState == ConnectionState.waiting && statusDocs.isEmpty) {
                     return ListView(
                       scrollDirection: Axis.horizontal,
                       padding: const EdgeInsets.symmetric(horizontal: 10),
                       children: [
                         GestureDetector(
                           onTap: () => _showStatusOptions(context),
                           child: _buildStatusCard(context, "Add status", userModel.profilepic, true),
                         ),
                         const Center(child: Padding(
                           padding: EdgeInsets.all(20.0),
                           child: CircularProgressIndicator(strokeWidth: 2),
                         )),
                       ],
                     );
                  }

                  // Find current user's status in the filtered list
                  DocumentSnapshot? myStatusDoc;
                  List<DocumentSnapshot> otherStatusDocs = [];
                  
                  for (var doc in statusDocs) {
                    var data = doc.data() as Map<String, dynamic>;
                    if (data['uid'] == userModel.uid) {
                      myStatusDoc = doc;
                    } else {
                      otherStatusDocs.add(doc);
                    }
                  }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: otherStatusDocs.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // Current User's Card (Always first)
                    String name = "My status";
                    String? displayImg = myStatusDoc != null ? 
                      (myStatusDoc.data() as Map<String, dynamic>)["lastStatusImage"] ?? userModel.profilepic : 
                      userModel.profilepic;
                    
                    return GestureDetector(
                      onTap: () async {
                        if (myStatusDoc != null) {
                          // Show options: View or Add
                          _showMyStatusOptions(context, myStatusDoc!);
                        } else {
                          // Only Add
                          _showStatusOptions(context);
                        }
                      },
                      child: _buildStatusCard(context, name, displayImg, true),
                    );
                  }
                  
                  // Other Users' Cards
                  var data = otherStatusDocs[index - 1].data() as Map<String, dynamic>;
                  String name = data["userName"] ?? "Unknown";
                  
                  return GestureDetector(
                    onTap: () async {
                      // Fetch status items for this user (Oldest first for story flow)
                      QuerySnapshot itemsSnapshot = await FirebaseFirestore.instance
                          .collection("statuses")
                          .doc(data['uid'])
                          .collection("items")
                          .orderBy("timestamp", descending: false)
                          .get();
                      
                      List<StatusModel> statuses = itemsSnapshot.docs.map((doc) {
                        return StatusModel.fromMap(doc.data() as Map<String, dynamic>);
                      }).toList();

                      if (statuses.isNotEmpty) {
                        Get.to(() => StatusViewPage(
                          statuses: statuses,
                          userName: name,
                          currentUserUid: userModel.uid,
                        ));
                      }
                    },
                    child: _buildStatusCard(
                        context, name, data["lastStatusImage"] ?? data["profilePic"], false),
                  );
                },
              );
            },
          );
        },
      ),
    ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Channels",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
              Text("Explore >",
                  style: TextStyle(
                      color: primaryColor, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        StreamBuilder(
          stream: FirebaseFirestore.instance.collection("channels").snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              return Column(
                children: snapshot.data!.docs.map((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  data['id'] = doc.id;
                  return _buildChannelTile(
                      context, data["title"], data["subtitle"], data["time"], data);
                }).toList(),
              );
            }
            
            // If no channels exist, show a button to create them
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [
                  Text("No real channels found in database.",
                      style: TextStyle(color: isDark ? Colors.white70 : Colors.grey, fontSize: 13)),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await FirebaseHelper.createSampleChannels();
                    },
                    icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                    label: const Text("Create Sample Channels", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                  Divider(height: 40, color: isDark ? Colors.white10 : Colors.grey[300]),
                  // Still show the UI preview
                  _buildChannelTile(context, "Aaj ki Hadith (Preview)", "Photo", "9:00 AM", {}),
                ],
              ),
            );
          },
        ),
      ],
    ),
    );
  }

  Widget _buildStatusCard(
      BuildContext context, String name, String? img, bool isAdd) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color primaryColor = isDark ? const Color(0xFF00A884) : Theme.of(context).colorScheme.primary;
    return Container(
      width: 110,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF202C33) : Colors.grey[100],
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isAdd ? (isDark ? Colors.white10 : Colors.grey[300]!) : primaryColor, width: 2),
      ),
      child: Stack(
        children: [
          if (img != null && img.isNotEmpty)
            ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.network(img,
                    fit: BoxFit.cover,
                    height: double.infinity,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: isDark ? const Color(0xFF111B21) : Colors.grey[300],
                      child: Icon(Icons.person, color: isDark ? Colors.white12 : Colors.white, size: 40),
                    ),
                ))
          else if (isAdd)
            Container(color: isDark ? const Color(0xFF111B21) : Colors.grey[200]),
          // Dark overlay for text readability
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            left: 10,
            right: 10,
            child: Text(name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelTile(BuildContext context, String title, String sub, String time, Map<String, dynamic> channelData) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color primaryColor = isDark ? const Color(0xFF00A884) : Theme.of(context).colorScheme.primary;
    
    // Check if following
    List followers = channelData['followers'] ?? [];
    bool isFollowing = followers.contains(userModel.uid);

    return ListTile(
      leading: CircleAvatar(
          backgroundColor: isDark ? const Color(0xFF202C33) : Colors.grey[200],
          child: Icon(Icons.campaign_outlined, color: isDark ? Colors.white70 : Colors.black54)),
      title: Text(title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black)),
      subtitle: Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: isDark ? Colors.white60 : Colors.black54)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(time, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey)),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {
              if (channelData['id'] != null) {
                FirebaseHelper.toggleFollowChannel(channelData['id'], userModel.uid!, isFollowing);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isFollowing ? Colors.transparent : primaryColor.withOpacity(0.1),
                border: Border.all(color: primaryColor),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                isFollowing ? "Following" : "Follow",
                style: TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
