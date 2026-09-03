import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageSettingsPage extends StatefulWidget {
  const StorageSettingsPage({Key? key}) : super(key: key);

  @override
  State<StorageSettingsPage> createState() => _StorageSettingsPageState();
}

class _StorageSettingsPageState extends State<StorageSettingsPage> {
  bool _useLessData = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _useLessData = prefs.getBool('storage_use_less_data') ?? false;
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
        title: const Text("Storage and data", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        surfaceTintColor: Colors.white,
      ),
      body: ListView(
        children: [
          _buildIconTile(Icons.folder_shared_outlined, "Manage storage", "3.1 GB"),
          const Divider(thickness: 0.5, height: 1, indent: 64),
          _buildIconTile(Icons.data_usage, "Network usage", "142 MB sent • 1.2 GB received"),
          SwitchListTile(
            title: const Text("Use less data for calls", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
            value: _useLessData,
            activeColor: Theme.of(context).colorScheme.primary,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            onChanged: (val) {
              setState(() => _useLessData = val);
              _savePref('storage_use_less_data', val);
            },
          ),
          const Divider(thickness: 0.5, height: 1),

          _buildHeading("Media auto-download"),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text("Voice messages are always auto-downloaded", style: TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          const SizedBox(height: 8),
          _buildListTile("When using mobile data", "Photos"),
          _buildListTile("When connected on Wi-Fi", "All media"),
          _buildListTile("When roaming", "No media"),
          const Divider(thickness: 0.5, height: 1),

          _buildHeading("Media upload quality"),
          _buildListTile("Photo upload quality", "Auto (recommended)"),
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

  Widget _buildIconTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade600, size: 26),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      onTap: () {},
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
