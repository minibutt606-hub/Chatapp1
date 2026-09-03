import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsSettingsPage extends StatefulWidget {
  const NotificationsSettingsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsSettingsPage> createState() => _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState extends State<NotificationsSettingsPage> {
  bool _conversationTones = true;
  bool _highPriority = true;
  bool _reactionNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _conversationTones = prefs.getBool('notif_conv_tones') ?? true;
      _highPriority = prefs.getBool('notif_high_priority') ?? true;
      _reactionNotifications = prefs.getBool('notif_reaction') ?? true;
    });
  }

  void _savePref(String key, bool val) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(key, val);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Notifications", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        surfaceTintColor: Colors.white,
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text("Conversation tones", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
            subtitle: const Text("Play sounds for incoming and outgoing messages.", style: TextStyle(color: Colors.grey, fontSize: 13)),
            value: _conversationTones,
            activeColor: Theme.of(context).colorScheme.primary,
            onChanged: (val) {
              setState(() => _conversationTones = val);
              _savePref('notif_conv_tones', val);
            },
          ),
          const Divider(thickness: 0.5, height: 1),

          _buildHeading("Messages"),
          _buildListTile("Notification tone", "Default (ringtone)"),
          _buildListTile("Vibrate", "Default"),
          _buildListTile("Light", "White"),
          SwitchListTile(
            title: const Text("Use high priority notifications", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
            subtitle: const Text("Show previews of notifications at the top of the screen", style: TextStyle(color: Colors.grey, fontSize: 13)),
            value: _highPriority,
            activeColor: Theme.of(context).colorScheme.primary,
            onChanged: (val) {
              setState(() => _highPriority = val);
              _savePref('notif_high_priority', val);
            },
          ),
          SwitchListTile(
            title: const Text("Reaction Notifications", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
            subtitle: const Text("Show notifications for reactions to messages you send", style: TextStyle(color: Colors.grey, fontSize: 13)),
            value: _reactionNotifications,
            activeColor: Theme.of(context).colorScheme.primary,
            onChanged: (val) {
              setState(() => _reactionNotifications = val);
              _savePref('notif_reaction', val);
            },
          ),
          const Divider(thickness: 0.5, height: 1),

          _buildHeading("Groups"),
          _buildListTile("Notification tone", "Default (ringtone)"),
          _buildListTile("Vibrate", "Default"),
          SwitchListTile(
            title: const Text("Use high priority notifications", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
            subtitle: const Text("Show previews of notifications at the top of the screen", style: TextStyle(color: Colors.grey, fontSize: 13)),
            value: _highPriority,
            activeColor: Theme.of(context).colorScheme.primary,
            onChanged: (val) {},
          ),
          const Divider(thickness: 0.5, height: 1),

          _buildHeading("Calls"),
          _buildListTile("Ringtone", "Default (ringtone)"),
          _buildListTile("Vibrate", "Default"),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeading(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
    );
  }

  Widget _buildListTile(String title, String subtitle) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      onTap: () {},
    );
  }
}
