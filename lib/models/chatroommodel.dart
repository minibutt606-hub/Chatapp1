import 'package:cloud_firestore/cloud_firestore.dart';

class Chatroommodel {
  String? chatroomid;
  Map<String, dynamic>? participants;
  String? lastMessage;
  DateTime? lastMessageTime;
  bool isGroup;
  String? groupName;
  String? groupPic;
  String? adminId;
  Map<String, dynamic>? favorites; // { "userId": true }
  Map<String, dynamic>? unreadCounts; // { "userId": 5 }
  String? lastMessageSenderName;

  Chatroommodel({
    required this.chatroomid,
    required this.participants,
    this.lastMessage = "",
    this.lastMessageTime,
    this.isGroup = false,
    this.groupName,
    this.groupPic,
    this.adminId,
    this.favorites,
    this.unreadCounts,
    this.lastMessageSenderName,
  });

  factory Chatroommodel.fromMap(Map<String, dynamic> map) {
    return Chatroommodel(
      chatroomid: map['chatroomid'],
      participants: map['participants'],
      lastMessage: map['lastMessage'] ?? "",
      lastMessageTime: map['lastMessageTime'] != null
          ? (map['lastMessageTime'] as Timestamp).toDate()
          : null,
      isGroup: map['isGroup'] ?? false,
      groupName: map['groupName'],
      groupPic: map['groupPic'],
      adminId: map['adminId'],
      favorites: map['favorites'],
      unreadCounts: map['unreadCounts'],
      lastMessageSenderName: map['lastMessageSenderName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatroomid': chatroomid,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'isGroup': isGroup,
      'groupName': groupName,
      'groupPic': groupPic,
      'adminId': adminId,
      'favorites': favorites,
      'unreadCounts': unreadCounts,
      'lastMessageSenderName': lastMessageSenderName,
    };
  }
}
