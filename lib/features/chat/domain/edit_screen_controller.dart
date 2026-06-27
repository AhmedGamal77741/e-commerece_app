import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/features/chat/domain/chat_controller.dart';
import 'package:ecommerece_app/features/chat/services/favorites_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:ecommerece_app/features/chat/models/chat_room_model.dart';
import 'package:ecommerece_app/features/home/domain/feed_controller.dart';

class EditScreenState {
  final int selectedTab;
  final String query;
  final Set<String> directChatsSelected;
  final Set<String> groupChatsSelected;
  final Map<String, String> aliases;

  EditScreenState({
    this.selectedTab = 0,
    this.query = '',
    this.directChatsSelected = const {},
    this.groupChatsSelected = const {},
    this.aliases = const {},
  });

  EditScreenState copyWith({
    int? selectedTab,
    String? query,
    Set<String>? directChatsSelected,
    Set<String>? groupChatsSelected,
    Map<String, String>? aliases,
  }) {
    return EditScreenState(
      selectedTab: selectedTab ?? this.selectedTab,
      query: query ?? this.query,
      directChatsSelected: directChatsSelected ?? this.directChatsSelected,
      groupChatsSelected: groupChatsSelected ?? this.groupChatsSelected,
      aliases: aliases ?? this.aliases,
    );
  }
}

class EditScreenController extends StateNotifier<EditScreenState> {
  late TextEditingController searchController;
  late String uid;
  StreamSubscription? _aliasesSubscription;
  final Ref ref;

  EditScreenController(this.ref, int initialTab) : super(EditScreenState(selectedTab: initialTab)) {
    searchController = TextEditingController();
    uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _subscribeAliases();
  }

  @override
  void dispose() {
    searchController.dispose();
    _aliasesSubscription?.cancel();
    super.dispose();
  }

  void setTab(int index) {
    state = state.copyWith(selectedTab: index);
  }

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  void clearSearch() {
    searchController.clear();
    state = state.copyWith(query: '');
  }

  void _subscribeAliases() {
    if (uid.isEmpty) return;
    _aliasesSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('aliases')
        .snapshots()
        .listen((snap) {
      final map = <String, String>{};
      for (final doc in snap.docs) {
        final alias = doc.data()['alias'] as String?;
        if (alias != null && alias.isNotEmpty) map[doc.id] = alias;
      }
      state = state.copyWith(aliases: map);
    });
  }

  void toggleDirectChatSelection(String id) {
    final current = Set<String>.from(state.directChatsSelected);
    if (current.contains(id)) {
      current.remove(id);
    } else {
      current.add(id);
    }
    state = state.copyWith(directChatsSelected: current);
  }

  void toggleGroupChatSelection(String id) {
    final current = Set<String>.from(state.groupChatsSelected);
    if (current.contains(id)) {
      current.remove(id);
    } else {
      current.add(id);
    }
    state = state.copyWith(groupChatsSelected: current);
  }

  void clearDirectChatSelection() {
    state = state.copyWith(directChatsSelected: {});
  }

  void clearGroupChatSelection() {
    state = state.copyWith(groupChatsSelected: {});
  }

  Future<void> leaveSelectedDirectChats() async {
    if (state.directChatsSelected.isEmpty) return;
    for (final id in state.directChatsSelected) {
      await ref.read(chatControllerProvider.notifier).softDeleteChatForCurrentUser(id);
    }
    state = state.copyWith(directChatsSelected: {});
  }

  Future<void> leaveSelectedGroupChats() async {
    if (state.groupChatsSelected.isEmpty) return;
    for (final id in state.groupChatsSelected) {
      await ref.read(chatControllerProvider.notifier).removeParticipantFromGroup(id, uid);
    }
    state = state.copyWith(groupChatsSelected: {});
  }
}

final editScreenControllerProvider = StateNotifierProvider.autoDispose.family<EditScreenController, EditScreenState, int>((ref, initialTab) {
  return EditScreenController(ref, initialTab);
});
