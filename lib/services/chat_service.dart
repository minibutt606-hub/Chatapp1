import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:chatapp/models/messagemodel.dart';
import 'package:chatapp/main.dart';

import 'package:chatapp/services/cloudinary_service.dart';
import 'package:cloudinary_public/cloudinary_public.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> sendMessage({
    required String chatroomId,
    required String senderId,
    required String text,
    String type = "text",
    String? imageUrl,
    int? duration,
    String? senderName,
  }) async {
    String messageId = uuid.v1();
    
    Messagemodel newMessage = Messagemodel(
      messageid: messageId,
      sender: senderId,
      createdon: DateTime.now(),
      text: text,
      type: type,
      imageUrl: imageUrl,
      seen: false,
      isDelivered: false,
      duration: duration,
      seenBy: [senderId], // Sender has obviously seen their own message
    );

    await _firestore
        .collection("chatrooms")
        .doc(chatroomId)
        .collection("messages")
        .doc(messageId)
        .set(newMessage.toMap());

    await _firestore.collection("chatrooms").doc(chatroomId).update({
      "lastMessage": type == "text"
          ? text
          : (type == "image"
              ? "📷 Photo"
              : (type == "audio"
                  ? "🎤 Voice message"
                  : (type == "location" 
                      ? "📍 Location" 
                      : (type == "video" ? "🎥 Video" : "👤 Contact")))),
      "lastMessageTime": DateTime.now(),
      "lastMessageSenderName": senderName ?? "",
      // Auto-increment unread count for other participants
    });

    // Fetch chatroom to find other participants
    DocumentSnapshot roomDoc = await _firestore.collection("chatrooms").doc(chatroomId).get();
    Map<String, dynamic> participants = roomDoc.get("participants");
    participants.forEach((uid, isParticipant) async {
      if (uid != senderId) {
        await _firestore.collection("chatrooms").doc(chatroomId).update({
          "unreadCounts.$uid": FieldValue.increment(1),
        });
      }
    });
  }

  static Future<String> uploadFile(File file, String path, {String type = "image"}) async {
    CloudinaryResourceType resourceType = CloudinaryResourceType.Image;
    if (type == "video") resourceType = CloudinaryResourceType.Video;
    if (type == "audio") resourceType = CloudinaryResourceType.Video; // Cloudinary treats audio as video resource type
    if (type == "document") resourceType = CloudinaryResourceType.Auto;

    String? url = await CloudinaryService.uploadFile(file.path, resourceType: resourceType);
    return url ?? "";
  }

  static Future<void> updateTypingStatus(String chatroomId, String userId, String status) async {
    await _firestore.collection("users").doc(userId).update({
      "typingStatus": status,
    });
  }

  static Future<void> clearChat(String chatroomId) async {
    var messages = await _firestore
        .collection("chatrooms")
        .doc(chatroomId)
        .collection("messages")
        .get();
    for (var doc in messages.docs) {
      await doc.reference.delete();
    }
    await _firestore.collection("chatrooms").doc(chatroomId).update({
      "lastMessage": "",
    });
  }
  static Future<void> markAllAsRead(String userId) async {
    var chatrooms = await _firestore
        .collection("chatrooms")
        .where("participants.$userId", isEqualTo: true)
        .get();

    for (var doc in chatrooms.docs) {
      // Mark all incoming messages in this chat as seen
      var messages = await doc.reference
          .collection("messages")
          .where("seen", isEqualTo: false)
          .get();

      for (var msgDoc in messages.docs) {
        if (msgDoc["sender"] != userId) {
          await msgDoc.reference.update({
            "seen": true,
            "seenBy": FieldValue.arrayUnion([userId])
          });
        }
      }

      // Reset unread count in room doc
      await doc.reference.update({"unreadCounts.$userId": 0});
    }
  }
}
