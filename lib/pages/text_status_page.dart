import 'package:chatapp/models/status_model.dart';
import 'package:chatapp/models/usermodel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

class TextStatusPage extends StatefulWidget {
  final UserModel currentUser;

  const TextStatusPage({Key? key, required this.currentUser}) : super(key: key);

  @override
  State<TextStatusPage> createState() => _TextStatusPageState();
}

class _TextStatusPageState extends State<TextStatusPage> {
  final TextEditingController _textController = TextEditingController();
  final List<Color> _colors = [
    Colors.deepPurpleAccent,
    Colors.teal,
    Colors.pinkAccent,
    Colors.orange,
    Colors.indigo,
    Colors.brown,
    Colors.blueGrey,
    Colors.black87,
  ];
  int _colorIndex = 0;
  bool _isUploading = false;

  void _changeColor() {
    setState(() {
      _colorIndex = (_colorIndex + 1) % _colors.length;
    });
  }

  Future<void> _uploadStatus() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isUploading = true);

    String statusId = const Uuid().v1();
    String bgColorHex = _colors[_colorIndex].toARGB32().toRadixString(16);

    StatusModel newStatus = StatusModel(
      statusId: statusId,
      uid: widget.currentUser.uid,
      userName: widget.currentUser.fullname,
      profilePic: widget.currentUser.profilepic ?? "",
      imageUrl: "",
      timestamp: DateTime.now(),
      viewers: [],
      type: "text",
      text: text,
      bgColor: bgColorHex,
    );

    await FirebaseFirestore.instance
        .collection("statuses")
        .doc(widget.currentUser.uid)
        .collection("items")
        .doc(statusId)
        .set(newStatus.toMap());

    // Update lastUpdated for the user's status document itself
    await FirebaseFirestore.instance
        .collection("statuses")
        .doc(widget.currentUser.uid)
        .set({
      "uid": widget.currentUser.uid,
      "userName": widget.currentUser.fullname,
      "profilePic": widget.currentUser.profilepic ?? "",
      "lastUpdated": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    setState(() => _isUploading = false);
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colors[_colorIndex],
      body: SafeArea(
        child: Stack(
          children: [
            // Close Button
            Positioned(
              top: 10,
              left: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Get.back(),
              ),
            ),
            
            // Color changer
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.palette, color: Colors.white, size: 30),
                onPressed: _changeColor,
              ),
            ),

            // TextField
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: TextField(
                  controller: _textController,
                  autofocus: true,
                  maxLength: 250,
                  maxLines: null,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "Type a status",
                    hintStyle: TextStyle(
                      color: Colors.white54,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                    counterText: "",
                  ),
                  onChanged: (val) => setState(() {}),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _textController.text.trim().isNotEmpty
          ? FloatingActionButton(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              onPressed: _isUploading ? null : _uploadStatus,
              child: _isUploading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Icon(Icons.send),
            )
          : null,
    );
  }
}
