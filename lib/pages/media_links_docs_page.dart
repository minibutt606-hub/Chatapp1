import 'package:chatapp/models/chatroommodel.dart';
import 'package:chatapp/models/messagemodel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class MediaLinksDocsPage extends StatefulWidget {
  final Chatroommodel chatRoom;
  const MediaLinksDocsPage({Key? key, required this.chatRoom})
      : super(key: key);

  @override
  State<MediaLinksDocsPage> createState() => _MediaLinksDocsPageState();
}

class _MediaLinksDocsPageState extends State<MediaLinksDocsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Stream<List<Messagemodel>> _getMessages(List<String> types) {
    return FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(widget.chatRoom.chatroomid)
        .collection("messages")
        .orderBy("createdon", descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Messagemodel.fromMap(d.data()))
            .where((m) => types.contains(m.type))
            .toList());
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text("Media, links and docs",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "MEDIA"),
            Tab(text: "LINKS"),
            Tab(text: "DOCS"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MediaTab(stream: _getMessages(["image", "video"])),
          _LinksTab(stream: _getMessages(["text"])),
          _DocsTab(stream: _getMessages(["document", "audio"])),
        ],
      ),
    );
  }
}

// ── MEDIA TAB ──────────────────────────────────────────────────────────────
class _MediaTab extends StatelessWidget {
  final Stream<List<Messagemodel>> stream;
  const _MediaTab({required this.stream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Messagemodel>>(
      stream: stream,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snap.data!;
        if (items.isEmpty) {
          return _EmptyState(
              icon: Icons.photo_library_outlined, label: "No media yet");
        }
        return GridView.builder(
          padding: const EdgeInsets.all(4),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 3,
            mainAxisSpacing: 3,
          ),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final msg = items[i];
            if (msg.type == "video") {
              return GestureDetector(
                onTap: () => _openUrl(msg.imageUrl),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(color: Colors.black54),
                    const Center(
                        child: Icon(Icons.play_circle_fill,
                            color: Colors.white, size: 40)),
                  ],
                ),
              );
            }
            return GestureDetector(
              onTap: () => Get.to(() => _FullImagePage(url: msg.imageUrl!)),
              child: Image.network(
                msg.imageUrl ?? "",
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image, color: Colors.grey),
              ),
            );
          },
        );
      },
    );
  }
}

// ── LINKS TAB ─────────────────────────────────────────────────────────────
class _LinksTab extends StatelessWidget {
  final Stream<List<Messagemodel>> stream;
  const _LinksTab({required this.stream});

  static final _urlReg = RegExp(
      r'https?://[^\s]+',
      caseSensitive: false);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Messagemodel>>(
      stream: stream,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        // Extract text messages that contain URLs
        final links = <String>[];
        for (final m in snap.data!) {
          final matches = _urlReg.allMatches(m.text ?? "");
          for (final match in matches) {
            links.add(match.group(0)!);
          }
        }
        if (links.isEmpty) {
          return _EmptyState(icon: Icons.link_off, label: "No links yet");
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: links.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final url = links[i];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 6),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.link, color: Colors.blue),
              ),
              title: Text(
                url,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 13,
                    decoration: TextDecoration.underline),
              ),
              onTap: () => _openUrl(url),
            );
          },
        );
      },
    );
  }
}

// ── DOCS TAB ──────────────────────────────────────────────────────────────
class _DocsTab extends StatelessWidget {
  final Stream<List<Messagemodel>> stream;
  const _DocsTab({required this.stream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Messagemodel>>(
      stream: stream,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snap.data!;
        if (items.isEmpty) {
          return _EmptyState(
              icon: Icons.insert_drive_file_outlined, label: "No docs yet");
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final msg = items[i];
            final isAudio = msg.type == "audio";
            return ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (isAudio ? Colors.orange : Colors.indigo).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isAudio ? Icons.audiotrack : Icons.insert_drive_file,
                  color: isAudio ? Colors.orange : Colors.indigo,
                ),
              ),
              title: Text(
                msg.text ?? "File",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                isAudio ? "Voice message" : "Document",
                style:
                    TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.open_in_new, size: 18),
                onPressed: () => _openUrl(msg.imageUrl),
              ),
              onTap: () => _openUrl(msg.imageUrl),
            );
          },
        );
      },
    );
  }
}

// ── helpers ───────────────────────────────────────────────────────────────
void _openUrl(String? url) async {
  if (url == null || url.isEmpty) return;
  final uri = Uri.tryParse(url);
  if (uri != null && await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String label;
  const _EmptyState({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(label,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
        ],
      ),
    );
  }
}

class _FullImagePage extends StatelessWidget {
  final String url;
  const _FullImagePage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(url,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.broken_image, color: Colors.white)),
        ),
      ),
    );
  }
}
