import 'package:chatapp/models/usermodel.dart';
import 'package:chatapp/pages/loginpage.dart';
import 'package:chatapp/services/chat_service.dart';
import 'package:chatapp/pages/settings_subpages/chat_settings_page.dart';
import 'package:chatapp/pages/settings_subpages/my_profile_page.dart';
import 'package:chatapp/pages/settings_subpages/privacy_settings_page.dart';
import 'package:chatapp/pages/settings_subpages/notifications_settings_page.dart';
import 'package:chatapp/pages/settings_subpages/security_settings_page.dart';
import 'package:chatapp/pages/settings_subpages/storage_settings_page.dart';
import 'package:chatapp/pages/settings_subpages/two_step_settings_page.dart';
import 'package:chatapp/pages/settings_subpages/help_settings_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsPage extends StatelessWidget {
  final UserModel userModel;
  const SettingsPage({Key? key, required this.userModel}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? const Color(0xFF202C33) : Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ─ App bar with own profile at top ─
          SliverAppBar(
            expandedHeight: 210,
            pinned: true,
            backgroundColor: primary,
            foregroundColor: Colors.white,
            title: const Text(
              "Settings",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      primary,
                      isDark ? const Color(0xFF111B21) : primary.withValues(alpha: 0.82)
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Avatar
                      GestureDetector(
                        onTap: () =>
                            Get.to(() => MyProfilePage(userModel: userModel)),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: SizedBox(
                              width: 90,
                              height: 90,
                              child: (userModel.profilepic?.isNotEmpty ?? false)
                                  ? Image.network(
                                      userModel.profilepic!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => _avatar(isDark),
                                    )
                                  : _avatar(isDark),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () =>
                            Get.to(() => MyProfilePage(userModel: userModel)),
                        child: Column(
                          children: [
                            Text(
                              userModel.fullname ?? "User",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              (userModel.phoneNumber?.isNotEmpty ?? false)
                                  ? userModel.phoneNumber!
                                  : userModel.email ?? "",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 32),
              child: Column(
                children: [
                  // Account section
                  _SettingsSection(
                    title: "Account",
                    items: [
                      _SettingsTile(
                        icon: Icons.security_outlined,
                        color: Colors.blue,
                        label: "Privacy",
                        sublabel: "Block contacts, disappearing messages",
                        onTap: () => Get.to(() => PrivacySettingsPage(userModel: userModel)),
                      ),
                      _SettingsTile(
                        icon: Icons.lock_outline,
                        color: Colors.green,
                        label: "Security",
                        sublabel: "Change number, delete account",
                        onTap: () => Get.to(() => const SecuritySettingsPage()),
                      ),
                      _SettingsTile(
                        icon: Icons.key_outlined,
                        color: Colors.orange,
                        label: "Two-step verification",
                        sublabel: "Add extra security to your account",
                        onTap: () =>
                            Get.to(() => const TwoStepVerificationPage()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  _SettingsSection(
                    title: "Chats & media",
                    items: [
                      _SettingsTile(
                        icon: Icons.chat_outlined,
                        color: Colors.teal,
                        label: "Chats",
                        sublabel: "Theme, wallpapers, chat history",
                        onTap: () => Get.to(() => const ChatSettingsPage()),
                      ),
                      _SettingsTile(
                        icon: Icons.notifications_outlined,
                        color: Colors.red,
                        label: "Notifications",
                        sublabel: "Message, group & call tones",
                        onTap: () =>
                            Get.to(() => const NotificationsSettingsPage()),
                      ),
                      _SettingsTile(
                        icon: Icons.storage_outlined,
                        color: Colors.purple,
                        label: "Storage and data",
                        sublabel: "Network usage, auto-download",
                        onTap: () => Get.to(() => const StorageSettingsPage()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  _SettingsSection(
                    title: "App",
                    items: [
                      _SettingsTile(
                        icon: Icons.help_outline,
                        color: Colors.indigo,
                        label: "Help",
                        sublabel: "Help center, contact us, privacy policy",
                        onTap: () => Get.to(() => const HelpSettingsPage()),
                      ),

                      const SizedBox(height: 14),

                      // Logout button
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          leading: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.logout,
                              color: Colors.red,
                              size: 19,
                            ),
                          ),
                          title: const Text(
                            "Log out",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          onTap: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: Theme.of(context).colorScheme.surface,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                title: Text(
                                  "Log out?",
                                  style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                                ),
                                content: Text(
                                  "Are you sure you want to log out?",
                                  style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text("Cancel"),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                    ),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text("Log out"),
                                  ),
                                ],
                              ),
                            );
                            if (ok == true) {
                              await FirebaseFirestore.instance
                                  .collection("users")
                                  .doc(userModel.uid)
                                  .update({"isOnline": false});
                              await FirebaseAuth.instance.signOut();
                              Get.offAll(
                                () => Loginpage(),
                                transition: Transition.fadeIn,
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _avatar(bool isDark) => Container(
    color: isDark ? const Color(0xFF202C33) : Colors.grey.shade300,
    child: Icon(Icons.person, size: 44, color: isDark ? Colors.white24 : Colors.white),
  );
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> items;
  const _SettingsSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white38 : Colors.grey.shade500,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: items),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String? sublabel;
  final VoidCallback? onTap;
  const _SettingsTile({
    required this.icon,
    required this.color,
    required this.label,
    this.sublabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 19),
      ),
      title: Text(
        label,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.black87),
      ),
      subtitle: sublabel != null
          ? Text(
              sublabel!,
              style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey.shade500),
            )
          : null,
      trailing: Icon(
        Icons.chevron_right,
        color: isDark ? Colors.white10 : Colors.grey.shade400,
        size: 18,
      ),
      onTap: onTap,
    );
  }
}
