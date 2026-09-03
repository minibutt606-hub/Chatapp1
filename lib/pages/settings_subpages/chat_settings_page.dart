import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatSettingsPage extends StatefulWidget {
  const ChatSettingsPage({Key? key}) : super(key: key);

  @override
  State<ChatSettingsPage> createState() => _ChatSettingsPageState();
}

class _ChatSettingsPageState extends State<ChatSettingsPage> {
  String _currentTheme = "Light";
  String _currentFontSize = "Medium";

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentTheme = prefs.getString('app_theme') ?? "Light";
      _currentFontSize = prefs.getString('font_size') ?? "Medium";
    });
  }

  void _showThemeDialog() {
    Get.defaultDialog(
      title: "Choose theme",
      backgroundColor: Colors.white,
      content: Column(
        children: ["Light", "Dark", "System default"].map((t) {
          return RadioListTile<String>(
            title: Text(t),
            value: t,
            groupValue: _currentTheme,
            activeColor: Colors.teal,
            onChanged: (val) async {
              if (val != null) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('app_theme', val);
                setState(() => _currentTheme = val);
                
                if (val == "Dark") Get.changeThemeMode(ThemeMode.dark);
                else if (val == "Light") Get.changeThemeMode(ThemeMode.light);
                else Get.changeThemeMode(ThemeMode.system);
                
                Get.back();
              }
            },
          );
        }).toList(),
      ),
    );
  }

  void _showFontSizeDialog() {
    Get.defaultDialog(
      title: "Font size",
      backgroundColor: Colors.white,
      content: Column(
        children: ["Small", "Medium", "Large"].map((f) {
          return RadioListTile<String>(
            title: Text(f),
            value: f,
            groupValue: _currentFontSize,
            activeColor: Colors.teal,
            onChanged: (val) async {
              if (val != null) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('font_size', val);
                setState(() => _currentFontSize = val);
                Get.back();
                Get.snackbar("Font size", "Font size updated to $val. Restart chat to see full effect.");
              }
            },
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        title: const Text("Chats", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        elevation: 0,
      ),
      body: ListView(
        children: [
          _buildHeading("Display"),
          _buildListTile(Icons.brightness_6_outlined, "Theme", subtitle: _currentTheme, onTap: _showThemeDialog),
          _buildListTile(Icons.wallpaper_outlined, "Wallpaper", onTap: () {
            Get.snackbar("Wallpaper", "Wallpaper selection coming soon.");
          }),
          const Divider(thickness: 0.5, height: 1, indent: 64),
          
          _buildHeading("Settings"),
          _buildListTile(Icons.format_size, "Font size", subtitle: _currentFontSize, onTap: _showFontSizeDialog),
          const Divider(thickness: 0.5, height: 1),

          _buildListTile(Icons.cloud_upload_outlined, "Chat backup", onTap: () {
            _showBackupDialog();
          }),
          _buildListTile(Icons.compare_arrows_outlined, "Transfer chats", onTap: () {
            Get.snackbar("Transfer", "Scanning for nearby devices...");
          }),
          _buildListTile(Icons.history_outlined, "Chat history", onTap: () {
            _showHistoryDialog();
          }),
        ],
      ),
    );
  }

  void _showBackupDialog() {
    Get.defaultDialog(
      title: "Chat Backup",
      backgroundColor: Colors.white,
      content: Column(
        children: [
          const Icon(Icons.cloud_done, size: 50, color: Colors.teal),
          const SizedBox(height: 16),
          const Text("Last backup: Never", style: TextStyle(fontSize: 14)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.snackbar("Backup", "Backing up messages to Google Drive...");
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            child: const Text("BACK UP"),
          )
        ],
      ),
    );
  }

  void _showHistoryDialog() {
    Get.defaultDialog(
      title: "Chat history",
      backgroundColor: Colors.white,
      content: Column(
        children: [
          ListTile(title: const Text("Export chat"), onTap: () => Get.back()),
          ListTile(title: const Text("Archive all chats"), onTap: () => Get.back()),
          ListTile(title: const Text("Clear all chats"), textColor: Colors.red, onTap: () => Get.back()),
          ListTile(title: const Text("Delete all chats"), textColor: Colors.red, onTap: () => Get.back()),
        ],
      ),
    );
  }

  Widget _buildHeading(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey),
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, {String? subtitle, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade600),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)) : null,
      onTap: onTap,
    );
  }
}
