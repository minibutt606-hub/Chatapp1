import 'package:chatapp/models/chatroommodel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DisappearingMessagesPage extends StatefulWidget {
  final Chatroommodel chatRoom;

  const DisappearingMessagesPage({Key? key, required this.chatRoom})
      : super(key: key);

  @override
  State<DisappearingMessagesPage> createState() =>
      _DisappearingMessagesPageState();
}

class _DisappearingMessagesPageState extends State<DisappearingMessagesPage> {
  int? _selected; // seconds, null = off
  bool _saving = false;

  final _options = const [
    _DOption(label: "Off", seconds: 0, icon: Icons.timer_off_outlined),
    _DOption(label: "24 hours", seconds: 86400, icon: Icons.timer_outlined),
    _DOption(label: "7 days", seconds: 604800, icon: Icons.calendar_today),
    _DOption(label: "90 days", seconds: 7776000, icon: Icons.date_range),
  ];

  @override
  void initState() {
    super.initState();
    _selected = 0; // default off
    _load();
  }

  Future<void> _load() async {
    final doc = await FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(widget.chatRoom.chatroomid)
        .get();
    final v = doc.data()?["disappearingMessages"] as int? ?? 0;
    setState(() => _selected = v);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(widget.chatRoom.chatroomid)
        .update({"disappearingMessages": _selected ?? 0});
    setState(() => _saving = false);
    Get.back();
    final label = _options.firstWhere((o) => o.seconds == _selected).label;
    Get.snackbar("Disappearing messages",
        _selected == 0 ? "Turned off" : "Set to $label",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text("Disappearing messages",
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primary.withValues(alpha: 0.2))),
              child: Row(
                children: [
                  Icon(Icons.timer_outlined, color: primary),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "When turned on, new messages will automatically disappear after the selected time.",
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
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
                        value: opt.seconds,
                        groupValue: _selected,
                        activeColor: primary,
                        secondary: Icon(opt.icon, color: Colors.grey.shade600),
                        title: Text(opt.label,
                            style: const TextStyle(fontSize: 15)),
                        onChanged: (v) => setState(() => _selected = v),
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
                onPressed: _saving ? null : _save,
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
                    : const Text("Save",
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

class _DOption {
  final String label;
  final int seconds;
  final IconData icon;
  const _DOption(
      {required this.label, required this.seconds, required this.icon});
}
