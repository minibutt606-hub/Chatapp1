import 'package:chatapp/models/chatroommodel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MuteNotificationsPage extends StatefulWidget {
  final Chatroommodel chatRoom;
  final String currentUserId;

  const MuteNotificationsPage({
    Key? key,
    required this.chatRoom,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<MuteNotificationsPage> createState() => _MuteNotificationsPageState();
}

class _MuteNotificationsPageState extends State<MuteNotificationsPage> {
  String? _current;
  bool _saving = false;

  final _options = const [
    _MuteOption(label: "8 hours", hours: 8),
    _MuteOption(label: "1 week", hours: 168),
    _MuteOption(label: "Always", hours: -1),
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    final doc = await FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(widget.chatRoom.chatroomid)
        .get();
    final muted = doc.data()?["muted"] as Map? ?? {};
    final until = muted[widget.currentUserId];
    if (until != null) {
      setState(() => _current = until == -1 ? "always" : (until as int).toString());
    }
  }

  Future<void> _save(int hours) async {
    setState(() => _saving = true);
    await FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(widget.chatRoom.chatroomid)
        .set({
      "muted": {widget.currentUserId: hours},
    }, SetOptions(merge: true));
    setState(() => _saving = false);
    Get.back();
    Get.snackbar(
      "Notifications muted",
      hours == -1 ? "Muted always" : "Muted for ${_options.firstWhere((o) => o.hours == hours).label}",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade100,
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text("Mute notifications",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: _options.map((opt) {
                  return Column(
                    children: [
                      RadioListTile<int>(
                        value: opt.hours,
                        groupValue: _current == "always"
                            ? -1
                            : int.tryParse(_current ?? ""),
                        activeColor: primary,
                        title: Text(opt.label,
                            style: const TextStyle(fontSize: 15)),
                        onChanged: (v) => setState(() =>
                            _current = v == -1 ? "always" : v.toString()),
                      ),
                      if (opt != _options.last)
                        Divider(
                            height: 1,
                            indent: 56,
                            color: Colors.grey.shade200),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving || _current == null
                    ? null
                    : () => _save(
                        _current == "always" ? -1 : int.parse(_current!)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text("OK",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MuteOption {
  final String label;
  final int hours;
  const _MuteOption({required this.label, required this.hours});
}
