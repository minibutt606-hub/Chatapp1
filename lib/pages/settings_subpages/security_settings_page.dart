import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecuritySettingsPage extends StatefulWidget {
  const SecuritySettingsPage({Key? key}) : super(key: key);

  @override
  State<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage> {
  bool _showSecurityNotifs = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showSecurityNotifs = prefs.getBool('security_notifs') ?? false;
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
        title: const Text("Security notifications", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        surfaceTintColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        children: [
          Icon(Icons.lock, size: 80, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 24),
          const Text(
            "Your chats and calls are private",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            "End-to-end encryption keeps your personal messages and calls between you and the people you choose. Not even WhatsApp can read or listen to them.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text("Show security notifications on this device", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
            subtitle: const Text("Get notified when your security code changes for a contact's phone in an end-to-end encrypted chat.", style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4)),
            value: _showSecurityNotifs,
            activeColor: Theme.of(context).colorScheme.primary,
            onChanged: (val) {
              setState(() => _showSecurityNotifs = val);
              _savePref('security_notifs', val);
            },
          ),
        ],
      ),
    );
  }
}
