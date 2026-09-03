import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TwoStepVerificationPage extends StatefulWidget {
  const TwoStepVerificationPage({Key? key}) : super(key: key);

  @override
  State<TwoStepVerificationPage> createState() => _TwoStepVerificationPageState();
}

class _TwoStepVerificationPageState extends State<TwoStepVerificationPage> {
  bool _isEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isEnabled = prefs.getString('two_step_pin') != null;
    });
  }

  void _showPinDialog() {
    TextEditingController pinController = TextEditingController();
    Get.defaultDialog(
      title: "Create a 6-digit PIN",
      backgroundColor: Colors.white,
      content: Column(
        children: [
          const Text(
            "Enter a 6-digit PIN that you'll be asked for when you register your phone number with ChatApp again.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: pinController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            obscureText: true,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              counterText: "",
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.teal)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.teal, width: 2)),
            ),
          ),
        ],
      ),
      textConfirm: "NEXT",
      confirmTextColor: Colors.white,
      onConfirm: () async {
        if (pinController.text.length == 6) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('two_step_pin', pinController.text);
          setState(() => _isEnabled = true);
          Get.back();
          Get.snackbar("Success", "Two-step verification is enabled.", backgroundColor: Colors.green.shade100);
        } else {
          Get.snackbar("Error", "PIN must be 6 digits", backgroundColor: Colors.red.shade100);
        }
      },
    );
  }

  void _disableTwoStep() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('two_step_pin');
    setState(() => _isEnabled = false);
    Get.snackbar("Disabled", "Two-step verification is turned off.", backgroundColor: Colors.grey.shade200);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Two-step verification", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        elevation: 0,
      ),
      body: _isEnabled ? _buildEnabledView() : _buildDisabledView(),
    );
  }

  Widget _buildDisabledView() {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            children: [
              const SizedBox(height: 20),
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: isDark ? const Color(0xFF202C33) : const Color(0xFFF0F0F0),
                  child: const Icon(Icons.password_rounded, size: 50, color: Colors.teal),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                "For extra security, turn on two-step verification, which will require a PIN when registering your phone number with ChatApp again.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: isDark ? Colors.white70 : Colors.black87, height: 1.5),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 0,
              ),
              onPressed: _showPinDialog,
              child: const Text("Turn on", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnabledView() {
    return ListView(
      children: [
        const SizedBox(height: 24),
        const Center(
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Color(0xFFF0F0F0),
            child: Icon(Icons.check_circle, size: 60, color: Colors.teal),
          ),
        ),
        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            "Two-step verification is enabled. You'll need to enter your PIN when registering your phone number with ChatApp again.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.black54, height: 1.5),
          ),
        ),
        const SizedBox(height: 32),
        _buildOption(Icons.cancel_outlined, "Turn off", _disableTwoStep),
        _buildOption(Icons.password, "Change PIN", _showPinDialog),
        _buildOption(Icons.email_outlined, "Change email address", () {
          Get.snackbar("Coming soon", "Email backup feature is under development.");
        }),
      ],
    );
  }

  Widget _buildOption(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.black54),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}
