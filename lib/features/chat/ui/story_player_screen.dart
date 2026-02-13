import 'dart:async';
import 'package:ecommerece_app/features/chat/models/story_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class StoryPlayerScreen extends StatefulWidget {
  final UserStoryGroup group;

  const StoryPlayerScreen({super.key, required this.group});

  @override
  State<StoryPlayerScreen> createState() => _StoryPlayerScreenState();
}

class _StoryPlayerScreenState extends State<StoryPlayerScreen> {
  int _currentIndex = 0;
  double _percent = 0.0;
  Timer? _timer;
  late PageController _pageController;
  bool _isPaused = false;
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_isExiting || _isPaused) {
        return;
      }
      setState(() {
        if (_percent < 1.0) {
          _percent += 0.01; // Adjust speed here (5 seconds total)
        } else {
          _timer?.cancel();
          _nextStory();
        }
      });
    });
  }

  bool _isExiting = false;

  void _nextStory() {
    if (_isExiting) return;
    if (_currentIndex < widget.group.stories.length - 1) {
      setState(() {
        _currentIndex++;
        _percent = 0.0;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startTimer();
    } else {
      _handleExit();
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _percent = 0.0;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startTimer();
    }
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  void _handleExit() {
    if (_isExiting || !mounted) return;

    _isExiting = true;
    _timer?.cancel();
    Navigator.of(context).pop();
  }

  Future<void> _deleteStory() async {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("Delete Story"),
            content: const Text("Are you sure you want to delete this story?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  // TODO: Implement delete logic in StoryService
                  // await StoryService().deleteStory(
                  //   widget.group.stories[_currentIndex].storyId,
                  // );
                  Navigator.pop(ctx);
                  _handleExit();
                },
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool _isMyStory = (currentUser?.uid == widget.group.authorId);

    final currentStory = widget.group.stories[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. The Story Image/Content
          PageView.builder(
            controller: _pageController,
            physics:
                const NeverScrollableScrollPhysics(), // Managed by timer/taps
            itemCount: widget.group.stories.length,
            itemBuilder: (context, index) {
              return Image.network(
                widget.group.stories[index].imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              );
            },
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: Row(
                    children:
                        widget.group.stories.asMap().entries.map((entry) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: LinearProgressIndicator(
                                value:
                                    entry.key == _currentIndex
                                        ? _percent
                                        : (entry.key < _currentIndex
                                            ? 1.0
                                            : 0.0),
                                backgroundColor: Colors.white24,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                                minHeight: 2,
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(widget.group.authorImage),
                  ),
                  title: Text(
                    widget.group.authorName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(child: GestureDetector(onTap: _previousStory)),
              Expanded(
                child: GestureDetector(
                  onLongPressStart: (details) => _togglePause(),
                  onLongPressEnd: (details) => _togglePause(),
                ),
              ),
              Expanded(child: GestureDetector(onTap: _nextStory)),
            ],
          ),
          if (!_isMyStory)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 10,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white54),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const TextField(
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: '메시지 보내기', // "Send Message"
                          hintStyle: TextStyle(color: Colors.white60),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  const Icon(Icons.send, color: Colors.white),
                ],
              ),
            ),
          if (_isMyStory)
            Positioned(
              bottom: 10,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: _deleteStory,
              ),
            ),
        ],
      ),
    );
  }
}
