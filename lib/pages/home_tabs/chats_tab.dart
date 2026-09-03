import 'package:chatapp/models/chatroommodel.dart';
import 'package:chatapp/models/firebase_helper.dart';
import 'package:chatapp/models/usermodel.dart';
import 'package:chatapp/widgets/chatroom_tile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChatsTab extends StatefulWidget {
  final UserModel userModel;

  const ChatsTab({Key? key, required this.userModel}) : super(key: key);

  @override
  State<ChatsTab> createState() => _ChatsTabState();
}

class _ChatsTabState extends State<ChatsTab> {
  TextEditingController searchController = TextEditingController();
  String searchQuery = "";
  String selectedFilter = "All"; // All, Unread, Favorites, Groups
  Map<String, String> chatroomToUsername = {};

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _updateUsernameMap(List<DocumentSnapshot> docs) async {
    for (var doc in docs) {
      Chatroommodel model = Chatroommodel.fromMap(
        doc.data() as Map<String, dynamic>,
      );
      if (!chatroomToUsername.containsKey(model.chatroomid)) {
        Map<String, dynamic> participants = model.participants!;
        List<String> participantKeys = participants.keys.toList();
        participantKeys.remove(widget.userModel.uid);

        if (participantKeys.isNotEmpty) {
          UserModel? targetUser = await FirebaseHelper.getUserModelById(
            participantKeys[0],
          );
          if (targetUser != null && mounted) {
            setState(() {
              chatroomToUsername[model.chatroomid!] = targetUser.fullname!
                  .toLowerCase();
            });
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color primaryColor = isDark ? const Color(0xFF00A884) : Theme.of(context).colorScheme.primary;

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF202C33) : Colors.grey[100],
              borderRadius: BorderRadius.circular(25),
            ),
            child: TextField(
              controller: searchController,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: "Ask Meta AI or Search",
                hintStyle: TextStyle(color: isDark ? Colors.white60 : Colors.grey, fontSize: 16),
                prefixIcon: Icon(Icons.search, color: isDark ? Colors.white60 : Colors.grey),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ),
        // Chips (Updated with logic)
        StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection("chatrooms")
              .where("participants.${widget.userModel.uid}", isEqualTo: true)
              .snapshots(),
          builder: (context, snapshot) {
            int unreadChatsCount = 0;
            if (snapshot.hasData) {
              for (var doc in snapshot.data!.docs) {
                Chatroommodel model = Chatroommodel.fromMap(
                  doc.data() as Map<String, dynamic>,
                );
                int unread = model.unreadCounts?[widget.userModel.uid] ?? 0;
                if (unread > 0) unreadChatsCount++;
              }
            }

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Row(
                children: [
                  _buildChip(context, "All"),
                  _buildChip(context, "Unread", count: unreadChatsCount),
                  _buildChip(context, "Favorites"),
                  _buildChip(context, "Groups"),
                ],
              ),
            );
          },
        ),
        Expanded(
          child: StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection("chatrooms")
                .where("participants.${widget.userModel.uid}", isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                QuerySnapshot chatRoomSnapshot = snapshot.data as QuerySnapshot;
                List<DocumentSnapshot> chatRoomDocs = chatRoomSnapshot.docs
                    .toList();

                chatRoomDocs.sort((a, b) {
                  var dataA = a.data() as Map<String, dynamic>;
                  var dataB = b.data() as Map<String, dynamic>;
                  Timestamp? tA = dataA["lastMessageTime"];
                  Timestamp? tB = dataB["lastMessageTime"];
                  if (tA == null) return 1;
                  if (tB == null) return -1;
                  return tB.compareTo(tA);
                });

                // Deduplication logic for 1-to-1 chats
                Map<String, DocumentSnapshot> uniqueChats = {};
                List<DocumentSnapshot> deduplicatedDocs = [];

                for (var doc in chatRoomDocs) {
                  Map<String, dynamic> data =
                      doc.data() as Map<String, dynamic>;
                  bool isGroup = data["isGroup"] ?? false;

                  if (isGroup) {
                    deduplicatedDocs.add(doc);
                  } else {
                    List<String> participants = (data["participants"] as Map)
                        .keys
                        .cast<String>()
                        .toList();
                    participants.sort();
                    String participantKey = participants.join("_");

                    if (!uniqueChats.containsKey(participantKey)) {
                      uniqueChats[participantKey] = doc;
                      deduplicatedDocs.add(doc);
                    }
                  }
                }

                _updateUsernameMap(deduplicatedDocs);

                // Filter logic
                List<DocumentSnapshot> filteredDocs = deduplicatedDocs.where((
                  doc,
                ) {
                  Chatroommodel model = Chatroommodel.fromMap(
                    doc.data() as Map<String, dynamic>,
                  );
                  bool matchesSearch = true;
                  if (searchQuery.isNotEmpty) {
                    bool messageMatch = model.lastMessage!
                        .toLowerCase()
                        .contains(searchQuery);
                    bool nameMatch =
                        chatroomToUsername.containsKey(model.chatroomid) &&
                        chatroomToUsername[model.chatroomid]!.contains(
                          searchQuery,
                        );
                    matchesSearch = messageMatch || nameMatch;
                  }
                  if (!matchesSearch) return false;

                  switch (selectedFilter) {
                    case "Unread":
                      int unread =
                          model.unreadCounts?[widget.userModel.uid] ?? 0;
                      return unread > 0;
                    case "Favorites":
                      return model.favorites?[widget.userModel.uid] == true;
                    case "Groups":
                      return model.isGroup;
                    default:
                      return true;
                  }
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(child: Text("No $selectedFilter found", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)));
                }

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    Chatroommodel chatRoomModel = Chatroommodel.fromMap(
                      filteredDocs[index].data() as Map<String, dynamic>,
                    );
                    return ChatroomTile(
                      key: ValueKey(chatRoomModel.chatroomid!),
                      chatRoomModel: chatRoomModel,
                      userModel: widget.userModel,
                    );
                  },
                );
              } else if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
              } else {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChip(BuildContext context, String label, {int count = 0}) {
    bool isSelected = selectedFilter == label;
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color primaryColor = isDark ? const Color(0xFF00A884) : Theme.of(context).colorScheme.primary;
    String displayLabel = (count > 0 && label == "Unread")
        ? "$label $count"
        : label;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = label;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark ? const Color(0xFF00A884).withOpacity(0.2) : primaryColor.withOpacity(0.15)) 
              : (isDark ? const Color(0xFF202C33) : Colors.grey[100]),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected
                ? (isDark ? const Color(0xFF00A884) : primaryColor.withOpacity(0.4))
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          displayLabel,
          style: TextStyle(
            color: isSelected ? primaryColor : (isDark ? Colors.white70 : Colors.black87),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
