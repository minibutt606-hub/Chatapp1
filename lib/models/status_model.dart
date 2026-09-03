import 'package:cloud_firestore/cloud_firestore.dart';

class StatusModel {
  String? statusId;
  String? uid;
  String? userName;
  String? profilePic;
  String? imageUrl;
  DateTime? timestamp;
  List<String>? viewers;
  String? type; // "image" (default), "video", "text"
  String? text; // content if type is text
  String? bgColor; // background color hex if type is text

  StatusModel({
    this.statusId,
    this.uid,
    this.userName,
    this.profilePic,
    this.imageUrl,
    this.timestamp,
    this.viewers,
    this.type,
    this.text,
    this.bgColor,
  });

  factory StatusModel.fromMap(Map<String, dynamic> map) {
    return StatusModel(
      statusId: map['statusId'],
      uid: map['uid'],
      userName: map['userName'],
      profilePic: map['profilePic'],
      imageUrl: map['imageUrl'],
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : null,
      viewers: List<String>.from(map['viewers'] ?? []),
      type: map['type'] ?? 'image',
      text: map['text'],
      bgColor: map['bgColor'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'statusId': statusId,
      'uid': uid,
      'userName': userName,
      'profilePic': profilePic,
      'imageUrl': imageUrl,
      'timestamp': timestamp,
      'viewers': viewers,
      'type': type ?? 'image',
      'text': text,
      'bgColor': bgColor,
    };
  }
}

class UserStatusModel {
  String? uid;
  String? userName;
  String? profilePic;
  DateTime? lastUpdated;
  List<StatusModel>? statuses;

  UserStatusModel({
    this.uid,
    this.userName,
    this.profilePic,
    this.lastUpdated,
    this.statuses,
  });

  factory UserStatusModel.fromMap(Map<String, dynamic> map, List<StatusModel> statuses) {
    return UserStatusModel(
      uid: map['uid'],
      userName: map['userName'],
      profilePic: map['profilePic'],
      lastUpdated: map['lastUpdated'] != null
          ? (map['lastUpdated'] as Timestamp).toDate()
          : null,
      statuses: statuses,
    );
  }
}
