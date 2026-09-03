import 'package:chatapp/models/chatroommodel.dart';
import 'package:chatapp/models/messagemodel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';


class ChatExportService {
  static Future<void> exportChat({
    required BuildContext context,
    required Chatroommodel chatRoom,
    required String currentUserId,
    required String targetUserName,
  }) async {
    // Show loading
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      final snap = await FirebaseFirestore.instance
          .collection("chatrooms")
          .doc(chatRoom.chatroomid)
          .collection("messages")
          .orderBy("createdon", descending: false)
          .get();

      final messages =
          snap.docs.map((d) => Messagemodel.fromMap(d.data())).toList();

      final buffer = StringBuffer();
      buffer.writeln("═══════════════════════════════");
      buffer.writeln("Chat Export with $targetUserName");
      buffer.writeln("Exported: ${_fmt(DateTime.now())}");
      buffer.writeln("═══════════════════════════════\n");

      for (final msg in messages) {
        final sender =
            msg.sender == currentUserId ? "You" : targetUserName;
        final time = _fmt(msg.createdon);
        final content = _contentText(msg);
        buffer.writeln("[$time] $sender:");
        buffer.writeln("  $content");
        buffer.writeln();
      }

      Get.back(); // close dialog
      await SharePlus.instance.share(
        ShareParams(
          text: buffer.toString(),
          subject: "Chat with $targetUserName",
        ),
      );
    } catch (e) {
      Get.back();
      Get.snackbar("Error", "Could not export chat: $e",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100);
    }
  }

  static String _fmt(DateTime? dt) {
    if (dt == null) return "";
    return "${dt.day}/${dt.month}/${dt.year} "
        "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }

  static String _contentText(Messagemodel msg) {
    switch (msg.type) {
      case "image":
        return "📷 Photo: ${msg.imageUrl ?? ''}";
      case "video":
        return "🎥 Video: ${msg.imageUrl ?? ''}";
      case "audio":
        return "🎤 Voice message: ${msg.imageUrl ?? ''}";
      case "document":
        return "📄 Document: ${msg.text ?? ''}";
      case "location":
        return "📍 Location: ${msg.imageUrl ?? ''}";
      case "contact":
        return "👤 Contact: ${msg.text ?? ''}";
      default:
        return msg.text ?? "";
    }
  }
}
