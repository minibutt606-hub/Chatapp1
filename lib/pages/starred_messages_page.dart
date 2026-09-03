import 'package:flutter/material.dart';

class StarredMessagesPage extends StatelessWidget {
  const StarredMessagesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Starred Messages"),
        centerTitle: false,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_outline, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text("No starred messages", style: TextStyle(color: Colors.grey, fontSize: 18)),
            Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                "Tap and hold on any message to star it, so you can easily find it later.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
