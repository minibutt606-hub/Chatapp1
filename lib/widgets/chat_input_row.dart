import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'dart:io';

class ChatInputRow extends StatelessWidget {
  final TextEditingController messageController;
  final FocusNode focusNode;
  final bool showEmoji;
  final bool isRecording;
  final VoidCallback onToggleEmoji;
  final VoidCallback onAttachment;
  final VoidCallback onCamera;
  final VoidCallback onSendMessage;
  final VoidCallback onToggleRecording;
  final Function(String) onChanged;

  const ChatInputRow({
    Key? key,
    required this.messageController,
    required this.focusNode,
    required this.showEmoji,
    required this.isRecording,
    required this.onToggleEmoji,
    required this.onAttachment,
    required this.onCamera,
    required this.onSendMessage,
    required this.onToggleRecording,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(
            5,
            8,
            5,
            showEmoji ? 8 : 8 + bottomInset,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: onToggleEmoji,
                        icon: Icon(
                          showEmoji
                              ? Icons.keyboard
                              : Icons.emoji_emotions_outlined,
                          color: Colors.grey,
                          size: 24,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          focusNode: focusNode,
                          controller: messageController,
                          maxLines: 5,
                          minLines: 1,
                          onChanged: onChanged,
                          decoration: const InputDecoration(
                            hintText: "Message",
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 5, vertical: 10),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: onAttachment,
                        icon: const Icon(Icons.attach_file,
                            color: Colors.grey, size: 24),
                      ),
                      if (messageController.text.isEmpty && !isRecording)
                        IconButton(
                          onPressed: onCamera,
                          icon: const Icon(Icons.camera_alt,
                              color: Colors.grey, size: 24),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Send / Mic button
              GestureDetector(
                onTap: messageController.text.isNotEmpty
                    ? onSendMessage
                    : null,
                onLongPressStart:
                    messageController.text.isEmpty && !isRecording
                        ? (_) => onToggleRecording()
                        : null,
                onLongPressEnd: isRecording ? (_) => onToggleRecording() : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isRecording
                        ? Colors.red
                        : Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isRecording
                                ? Colors.red
                                : Theme.of(context).colorScheme.primary)
                            .withOpacity(0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    isRecording
                        ? Icons.stop_rounded
                        : (messageController.text.isNotEmpty
                            ? Icons.send_rounded
                            : Icons.mic_rounded),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Recording indicator
        if (isRecording)
          Container(
            padding: EdgeInsets.only(
                left: 16, right: 16, bottom: 6 + bottomInset),
            child: Row(
              children: [
                const Icon(Icons.circle, color: Colors.red, size: 10),
                const SizedBox(width: 8),
                const Text(
                  'Recording... Release to send',
                  style: TextStyle(color: Colors.red, fontSize: 13),
                ),
              ],
            ),
          ),
        if (showEmoji)
          SizedBox(
            height: 256 + bottomInset,
            child: EmojiPicker(
              onEmojiSelected: (category, emoji) {
                messageController.text =
                    messageController.text + emoji.emoji;
                onChanged(messageController.text);
              },
              config: Config(
                height: 256 + bottomInset,
                checkPlatformCompatibility: true,
                emojiViewConfig: EmojiViewConfig(
                  columns: 7,
                  emojiSizeMax: 32 * (Platform.isIOS ? 1.30 : 1.0),
                ),
                categoryViewConfig: CategoryViewConfig(
                  indicatorColor: Theme.of(context).colorScheme.primary,
                  iconColorSelected:
                      Theme.of(context).colorScheme.primary,
                  backspaceColor:
                      Theme.of(context).colorScheme.primary,
                ),
                bottomActionBarConfig: const BottomActionBarConfig(
                  enabled: false,
                ),
                skinToneConfig: SkinToneConfig(
                  indicatorColor:
                      Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
