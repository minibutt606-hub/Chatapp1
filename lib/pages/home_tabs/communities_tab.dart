import 'package:chatapp/models/firebase_helper.dart';
import 'package:chatapp/models/usermodel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CommunitiesTab extends StatelessWidget {
  final UserModel userModel;

  const CommunitiesTab({Key? key, required this.userModel}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color primaryColor = isDark ? const Color(0xFF00A884) : Theme.of(context).colorScheme.primary;

    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection("communities").snapshots(),
      builder: (context, snapshot) {
        return ListView(
          children: [
            const SizedBox(height: 10),
            ListTile(
              leading: Stack(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF202C33) : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.groups, color: isDark ? Colors.white24 : Colors.white, size: 30),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: primaryColor,
                      child: const Icon(Icons.add, size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
              title: Text("New Community",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black)),
              onTap: () {},
            ),
            Divider(thickness: 0.5, color: isDark ? Colors.white10 : Colors.grey[300]),
            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty)
              ...snapshot.data!.docs.map((doc) {
                var data = doc.data() as Map<String, dynamic>;
                return _buildCommunityTile(context, data["name"], Icons.group);
              }).toList()
            else
              Column(
                children: [
                   Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await FirebaseHelper.createSampleCommunities();
                      },
                      icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                      label: const Text("Create Sample Communities", style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                    ),
                  ),
                  _buildCommunityTile(context, "Tech Enthusiasts (Preview)", Icons.computer),
                  _buildCommunityTile(context, "Announcements (Preview)", Icons.campaign),
                  _buildCommunityTile(context, "Local Events (Preview)", Icons.place),
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(Icons.groups_3_outlined, size: 60, color: isDark ? Colors.white10 : Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text("Stay connected with a community",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white60 : Colors.black54)),
                        const SizedBox(height: 8),
                        Text(
                          "Communities bring members together in topic-based groups, and make it easy to get announcements.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                ],
              )
          ],
        );
      },
    );
  }

  Widget _buildCommunityTile(BuildContext context, String name, IconData icon) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color primaryColor = isDark ? const Color(0xFF00A884) : Theme.of(context).colorScheme.primary;
    return Column(
      children: [
        ListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF00A884).withOpacity(0.1) : primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primaryColor),
          ),
          title: Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
          subtitle: Text("Tap to see members", style: TextStyle(color: isDark ? Colors.white60 : Colors.black54)),
          onTap: () {},
        ),
        Divider(indent: 80, thickness: 0.2, color: isDark ? Colors.white10 : Colors.grey[300]),
      ],
    );
  }
}
