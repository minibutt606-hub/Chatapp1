import 'package:cloud_firestore/cloud_firestore.dart';

class Messagemodel {
  String? messageid;
  String? sender;
  String? text;
  String? type; // "text" or "image"
  String? imageUrl;
  bool? seen;
  bool? isDelivered;
  DateTime? createdon;
  int? duration; // for voice messages in seconds
  List<String>? seenBy; // List of UIDs who have seen the message

  Messagemodel({
    required this.sender,
    required this.text,
    required this.seen,
    this.type = "text",
    this.imageUrl = "",
    this.isDelivered = false,
    required this.createdon,
    required this.messageid,
    this.duration,
    this.seenBy,
  });

  factory Messagemodel.fromMap(Map<String, dynamic> map) {
    return Messagemodel(
      sender: map['sender'],
      text: map['text'],
      type: map['type'] ?? "text",
      imageUrl: map['imageUrl'] ?? "",
      seen: map['seen'],
      isDelivered: map['isDelivered'] ?? false,
      createdon: map['createdon'] != null
          ? (map['createdon'] as Timestamp).toDate()
          : DateTime.now(),
      messageid: map['messageid'],
      duration: map['duration'],
      seenBy: map['seenBy'] != null ? List<String>.from(map['seenBy']) : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sender': sender,
      'text': text,
      'type': type,
      'imageUrl': imageUrl,
      'seen': seen,
      'isDelivered': isDelivered,
      'createdon': createdon,
      'messageid': messageid,
      'duration': duration,
      'seenBy': seenBy ?? [],
    };
  }
}
