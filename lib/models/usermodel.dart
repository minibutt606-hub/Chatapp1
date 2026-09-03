import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String? uid;
  String? fullname;
  String? email;
  String? profilepic;
  String? phoneNumber;
  bool? isOnline;
  DateTime? lastSeen;
  String? typingStatus;
  String? about;
  Map<String, dynamic>? blockedUsers;
  Map<String, dynamic>? privacySettings;

  UserModel({
    required this.uid,
    required this.fullname,
    required this.email,
    required this.profilepic,
    this.phoneNumber = "",
    this.isOnline = false,
    this.lastSeen,
    this.typingStatus = "",
    this.about = "Available",
    this.blockedUsers,
    this.privacySettings,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      fullname: map['fullname'],
      email: map['email'],
      profilepic: map['profilepic'],
      phoneNumber: map['phoneNumber'] ?? "",
      isOnline: map['isOnline'] ?? false,
      lastSeen: map['lastSeen'] != null
          ? (map['lastSeen'] as Timestamp).toDate()
          : null,
      typingStatus: map['typingStatus'] ?? "",
      about: map['about'] ?? "Available",
      blockedUsers: map['blockedUsers'] != null ? Map<String, dynamic>.from(map['blockedUsers']) : {},
      privacySettings: map['privacySettings'] ?? {
        "lastSeen": "Nobody",
        "profilePhoto": "Everyone",
        "about": "Everyone",
        "status": "My contacts",
        "readReceipts": true,
      },
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullname': fullname,
      'email': email,
      'profilepic': profilepic,
      'phoneNumber': phoneNumber,
      'isOnline': isOnline,
      'lastSeen': lastSeen,
      'typingStatus': typingStatus,
      'about': about,
      'blockedUsers': blockedUsers ?? {},
      'privacySettings': privacySettings ?? {
        "lastSeen": "Nobody",
        "profilePhoto": "Everyone",
        "about": "Everyone",
        "status": "My contacts",
        "readReceipts": true,
      },
    };
  }
}
