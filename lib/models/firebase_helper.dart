import 'dart:io';
import 'package:chatapp/models/chatroommodel.dart';
import 'package:chatapp/models/status_model.dart';
import 'package:chatapp/models/usermodel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:chatapp/services/cloudinary_service.dart';

class FirebaseHelper {
  static Future<UserModel?> getUserModelById(String uid) async {
    UserModel? userModel;

    DocumentSnapshot docSnap =
        await FirebaseFirestore.instance.collection("users").doc(uid).get();

    if (docSnap.data() != null) {
      userModel = UserModel.fromMap(docSnap.data() as Map<String, dynamic>);
    }

    return userModel;
  }

  static Future<void> uploadStatus(UserModel user, File file, {String type = "image"}) async {
    String statusId = const Uuid().v4();
    
    // Upload file to Cloudinary
    String? fileUrl = await CloudinaryService.uploadFile(file.path);
    if (fileUrl == null) return;

    StatusModel newStatus = StatusModel(
      statusId: statusId,
      uid: user.uid,
      userName: user.fullname,
      profilePic: user.profilepic,
      imageUrl: fileUrl,
      timestamp: DateTime.now(),
      viewers: [],
      type: type,
    );

    // Update or Create user's status summary document
    await FirebaseFirestore.instance.collection("statuses").doc(user.uid).set({
      "uid": user.uid,
      "userName": user.fullname,
      "profilePic": user.profilepic,
      "lastStatusImage": type == "image" ? fileUrl : "", // Video thumbnail not generated for simplicity, could show placeholder

      "lastUpdated": DateTime.now(),
    }, SetOptions(merge: true));

    // Add individual status item
    await FirebaseFirestore.instance
        .collection("statuses")
        .doc(user.uid)
        .collection("items")
        .doc(statusId)
        .set(newStatus.toMap());
  }

  static Future<void> toggleFollowChannel(String channelId, String userId, bool isFollowing) async {
    if (isFollowing) {
      await FirebaseFirestore.instance.collection("channels").doc(channelId).update({
        "followers": FieldValue.arrayRemove([userId])
      });
    } else {
      await FirebaseFirestore.instance.collection("channels").doc(channelId).update({
        "followers": FieldValue.arrayUnion([userId])
      });
    }
  }

  static Future<void> createSampleChannels() async {
    List<Map<String, dynamic>> samples = [
      {
        "title": "Aaj ki Hadith",
        "subtitle": "Daily spiritual updates",
        "time": "9:00 AM",
        "followers": []
      },
      {
        "title": "Tech News",
        "subtitle": "Latest gadgets and software",
        "time": "Yesterday",
        "followers": []
      },
      {
        "title": "Cricket Live",
        "subtitle": "Ball by ball updates",
        "time": "12:30 PM",
        "followers": []
      }
    ];

    for (var channel in samples) {
      await FirebaseFirestore.instance.collection("channels").add(channel);
    }
  }

  static Future<void> createSampleCommunities() async {
    List<Map<String, dynamic>> samples = [
      {
        "name": "Tech Enthusiasts",
        "description": "Discussing the latest in tech",
        "icon": "computer"
      },
      {
        "name": "Durood Pak Group",
        "description": "Spiritual reminders",
        "icon": "church"
      },
      {
        "name": "Local Announcements",
        "description": "News from your area",
        "icon": "campaign"
      }
    ];

    for (var community in samples) {
      await FirebaseFirestore.instance.collection("communities").add(community);
    }
  }

  static Future<void> clearCallLogs(String userId) async {
    var logs = await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("calls")
        .get();
    
    for (var doc in logs.docs) {
      await doc.reference.delete();
    }
  }

  static Future<void> saveCallLog({
    required String senderId,
    required String receiverId,
    required String receiverName,
    required bool isVideo,
  }) async {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    final timeString = "$h:$m";

    // Save for sender
    await FirebaseFirestore.instance
        .collection("users")
        .doc(senderId)
        .collection("calls")
        .add({
      "name": receiverName,
      "receiverId": receiverId,   // ← stored so we can navigate
      "time": now,
      "time_string": timeString,
      "isReceived": false,
      "isMissed": false,
      "isVideo": isVideo,
    });
  }

  static Future<Chatroommodel?> getChatroomModel(UserModel currentUser, UserModel targetUser) async {
    // Check if both UIDs are available
    if (currentUser.uid == null || targetUser.uid == null) return null;

    // First try to find an existing chatroom using the generic query
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection("chatrooms")
        .where("participants.${currentUser.uid}", isEqualTo: true)
        .where("participants.${targetUser.uid}", isEqualTo: true)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return Chatroommodel.fromMap(snapshot.docs[0].data() as Map<String, dynamic>);
    } else {
      // Create a deterministic ID to prevent duplicates if multiple clicks happen
      List<String> participantIds = [currentUser.uid!, targetUser.uid!];
      participantIds.sort(); // Sort to ensure the same ID regardless of who initiates
      String chatroomId = participantIds.join("_");

      // Check one more time by ID directly (in case it was just created or previously deleted)
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection("chatrooms").doc(chatroomId).get();
      
      if (doc.exists) {
        Chatroommodel existingChatroom = Chatroommodel.fromMap(doc.data() as Map<String, dynamic>);
        
        // If it exists but maybe participation was set to false (deleted), restore it
        if (existingChatroom.participants?[currentUser.uid] != true || 
            existingChatroom.participants?[targetUser.uid] != true) {
          
          existingChatroom.participants![currentUser.uid!] = true;
          existingChatroom.participants![targetUser.uid!] = true;
          
          await FirebaseFirestore.instance
              .collection("chatrooms")
              .doc(chatroomId)
              .update({"participants": existingChatroom.participants});
        }
        
        return existingChatroom;
      }

      Chatroommodel newChatroom = Chatroommodel(
        chatroomid: chatroomId,
        lastMessage: "",
        participants: {
          currentUser.uid.toString(): true,
          targetUser.uid.toString(): true,
        },
      );
      
      await FirebaseFirestore.instance
          .collection("chatrooms")
          .doc(newChatroom.chatroomid)
          .set(newChatroom.toMap());
          
      return newChatroom;
    }
  }
}
