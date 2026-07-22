// features/chat/ui/edit_screen.dart
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/features/chat/domain/edit_screen_controller.dart';
import 'package:ecommerece_app/features/chat/widgets/edit/edit_contacts_tab.dart';
import 'package:ecommerece_app/features/chat/widgets/edit/edit_direct_chats_tab.dart';
import 'package:ecommerece_app/features/chat/widgets/edit/edit_group_chats_tab.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class EditScreen extends ConsumerWidget {
  final int initialTab;

  const EditScreen({super.key, this.initialTab = 0});

  final List<String> _tabs = const ['친구', '1:1채팅', '그룹채팅'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editScreenControllerProvider(initialTab));
    final controller = ref.read(editScreenControllerProvider(initialTab).notifier);

    Widget buildPill(int index) {
      final bool isSelected = state.selectedTab == index;
      return GestureDetector(
        onTap: () => controller.setTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.transparent : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Text(
            _tabs[index],
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: kIsWeb,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: ColorsManager.primary,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Pills row ────────────────────────────────────────────────────
              Container(
                color: ColorsManager.primary,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Padding(
                        padding: EdgeInsets.only(right: 10.w),
                        child: Icon(
                          Icons.arrow_back,
                          size: 22.sp,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (int i = 0; i < _tabs.length; i++) ...[
                              buildPill(i),
                              if (i < _tabs.length - 1) SizedBox(width: 8.w),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
  
              // ── Search bar ───────────────────────────────────────────────────
              Container(
                color: ColorsManager.primary,
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
                child: Container(
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: TextField(
                    controller: controller.searchController,
                    style: TextStyle(fontSize: 14.sp, color: Colors.black),
                    decoration: InputDecoration(
                      hintText:
                          state.selectedTab == 0
                              ? '이름(초성), 전화번호 검색'
                              : state.selectedTab == 1
                              ? '1:1채팅 검색'
                              : '그룹채팅 검색',
                      hintStyle: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.grey[400],
                      ),
                      border: InputBorder.none,
                      prefixIcon: Icon(
                        Icons.search,
                        size: 20.sp,
                        color: Colors.grey[400],
                      ),
                      suffixIcon:
                          state.query.isNotEmpty
                              ? GestureDetector(
                                onTap: controller.clearSearch,
                                child: Icon(
                                  Icons.close,
                                  size: 18.sp,
                                  color: Colors.grey[400],
                                ),
                              )
                              : null,
                      contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                      isDense: true,
                    ),
                    onChanged: (val) => controller.setQuery(val.toLowerCase().trim()),
                  ),
                ),
              ),
  
              // ── Divider ──────────────────────────────────────────────────────
              Container(color: Colors.grey[300], height: 1),
  
              // ── Tab content ──────────────────────────────────────────────────
              Expanded(
                child: ColoredBox(
                  color: ColorsManager.primary,
                  child: IndexedStack(
                    index: state.selectedTab,
                    children: const [
                      EditContactsTab(),
                      EditDirectChatsTab(),
                      EditGroupChatsTab(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
