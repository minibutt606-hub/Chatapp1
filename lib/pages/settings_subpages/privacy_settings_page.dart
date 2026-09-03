import 'package:chatapp/models/usermodel.dart';
import 'package:chatapp/pages/settings_subpages/blocked_contacts_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PrivacySettingsPage extends StatefulWidget {
  final UserModel userModel;
  const PrivacySettingsPage({Key? key, required this.userModel}) : super(key: key);

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  bool _readReceipts = true;

  String _lastSeen = "Nobody";
  String _profilePhoto = "Everyone";
  String _about = "Everyone";
  String _status = "My contacts";
  String _messageTimer = "Off";
  String _groups = "Everyone";
  bool _fingerprint = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      final p = widget.userModel.privacySettings;
      _lastSeen = p?['lastSeen'] ?? "Nobody";
      _profilePhoto = p?['profilePhoto'] ?? "Everyone";
      _about = p?['about'] ?? "Everyone";
      _status = p?['status'] ?? "My contacts";
      _readReceipts = p?['readReceipts'] ?? true;
      _messageTimer = p?['messageTimer'] ?? "Off";
      _groups = p?['groups'] ?? "Everyone";
      _fingerprint = p?['fingerprint'] ?? false;
    });
  }

  Future<void> _updateFirebasePrivacy(String key, dynamic value) async {
    widget.userModel.privacySettings ??= {};
    widget.userModel.privacySettings![key] = value;
    await FirebaseFirestore.instance.collection("users").doc(widget.userModel.uid).update({
      "privacySettings": widget.userModel.privacySettings,
    });
  }

  Future<void> _updateReadReceipts(bool val) async {
    setState(() => _readReceipts = val);
    await _updateFirebasePrivacy("readReceipts", val);
  }

  Future<void> _updateStringPref(
    String key,
    String val,
    Function(String) updateState,
  ) async {
    setState(() => updateState(val));
    await _updateFirebasePrivacy(key, val);
  }

  Future<void> _updateBoolPref(
    String key,
    bool val,
    Function(bool) updateState,
  ) async {
    setState(() => updateState(val));
    await _updateFirebasePrivacy(key, val);
  }

  void _showSelectionSheet(
    String title,
    String prefKey,
    List<String> options,
    String currentValue,
    Function(String) updateState,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              ...options.map(
                (option) => RadioListTile<String>(
                  title: Text(
                    option,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  value: option,
                  groupValue: currentValue,
                  activeColor: Theme.of(context).colorScheme.primary,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  onChanged: (val) {
                    if (val != null) {
                      _updateStringPref(prefKey, val, updateState);
                      Navigator.pop(ctx);
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Privacy",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        elevation: 0,
      ),
      body: ListView(
        children: [
          _buildHeading("Who can see my personal info"),
          _buildListTile(
            "Last seen and online",
            _lastSeen,
            onTap: () => _showSelectionSheet(
              "Last seen and online",
              "lastSeen",
              ["Everyone", "My contacts", "Nobody"],
              _lastSeen,
              (v) => _lastSeen = v,
            ),
          ),
          _buildListTile(
            "Profile photo",
            _profilePhoto,
            onTap: () => _showSelectionSheet(
              "Profile photo",
              "profilePhoto",
              ["Everyone", "My contacts", "Nobody"],
              _profilePhoto,
              (v) => _profilePhoto = v,
            ),
          ),
          _buildListTile(
            "About",
            _about,
            onTap: () => _showSelectionSheet(
              "About",
              "about",
              ["Everyone", "My contacts", "Nobody"],
              _about,
              (v) => _about = v,
            ),
          ),
          _buildListTile(
            "Status",
            _status,
            onTap: () => _showSelectionSheet(
              "Status",
              "status",
              ["My contacts", "My contacts except...", "Only share with..."],
              _status,
              (v) => _status = v,
            ),
          ),

          const Divider(thickness: 0.5, height: 1),

          _buildHeading("Disappearing messages"),
          _buildListTile(
            "Default message timer",
            _messageTimer,
            subtitle:
                "Start new chats with disappearing messages set to your timer",
            onTap: () => _showSelectionSheet(
              "Message timer",
              "messageTimer",
              ["24 hours", "7 days", "90 days", "Off"],
              _messageTimer,
              (v) => _messageTimer = v,
            ),
          ),
          const Divider(thickness: 0.5, height: 1),

          _buildListTile(
            "Groups",
            _groups,
            onTap: () => _showSelectionSheet(
              "Who can add me to groups",
              "groups",
              ["Everyone", "My contacts", "My contacts except..."],
              _groups,
              (v) => _groups = v,
            ),
          ),
          
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection("users").doc(widget.userModel.uid).snapshots(),
            builder: (context, snapshot) {
              int count = 0;
              if (snapshot.hasData && snapshot.data!.data() != null) {
                final d = snapshot.data!.data() as Map<String, dynamic>;
                final blocked = d['blockedUsers'] as Map<dynamic, dynamic>? ?? {};
                count = blocked.keys.where((k) => blocked[k] == true).length;
              }
              return _buildListTile(
                "Blocked contacts",
                count.toString(),
                onTap: () => Get.to(() => BlockedContactsPage(userModel: widget.userModel)),
              );
            },
          ),

          _buildListTile(
            "Fingerprint lock",
            _fingerprint ? "Enabled" : "Disabled",
            onTap: () {
              _updateBoolPref(
                "fingerprint",
                !_fingerprint,
                (v) => _fingerprint = v,
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeading(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildListTile(
    String title,
    String trailingText, {
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            )
          : null,
      trailing: Text(
        trailingText,
        style: const TextStyle(color: Colors.grey, fontSize: 14),
      ),
      onTap: onTap,
    );
  }
}
