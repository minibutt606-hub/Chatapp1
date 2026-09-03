import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../qr_scanner_page.dart';

class LinkedDevicesPage extends StatefulWidget {
  const LinkedDevicesPage({Key? key}) : super(key: key);

  @override
  State<LinkedDevicesPage> createState() => _LinkedDevicesPageState();
}

class _LinkedDevicesPageState extends State<LinkedDevicesPage> {
  List<Map<String, dynamic>> linkedDevices = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    List<String> devicesJson = prefs.getStringList('linked_devices') ?? [];
    setState(() {
      linkedDevices = devicesJson
          .map((item) => jsonDecode(item) as Map<String, dynamic>)
          .toList();
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text("Linked devices", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        surfaceTintColor: Colors.white,
        actions: [
          IconButton(onPressed: _loadDevices, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.devices_outlined, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    "Use WhatsApp on other devices without keeping your phone online.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        await Get.to(() => const QRScannerPage());
                        _loadDevices(); // Refresh after returning from scanner
                      },
                      child: const Text("Link a device", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(top: 24)),
          if (linkedDevices.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  "Device status".toUpperCase(),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final device = linkedDevices[index];
                  return _buildDeviceTile(
                    icon: device['platform'] == 'Windows' ? Icons.computer : Icons.laptop_mac,
                    name: device['platform'] ?? "Unknown Device",
                    status: "Last active ${device['lastActive'] ?? 'recently'}",
                    onTap: () => _removeDevice(index),
                  );
                },
                childCount: linkedDevices.length,
              ),
            ),
          ],
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: const Text(
                "Your personal messages are end-to-end encrypted on all your devices.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.black45),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _removeDevice(int index) async {
    final ok = await Get.defaultDialog(
      title: "Log out?",
      middleText: "Are you sure you want to log out from this device?",
      textConfirm: "Log out",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      onConfirm: () => Get.back(result: true),
    );

    if (ok == true) {
      final prefs = await SharedPreferences.getInstance();
      linkedDevices.removeAt(index);
      List<String> devicesJson = linkedDevices.map((item) => jsonEncode(item)).toList();
      await prefs.setStringList('linked_devices', devicesJson);
      _loadDevices();
    }
  }

  Widget _buildDeviceTile({required IconData icon, required String name, required String status, required VoidCallback onTap}) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          ListTile(
            onTap: onTap,
            leading: CircleAvatar(
              backgroundColor: Colors.grey.shade100,
              child: Icon(icon, color: Colors.grey.shade600, size: 20),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text(status, style: const TextStyle(fontSize: 13)),
          ),
          Divider(height: 1, indent: 70, color: Colors.grey.shade200),
        ],
      ),
    );
  }
}
