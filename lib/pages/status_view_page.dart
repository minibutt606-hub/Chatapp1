import 'package:chatapp/models/status_model.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StatusViewPage extends StatefulWidget {
  final List<StatusModel> statuses;
  final String userName;
  final String? currentUserUid;

  const StatusViewPage({
    Key? key,
    required this.statuses,
    required this.userName,
    this.currentUserUid,
  }) : super(key: key);

  @override
  State<StatusViewPage> createState() => _StatusViewPageState();
}

class _StatusViewPageState extends State<StatusViewPage>
    with TickerProviderStateMixin {
  int currentIndex = 0;
  late PageController _pageController;

  // One AnimationController per status item (each max 30s)
  late AnimationController _progressController;
  static const int _statusDurationSec = 30;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _progressController = _buildProgressController();
    _startProgress();
    _markAsViewed();
  }

  AnimationController _buildProgressController() {
    return AnimationController(
      vsync: this,
      duration: const Duration(seconds: _statusDurationSec),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _advance();
        }
      });
  }

  void _startProgress() {
    _progressController.forward(from: 0.0);
  }

  void _advance() {
    if (currentIndex < widget.statuses.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.ease,
      );
    } else {
      Get.back();
    }
  }

  void _onPageChanged(int index) {
    if (_videoControllers.containsKey(currentIndex)) {
      _videoControllers[currentIndex]?.pause();
      _videoControllers[currentIndex]?.seekTo(Duration.zero);
    }
    setState(() => currentIndex = index);
    _progressController.stop();
    _progressController.reset();
    
    // For images or text, standard timeframe. Videos handle their own duration.
    if (widget.statuses[index].type != "video") {
       _progressController.duration = const Duration(seconds: _statusDurationSec);
    } else {
       if (_videoControllers.containsKey(index) && _videoControllers[index]!.value.isInitialized) {
          _progressController.duration = _videoControllers[index]!.value.duration;
          _videoControllers[index]!.play();
       }
    }
    
    _startProgress();
    _markAsViewed();
  }

  void _tapLeft() {
    if (currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.ease,
      );
    }
  }

  void _tapRight() {
    _advance();
  }

  void _markAsViewed() async {
    StatusModel currentStatus = widget.statuses[currentIndex];
    if (widget.currentUserUid != null &&
        widget.currentUserUid != currentStatus.uid) {
      if (!(currentStatus.viewers?.contains(widget.currentUserUid) ?? false)) {
        await FirebaseFirestore.instance
            .collection("statuses")
            .doc(currentStatus.uid)
            .collection("items")
            .doc(currentStatus.statusId)
            .update({
          "viewers": FieldValue.arrayUnion([widget.currentUserUid]),
        });
      }
    }
  }

  void _deleteStatus(StatusModel status) async {
    _progressController.stop();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Status",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content:
            const Text("Are you sure you want to delete this status?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startProgress();
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0),
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance
                  .collection("statuses")
                  .doc(status.uid)
                  .collection("items")
                  .doc(status.statusId)
                  .delete();
              Get.back();
              Get.snackbar(
                "Deleted",
                "Status deleted successfully",
                backgroundColor: Colors.green,
                colorText: Colors.white,
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  // We need to keep track of VideoControllers for memory management
  final Map<int, VideoPlayerController> _videoControllers = {};

  @override
  void dispose() {
    _progressController.dispose();
    _pageController.dispose();
    for (var controller in _videoControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildMediaItem(StatusModel status, int index) {
    if (status.type == "text") {
      final color = status.bgColor != null
          ? Color(int.parse(status.bgColor!, radix: 16)).withValues(alpha: 1.0)
          : Colors.black;
      // Start timer immediately for text
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && currentIndex == index && !_progressController.isAnimating) {
          _progressController.forward();
        }
      });
      return Container(
        color: color,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Text(
          status.text ?? "",
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else if (status.type == "video") {
      if (!_videoControllers.containsKey(index)) {
        _videoControllers[index] = VideoPlayerController.networkUrl(Uri.parse(status.imageUrl!))
          ..initialize().then((_) {
             if (mounted) {
               setState(() {});
               if (currentIndex == index) {
                  _progressController.stop();
                  _progressController.duration = _videoControllers[index]!.value.duration;
                  _progressController.forward();
                  _videoControllers[index]!.play();
               }
             }
          });
      }
      
      final controller = _videoControllers[index]!;
      if (!controller.value.isInitialized) {
        _progressController.stop();
        return const Center(child: CircularProgressIndicator(color: Colors.white));
      }
      
      return Center(
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),
      );
    } else {
      // Default is image
      return Image.network(
        status.imageUrl!,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          _progressController.stop();
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        },
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (frame != null && !_progressController.isAnimating) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && currentIndex == index && !_progressController.isAnimating) {
                // Reset to standard 30s for images
                _progressController.duration = const Duration(seconds: _statusDurationSec);
                _progressController.forward();
              }
            });
          }
          return child;
        },
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.broken_image, color: Colors.white54, size: 60),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          if (widget.currentUserUid == widget.statuses[currentIndex].uid) {
            if (details.primaryVelocity != null && details.primaryVelocity! < -300) {
              _showViewersList(widget.statuses[currentIndex]);
            }
          }
        },
        child: Stack(
          children: [
            // ── Full screen status image ──────────────────────────────────────
            PageView.builder(
            controller: _pageController,
            itemCount: widget.statuses.length,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              return _buildMediaItem(widget.statuses[index], index);
            },
          ),

          // ── Left / Right tap areas ────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _tapLeft,
                  child: Container(color: Colors.transparent),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _tapRight,
                  child: Container(color: Colors.transparent),
                ),
              ),
            ],
          ),

          // ── Top overlay: progress bars + user info ────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            right: 8,
            child: Column(
              children: [
                // ── Animated progress bars ─────────────────────────
                Row(
                  children: List.generate(widget.statuses.length, (i) {
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        height: 2.5,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: i < currentIndex
                              // Already viewed — fully white
                              ? Container(color: Colors.white)
                              : i == currentIndex
                                  // Currently viewing — animated fill
                                  ? AnimatedBuilder(
                                      animation: _progressController,
                                      builder: (_, __) => LinearProgressIndicator(
                                        value: _progressController.value,
                                        backgroundColor: Colors.white30,
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                        minHeight: 2.5,
                                      ),
                                    )
                                  // Not yet seen — dim white
                                  : Container(color: Colors.white30),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 10),

                // ── User info row ──────────────────────────────────
                Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Get.back(),
                    ),
                    const SizedBox(width: 4),
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white24,
                      backgroundImage:
                          (widget.statuses[currentIndex].profilePic != null &&
                                  widget.statuses[currentIndex].profilePic!
                                      .isNotEmpty)
                              ? NetworkImage(
                                  widget.statuses[currentIndex].profilePic!)
                              : null,
                      onBackgroundImageError:
                          (widget.statuses[currentIndex].profilePic != null &&
                                  widget.statuses[currentIndex].profilePic!
                                      .isNotEmpty)
                              ? (_, __) {}
                              : null,
                      child: (widget.statuses[currentIndex].profilePic == null ||
                              widget.statuses[currentIndex].profilePic!.isEmpty)
                          ? const Icon(Icons.person,
                              color: Colors.white, size: 16)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // Time ago
                          if (widget.statuses[currentIndex].timestamp != null)
                            Text(
                              _timeAgo(widget.statuses[currentIndex].timestamp!),
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 11),
                            ),
                        ],
                      ),
                    ),
                    // Delete button — own status only
                    if (widget.currentUserUid ==
                        widget.statuses[currentIndex].uid)
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.white),
                        onPressed: () =>
                            _deleteStatus(widget.statuses[currentIndex]),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // ── Viewers count (bottom, own status only) ───────────────────────
          if (widget.currentUserUid == widget.statuses[currentIndex].uid)
            Positioned(
              bottom: 36,
              left: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => _showViewersList(widget.statuses[currentIndex]),
                child: Column(
                  children: [
                    const Icon(Icons.keyboard_arrow_up,
                        color: Colors.white70, size: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.visibility,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          (widget.statuses[currentIndex].viewers?.length ?? 0)
                              .toString(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return "just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }

  void _showViewersList(StatusModel status) {
    _progressController.stop();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text(
                "Seen by ${status.viewers?.length ?? 0}",
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const Divider(height: 24),
              if (status.viewers == null || status.viewers!.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text("No views yet",
                      style: TextStyle(color: Colors.grey, fontSize: 15)),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: status.viewers!.length,
                    itemBuilder: (context, index) {
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection("users")
                            .doc(status.viewers![index])
                            .get(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox();
                          final userData = snapshot.data!.data()
                              as Map<String, dynamic>?;
                          if (userData == null) return const SizedBox();
                          final pic = userData['profilepic'] ?? "";
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: pic.isNotEmpty
                                  ? NetworkImage(pic)
                                  : null,
                              onBackgroundImageError: pic.isNotEmpty ? (_, __) {} : null,
                              child: pic.isEmpty
                                  ? const Icon(Icons.person,
                                      color: Colors.grey)
                                  : null,
                            ),
                            title: Text(userData['fullname'] ?? "Unknown",
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500)),
                          );
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
