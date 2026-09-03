import 'package:flutter/material.dart';
import 'package:chatapp/models/messagemodel.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class BubbleTailPainter extends CustomPainter {
  final Color color;
  final bool isMe;

  BubbleTailPainter({required this.color, required this.isMe});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    if (isMe) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(0, size.height);
    } else {
      path.moveTo(size.width, 0);
      path.lineTo(0, 0);
      path.lineTo(size.width, size.height);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AudioMessageWidget extends StatefulWidget {
  final String url;
  final bool isMe;
  final int? totalDuration; // Total duration from Firestore
  const AudioMessageWidget({
    Key? key,
    required this.url,
    required this.isMe,
    this.totalDuration,
  }) : super(key: key);

  @override
  State<AudioMessageWidget> createState() => _AudioMessageWidgetState();
}

class _AudioMessageWidgetState extends State<AudioMessageWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;
  bool isLoading = false;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => isPlaying = state == PlayerState.playing);
    });
    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) setState(() => duration = newDuration);
    });
    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) setState(() => position = newPosition);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String minutes = d.inMinutes.toString();
    String seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    // If the player hasn't fetched the duration yet, use the one from Firestore
    Duration displayDuration = duration;
    if (duration == Duration.zero && widget.totalDuration != null) {
      displayDuration = Duration(seconds: widget.totalDuration!);
    }

    return Container(
      width: 210,
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: widget.isMe ? Colors.white : Colors.grey[700],
                      size: 24,
                    ),
                    onPressed: () async {
                      if (isPlaying) {
                        await _audioPlayer.pause();
                      } else {
                        setState(() => isLoading = true);
                        try {
                          await _audioPlayer.play(UrlSource(widget.url));
                          setState(() => isLoading = false);
                        } catch (e) {
                          setState(() => isLoading = false);
                        }
                      }
                    },
                  ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              ),
              child: Slider(
                min: 0,
                activeColor: widget.isMe ? Colors.white : Theme.of(context).colorScheme.primary,
                inactiveColor: widget.isMe ? Colors.white38 : Colors.grey[400],
                max: displayDuration.inMilliseconds.toDouble() > 0 ? displayDuration.inMilliseconds.toDouble() : 1,
                value: position.inMilliseconds.toDouble().clamp(0, displayDuration.inMilliseconds.toDouble()),
                onChanged: (value) async {
                  await _audioPlayer.seek(Duration(milliseconds: value.toInt()));
                },
              ),
            ),
          ),
          Text(
            isPlaying ? _formatDuration(position) : _formatDuration(displayDuration),
            style: TextStyle(
              fontSize: 10,
              color: widget.isMe ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class VideoMessageWidget extends StatefulWidget {
  final String url;
  final bool isMe;
  const VideoMessageWidget({Key? key, required this.url, required this.isMe})
    : super(key: key);

  @override
  State<VideoMessageWidget> createState() => _VideoMessageWidgetState();
}

class _VideoMessageWidgetState extends State<VideoMessageWidget> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    initializePlayer();
  }

  Future<void> initializePlayer() async {
    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(widget.url),
    );
    await _videoPlayerController.initialize();
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: false,
      looping: false,
      aspectRatio: _videoPlayerController.value.aspectRatio,
      errorBuilder: (context, errorMessage) {
        return Center(child: Text(errorMessage, style: const TextStyle(color: Colors.white)));
      },
    );
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: _chewieController != null &&
              _chewieController!.videoPlayerController.value.isInitialized
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Chewie(controller: _chewieController!),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
