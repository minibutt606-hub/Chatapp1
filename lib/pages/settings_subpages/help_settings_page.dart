import 'package:flutter/material.dart';

class HelpSettingsPage extends StatelessWidget {
  const HelpSettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Help", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        surfaceTintColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _buildListTile(Icons.help_outline, "Help Center", "Get help, contact us"),
          _buildListTile(Icons.people_outline, "Contact us", "Questions? Need help?"),
          _buildListTile(Icons.description_outlined, "Terms and Privacy Policy", ""),
          _buildListTile(Icons.info_outline, "App info", ""),
        ],
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade600),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
      subtitle: subtitle.isNotEmpty ? Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)) : null,
      onTap: () {},
    );
  }
}
