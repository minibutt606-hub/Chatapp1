import 'package:chatapp/models/usermodel.dart';
import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

class CallPage extends StatelessWidget {
  final UserModel currentUser;
  final UserModel targetUser;
  final String callID;
  final bool isVideo;

  const CallPage({
    Key? key,
    required this.currentUser,
    required this.targetUser,
    required this.callID,
    required this.isVideo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final config = isVideo
        ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
        : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall();

    // Enable cloud call recording
    config.avatarBuilder = null; // keep default avatar

    return ZegoUIKitPrebuiltCall(
      appID: 195474778,
      appSign:
          '6c4514bc689bb1969eb9d91089a1b44cddceb31107df2361ff238bab5b8d8c17',
      userID:
          currentUser.uid ?? "user_${DateTime.now().millisecondsSinceEpoch}",
      userName: currentUser.fullname ?? "User",
      callID: callID,
      config: config,
    );
  }
}
