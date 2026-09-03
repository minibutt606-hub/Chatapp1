import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BlockUserService {
  static Future<void> blockUser({
    required String currentUserId,
    required String targetUserId,
    required String targetUserName,
    required BuildContext context,
  }) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Block contact?",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          "Blocked contacts will no longer be able to call you or send you messages.\n\nBlock $targetUserName?",
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Cancel",
                style: TextStyle(
                    color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Block"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await FirebaseFirestore.instance
        .collection("users")
        .doc(currentUserId)
        .update({
      "blockedUsers.$targetUserId": true,
    });

    Get.snackbar(
      "$targetUserName blocked",
      "You can unblock them from contact info.",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.black87,
    );
  }

  static Future<void> unblockUser({
    required String currentUserId,
    required String targetUserId,
    required String targetUserName,
  }) async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(currentUserId)
        .update({
      "blockedUsers.$targetUserId": FieldValue.delete(),
    });

    Get.snackbar(
      "$targetUserName unblocked",
      "They can now send you messages.",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade100,
    );
  }

  static Stream<bool> isBlockedStream(
      String currentUserId, String targetUserId) {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(currentUserId)
        .snapshots()
        .map((snap) {
      final blocked = (snap.data()?["blockedUsers"] as Map?) ?? {};
      return blocked[targetUserId] == true;
    });
  }
}
