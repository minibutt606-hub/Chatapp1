import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({Key? key}) : super(key: key);

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  bool isScanning = true;
  bool isConnecting = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Simulate a successful scan after 3 seconds
    _timer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        _onScanSuccess();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onScanSuccess() async {
    setState(() {
      isScanning = false;
      isConnecting = true;
    });

    // Simulate connection delay
    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    List<String> devices = prefs.getStringList('linked_devices') ?? [];
    
    // Create a new mock device
    Map<String, dynamic> newDevice = {
      'platform': devices.length % 2 == 0 ? 'Windows' : 'macOS',
      'lastActive': 'today at ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    devices.add(jsonEncode(newDevice));
    await prefs.setStringList('linked_devices', devices);

    if (mounted) {
      Get.snackbar(
        "Device Linked",
        "Successfully connected to ${newDevice['platform']}",
        backgroundColor: Colors.green.shade100,
        snackPosition: SnackPosition.BOTTOM,
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan QR Code"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (isConnecting)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.green),
                  const SizedBox(height: 20),
                  const Text("Connecting...", style: TextStyle(color: Colors.white, fontSize: 18)),
                ],
              ),
            )
          else ...[
            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    "Point your camera at the QR code on your computer",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ),
            ),
            
            // Scanning line animation
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 250),
              duration: const Duration(seconds: 2),
              builder: (context, double value, child) {
                return Positioned(
                  top: (MediaQuery.of(context).size.height / 2 - 125) + value,
                  left: MediaQuery.of(context).size.width / 2 - 125,
                  child: Container(
                    width: 250,
                    height: 2,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],

          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text(
                  "To use WhatsApp on your computer,\ngo to web.whatsapp.com",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text("CANCEL", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
