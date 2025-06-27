import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:ecommerece_app/features/chat/ui/chat_room_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/chat_room_model.dart';
import '../services/chat_service.dart';

class DirectChatsScreen extends StatefulWidget {
  @override
  State<DirectChatsScreen> createState() => _DirectChatsScreenState();
}

class _DirectChatsScreenState extends State<DirectChatsScreen> {
  final ChatService chatService = ChatService();
  String get currentUserId => FirebaseAuth.instance.currentUser!.uid;

  bool editMode = false;
  bool searchMode = false;
  Set<String> selectedChatIds = {};
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();

  Future<MyUser?> getOtherUser(ChatRoomModel chat) async {
    final otherId = chat.participants.firstWhere((id) => id != currentUserId);
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(otherId).get();
    if (!doc.exists) return null;
    return MyUser.fromDocument(doc.data()!);
  }

  void toggleSearchMode() {
    setState(() {
      searchMode = !searchMode;
      if (!searchMode) {
        searchQuery = '';
        searchController.clear();
      }
    });
  }

  void toggleEditMode() {
    setState(() {
      editMode = !editMode;
      if (!editMode) selectedChatIds.clear();
    });
  }

  void onSelectChat(String chatId, bool selected) {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            searchMode
                ? TextField(
                  controller: searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Search...',
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.trim().toLowerCase();
                    });
                  },
                )
                : null,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () async {
            if (editMode) {
              setState(() {
                editMode = false;
                selectedChatIds.clear();
              });
            } else if (searchMode) {
              setState(() {
                searchMode = false;
                searchQuery = '';
                searchController.clear();
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions:
            editMode
                ? [
                  InkWell(
                    onTap: toggleEditMode,
                    child: Image.asset(
                      'assets/015.png',
                      height: 30.sp,
                      width: 30.sp,
                      cacheWidth: 40,
                      cacheHeight: 40,
                    ),
                  ),
                  SizedBox(width: 5.w),
                  InkWell(
                    onTap: toggleEditMode,
                    child: Image.asset(
                      'assets/014.png',
                      height: 30.sp,
                      width: 30.sp,
                      cacheWidth: 40,
                      cacheHeight: 40,
                    ),
                  ),
                  /*  TextButton(
                    onPressed:
                        selectedChatIds.isEmpty
                            ? null
                            : () {
                              // Handle delete or other action for selectedChatIds
                              // Example: chatService.deleteChats(selectedChatIds);
                              toggleEditMode();
                            },
                    child: Text(
                      'Delete',
                      style: TextStyle(
                        color:
                            selectedChatIds.isEmpty ? Colors.grey : Colors.red,
                        fontSize: 16.sp,
                      ),
                    ),
                  ), */
                ]
                : [
                  InkWell(
                    onTap: toggleEditMode,
                    child: Image.asset(
                      'assets/002 (1).png',
                      height: 30.sp,
                      width: 30.sp,
                      cacheWidth: 40,
                      cacheHeight: 40,
                    ),
                  ),
                  SizedBox(width: 5.w),
                  IconButton(
                    icon: Icon(Icons.search, color: Colors.black, size: 30.sp),
                    onPressed: toggleSearchMode,
                  ),
                ],
      ),
      body: StreamBuilder<List<ChatRoomModel>>(
        stream: chatService.getChatRoomsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final directChats =
              snapshot.data!.where((chat) => chat.type == 'direct').toList();
          if (directChats.isEmpty)
            return const Center(child: Text('No direct chats.'));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: directChats.length,
            itemBuilder: (context, index) {
              final chat = directChats[index];
              return FutureBuilder<MyUser?>(
                future: getOtherUser(chat),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) {
                    return const ListTile(
                      leading: CircleAvatar(
                        radius: 25,
                        child: Icon(Icons.person),
                      ),
                      title: Text('Loading...'),
                    );
                  }
                  final friend = userSnap.data!;
                  // Filter by search query
                  if (searchQuery.isNotEmpty &&
                      !friend.name.toLowerCase().contains(searchQuery)) {
                    return const SizedBox.shrink();
                  }
                  // Only show checkboxes for non-brands (assuming brands have isBrand == true)
                  final showCheckbox = editMode;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: InkWell(
                      onTap:
                          editMode
                              ? () {
                                onSelectChat(
                                  chat.id,
                                  !selectedChatIds.contains(chat.id),
                                );
                              }
                              : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => ChatScreen(
                                          chatRoomId: chat.id,
                                          chatRoomName: friend.name,
                                        ),
                                  ),
                                );
                              },
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundImage:
                                friend.url.isNotEmpty
                                    ? NetworkImage(friend.url)
                                    : null,
                            child:
                                friend.url.isEmpty
                                    ? Text(
                                      friend.name.isNotEmpty
                                          ? friend.name[0]
                                          : '?',
                                    )
                                    : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  friend.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (showCheckbox)
                            StatefulBuilder(
                              builder: (context, checkboxState) {
                                return Checkbox(
                                  value: selectedChatIds.contains(chat.id),
                                  onChanged: (checked) {
                                    checkboxState(() {
                                      if (checked ?? false) {
                                        selectedChatIds.add(chat.id);
                                      } else {
                                        selectedChatIds.remove(chat.id);
                                      }
                                    });

                                    /*                                 onSelectChat(chat.id, );
                                 */
                                  },
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
