// screens/chat_screen.dart
import 'dart:io';
import 'package:ecommerece_app/core/helpers/loading_dialog.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../services/chat_service.dart';
import '../models/message_model.dart';

class ChatScreen extends StatefulWidget {
  final String chatRoomId;
  final String chatRoomName;

  const ChatScreen({
    Key? key,
    required this.chatRoomId,
    required this.chatRoomName,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  XFile? _pickedImage;

  MessageModel? _replyToMessage;

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
  }

  void _markMessagesAsRead() {
    _chatService.markMessagesAsRead(widget.chatRoomId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _pickedImage = picked;
      });
    }
  }

  Future<void> _sendImageMessage() async {
    if (_pickedImage == null) return;
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_$currentUserId.jpg';
    final ref = FirebaseStorage.instance.ref().child('chat_images/$fileName');

    UploadTask uploadTask;
    if (kIsWeb) {
      final bytes = await _pickedImage!.readAsBytes();
      uploadTask = ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
    } else {
      uploadTask = ref.putFile(File(_pickedImage!.path));
    }

    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();
    final content = _messageController.text.trim();

    await _chatService.sendMessage(
      chatRoomId: widget.chatRoomId,
      content: content,
      imageUrl: downloadUrl,
      replyToMessageId: _replyToMessage?.id,
    );

    _messageController.clear();
    setState(() {
      _pickedImage = null;
      _replyToMessage = null;
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    await _chatService.sendMessage(
      chatRoomId: widget.chatRoomId,
      content: content,
      replyToMessageId: _replyToMessage?.id,
    );

    _messageController.clear();
    setState(() {
      _replyToMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        forceMaterialTransparency: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatService.getMessagesStream(widget.chatRoomId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return const Center(
                    child: Text('No messages yet. Start the conversation!'),
                  );
                }

                return _pickedImage != null
                    ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child:
                                kIsWeb
                                    ? Image.network(
                                      _pickedImage!.path,

                                      fit: BoxFit.cover,
                                    )
                                    : Image.file(
                                      File(_pickedImage!.path),

                                      fit: BoxFit.cover,
                                    ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: IconButton(
                              icon: Icon(Icons.close, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _pickedImage = null;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMe = message.senderId == currentUserId;

                        return MessageBubble(
                          message: message,
                          isMe: isMe,
                          onReply: () {
                            setState(() {
                              _replyToMessage = message;
                            });
                          },
                        );
                      },
                    );
              },
            ),
          ),
          if (_replyToMessage != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey[200],
              child: Row(
                children: [
                  const Icon(Icons.reply, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _replyToMessage!.senderName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          _replyToMessage!.content,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () {
                      setState(() {
                        _replyToMessage = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          Container(
            height: 60.h,
            padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 15.w),
            child: Row(
              children: [
                InkWell(
                  onTap: _pickImage,
                  child: Image.asset("assets/추가-007.png"),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  flex: 4,
                  child: TextFormField(
                    onChanged: (value) {
                      setState(() {});
                    },
                    controller: _messageController,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 10.h,
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: ColorsManager.primary600),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: ColorsManager.primary600),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                InkWell(
                  onTap: () async {
                    showLoadingDialog(context);
                    if (_pickedImage != null) {
                      await _sendImageMessage();
                    } else {
                      await _sendMessage();
                    }
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 50.w,
                    height: 37.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color:
                          _messageController.text.isNotEmpty ||
                                  _pickedImage != null
                              ? Colors.black
                              : Color(0xFFEEEEEE),
                    ),
                    child: ImageIcon(
                      AssetImage("assets/Vector 3.png"),
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          /*  Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {
                    // TODO: Show attachment options
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ), */
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final VoidCallback onReply;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    required this.onReply,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        /*   _showMessageOptions(context); */
      },
      onDoubleTap: () => _toggleLove(context), // Double tap to love

      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: SizedBox(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment:
                  isMe ? MainAxisAlignment.start : MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Flexible(
                    child: FutureBuilder(
                      future:
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(message.senderId)
                              .get(),
                      builder: (context, asyncSnapshot) {
                        if (!asyncSnapshot.hasData) {
                          return SizedBox(
                            width: 35.sp,
                            height: 35.sp,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: ColorsManager.primary600,
                              ),
                            ),
                          );
                        }
                        return CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: NetworkImage(
                            asyncSnapshot.data!.data()!['url'],
                          ),
                        );
                      },
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        isMe
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                    children: [
                      if (!isMe)
                        Padding(
                          padding: EdgeInsets.only(left: 8, right: 5),
                          child: Text(
                            message.senderName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isMe ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ),
                      SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment:
                            isMe
                                ? MainAxisAlignment.start
                                : MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (isMe)
                            Flexible(
                              child: InkWell(
                                onTap: () {
                                  _toggleLove(context);
                                },
                                child: ImageIcon(
                                  AssetImage(
                                    message.lovedBy.contains(
                                          FirebaseAuth
                                              .instance
                                              .currentUser!
                                              .uid,
                                        )
                                        ? "assets/icon=like,status=off (1).png"
                                        : "assets/icon=like,status=off.png",
                                  ),

                                  color:
                                      message.lovedBy.contains(
                                            FirebaseAuth
                                                .instance
                                                .currentUser!
                                                .uid,
                                          )
                                          ? Color(0xFF280404)
                                          : Colors.black,
                                ),
                              ),
                            ),
                          if (message.lovedBy.isNotEmpty && isMe)
                            Flexible(
                              child: Text(
                                message.lovedBy.length.toString(),
                                style: TextStyle(
                                  color: const Color(0xFF343434),
                                  fontSize: 14,
                                  fontFamily: 'NotoSans',
                                  fontWeight: FontWeight.w400,
                                  height: 1.40,
                                ),
                              ),
                            ),
                          Flexible(
                            child: Container(
                              margin: EdgeInsets.only(
                                left: isMe ? 5 : 8,
                                right: isMe ? 8 : 5,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Color(0xFFEEEEEE),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(12),
                                  topRight: const Radius.circular(12),
                                  bottomLeft: Radius.circular(isMe ? 12 : 0),
                                  bottomRight: Radius.circular(isMe ? 0 : 12),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (message.content.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 8.0,
                                      ),
                                      child: Text(
                                        message.content,
                                        style: TextStyle(color: Colors.black),
                                      ),
                                    ),
                                  if (message.imageUrl!.isNotEmpty) ...[
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        message.imageUrl!,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ],
                                ],
                              ),

                              /*                     Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _formatTime(message.timestamp),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isMe ? Colors.white70 : Colors.black54,
                                        ),
                                      ),
                                      if (isMe) ...[
                                        const SizedBox(width: 4),
                                        Icon(
                                          message.readBy.length > 1
                                              ? Icons.done_all
                                              : Icons.done,
                                          size: 16,
                                          color: Colors.white70,
                                        ),
                                      ],
                                    ],
                                  ), */
                            ),
                          ),
                          if (message.lovedBy.isNotEmpty && !isMe)
                            Flexible(
                              child: Text(
                                message.lovedBy.length.toString(),
                                style: TextStyle(
                                  color: const Color(0xFF343434),
                                  fontSize: 14,
                                  fontFamily: 'NotoSans',
                                  fontWeight: FontWeight.w400,
                                  height: 1.40,
                                ),
                              ),
                            ),
                          if (!isMe)
                            InkWell(
                              onTap: () {
                                _toggleLove(context);
                              },
                              child: ImageIcon(
                                AssetImage(
                                  message.lovedBy.contains(
                                        FirebaseAuth.instance.currentUser!.uid,
                                      )
                                      ? "assets/icon=like,status=off (1).png"
                                      : "assets/icon=like,status=off.png",
                                ),

                                color:
                                    message.lovedBy.contains(
                                          FirebaseAuth
                                              .instance
                                              .currentUser!
                                              .uid,
                                        )
                                        ? Color(0xFF280404)
                                        : Colors.black,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggleLove(BuildContext context) {
    final chatService = ChatService();
    chatService.toggleLoveReaction(
      messageId: message.id,
      chatRoomId: message.chatRoomId,
    );
  }

  void _showLovedByUsers(BuildContext context) {
    // Show bottom sheet with list of users who loved this message
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.favorite, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${message.lovedBy.length} ${message.lovedBy.length == 1 ? 'person' : 'people'} loved this',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // You would fetch user details for each ID in lovedBy
                // For now, just showing the count
                Text('Loved by ${message.lovedBy.length} users'),
              ],
            ),
          ),
    );
  }

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Reply'),
                onTap: () {
                  Navigator.pop(context);
                  onReply();
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy'),
                onTap: () {
                  // TODO: Copy message
                  Navigator.pop(context);
                },
              ),
              if (isMe)
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Delete'),
                  onTap: () {
                    // TODO: Delete message
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
