import 'package:chatapp/models/chatroommodel.dart';
import 'package:chatapp/models/messagemodel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SearchChatPage extends StatefulWidget {
  final Chatroommodel chatRoom;
  final String currentUserId;

  const SearchChatPage({
    Key? key,
    required this.chatRoom,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<SearchChatPage> createState() => _SearchChatPageState();
}

class _SearchChatPageState extends State<SearchChatPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Messagemodel> _allMessages = [];
  List<Messagemodel> _results = [];
  bool _loading = false;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _loading = true);
    final snap = await FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(widget.chatRoom.chatroomid)
        .collection("messages")
        .where("type", isEqualTo: "text")
        .orderBy("createdon", descending: false)
        .get();
    _allMessages =
        snap.docs.map((d) => Messagemodel.fromMap(d.data())).toList();
    setState(() => _loading = false);
  }

  void _search(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _currentIndex = 0;
      });
      return;
    }
    final q = query.toLowerCase();
    setState(() {
      _results = _allMessages
          .where((m) => (m.text ?? "").toLowerCase().contains(q))
          .toList();
      _currentIndex = _results.isNotEmpty ? _results.length - 1 : 0;
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: TextField(
          controller: _searchCtrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
          decoration: const InputDecoration(
            hintText: "Search messages...",
            hintStyle: TextStyle(color: Colors.white60),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 4),
          ),
          onChanged: _search,
        ),
        actions: [
          if (_results.isNotEmpty) ...[
            Text(
              "${_currentIndex + 1}/${_results.length}",
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_up),
              onPressed: _currentIndex > 0
                  ? () => setState(() => _currentIndex--)
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_down),
              onPressed: _currentIndex < _results.length - 1
                  ? () => setState(() => _currentIndex++)
                  : null,
            ),
          ],
          const SizedBox(width: 4),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _searchCtrl.text.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text("Type to search messages",
                          style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
                )
              : _results.isEmpty
                  ? Center(
                      child: Text("No results for \"${_searchCtrl.text}\"",
                          style: TextStyle(color: Colors.grey.shade500)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _results.length,
                      itemBuilder: (context, i) {
                        final msg = _results[i];
                        final isMe = msg.sender == widget.currentUserId;
                        final highlighted = i == _currentIndex;
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: highlighted
                                ? primary.withValues(alpha: 0.12)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: highlighted
                                ? Border.all(
                                    color: primary.withValues(alpha: 0.4))
                                : null,
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4)
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                isMe
                                    ? Icons.arrow_back_ios_new
                                    : Icons.arrow_forward_ios,
                                size: 14,
                                color: isMe ? primary : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _HighlightedText(
                                      text: msg.text ?? "",
                                      query: _searchCtrl.text,
                                      highlightColor: primary,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _fmt(msg.createdon),
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }

  String _fmt(DateTime? dt) {
    if (dt == null) return "";
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return "Today ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    }
    return "${dt.day}/${dt.month}/${dt.year}";
  }
}

class _HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final Color highlightColor;
  const _HighlightedText(
      {required this.text,
      required this.query,
      required this.highlightColor});

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) return Text(text);
    final lower = text.toLowerCase();
    final lowerQ = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;
    int idx;
    while ((idx = lower.indexOf(lowerQ, start)) != -1) {
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx)));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + query.length),
        style: TextStyle(
            backgroundColor: highlightColor.withValues(alpha: 0.25),
            color: highlightColor,
            fontWeight: FontWeight.bold),
      ));
      start = idx + query.length;
    }
    if (start < text.length) spans.add(TextSpan(text: text.substring(start)));
    return RichText(
        text: TextSpan(
            style: const TextStyle(color: Colors.black87, fontSize: 14),
            children: spans));
  }
}
