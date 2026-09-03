import 'package:chatapp/models/usermodel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ReportUserPage extends StatefulWidget {
  final UserModel targetUser;
  final UserModel currentUser;

  const ReportUserPage({
    Key? key,
    required this.targetUser,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<ReportUserPage> createState() => _ReportUserPageState();
}

class _ReportUserPageState extends State<ReportUserPage> {
  String? _selected;
  final _detailsCtrl = TextEditingController();
  bool _block = true;
  bool _submitting = false;

  final List<_ReportCategory> _categories = const [
    _ReportCategory(
        id: "spam",
        icon: Icons.mark_email_unread_outlined,
        title: "Spam",
        subtitle: "Sending unwanted messages or links"),
    _ReportCategory(
        id: "harassment",
        icon: Icons.sentiment_very_dissatisfied_outlined,
        title: "Harassment or bullying",
        subtitle: "Threatening, abusive or harmful content"),
    _ReportCategory(
        id: "fake",
        icon: Icons.person_off_outlined,
        title: "Fake account",
        subtitle: "Pretending to be someone else"),
    _ReportCategory(
        id: "explicit",
        icon: Icons.no_adult_content,
        title: "Inappropriate content",
        subtitle: "Sexual, violent or disturbing material"),
    _ReportCategory(
        id: "other",
        icon: Icons.help_outline,
        title: "Other",
        subtitle: "Something else that violates our policies"),
  ];

  Future<void> _submit() async {
    if (_selected == null) {
      Get.snackbar("Select reason", "Please choose a reason to report",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100);
      return;
    }
    setState(() => _submitting = true);
    await FirebaseFirestore.instance.collection("reports").add({
      "reporterId": widget.currentUser.uid,
      "reporterName": widget.currentUser.fullname,
      "reportedId": widget.targetUser.uid,
      "reportedName": widget.targetUser.fullname,
      "category": _selected,
      "details": _detailsCtrl.text.trim(),
      "block": _block,
      "timestamp": DateTime.now(),
    });

    if (_block) {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.currentUser.uid)
          .update({
        "blockedUsers.${widget.targetUser.uid}": true,
      });
    }

    setState(() => _submitting = false);
    Get.back();
    Get.snackbar(
      "Report submitted",
      "Thank you. We'll review this report.",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.black87,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _detailsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: Text(
          "Report ${widget.targetUser.fullname ?? 'User'}",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: (widget.targetUser.profilepic?.isNotEmpty ?? false)
                        ? NetworkImage(widget.targetUser.profilepic!)
                        : null,
                    onBackgroundImageError: (widget.targetUser.profilepic?.isNotEmpty ?? false) ? (_, __) {} : null,
                    child: (widget.targetUser.profilepic?.isEmpty ?? true)
                        ? const Icon(Icons.person, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.targetUser.fullname ?? "User",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        "This report is anonymous",
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const Text("  Why are you reporting this account?",
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.black54)),
            const SizedBox(height: 8),

            // Categories
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: _categories.map((cat) {
                  final selected = _selected == cat.id;
                  return Column(
                    children: [
                      ListTile(
                        leading: Icon(cat.icon,
                            color: selected ? primary : Colors.grey.shade600),
                        title: Text(cat.title,
                            style: TextStyle(
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.normal)),
                        subtitle: Text(cat.subtitle,
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500)),
                        trailing: selected
                            ? Icon(Icons.check_circle,
                                color: primary)
                            : const Icon(Icons.radio_button_unchecked,
                                color: Colors.grey),
                        onTap: () => setState(() => _selected = cat.id),
                      ),
                      if (cat != _categories.last)
                        Divider(
                            height: 1,
                            indent: 56,
                            color: Colors.grey.shade200),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Details field
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _detailsCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Additional details (optional)...",
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Block toggle
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                value: _block,
                activeColor: primary,
                onChanged: (v) => setState(() => _block = v),
                title: Text(
                  "Block ${widget.targetUser.fullname ?? 'this user'}",
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  "They won't be able to message or call you",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text("Submit Report",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                "Reports are reviewed by our team.\nThank you for helping keep our community safe.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportCategory {
  final String id;
  final IconData icon;
  final String title;
  final String subtitle;
  const _ReportCategory(
      {required this.id,
      required this.icon,
      required this.title,
      required this.subtitle});
}
