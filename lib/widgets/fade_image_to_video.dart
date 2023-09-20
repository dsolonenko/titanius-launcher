import 'dart:io';
import 'dart:math';
import 'package:fade_indexed_stack/fade_indexed_stack.dart';
import 'package:flutter/material.dart';
import 'package:focus_detector_v2/focus_detector_v2.dart';
import 'package:video_player/video_player.dart';

import 'package:titanius/data/models.dart';
import 'package:titanius/data/repo.dart';

class FadeImageToVideo extends StatefulWidget {
  final Game game;
  final Settings settings;

  const FadeImageToVideo({super.key, required this.game, required this.settings});

  @override
  FadeImageToVideoState createState() => FadeImageToVideoState();
}

class FadeImageToVideoState extends State<FadeImageToVideo> {
  late VideoPlayerController _controller;
  bool _showImage = true;
  bool _lostFocus = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.game.videoUrl!))..setLooping(true);

    if (widget.settings.muteVideo) {
      _controller.setVolume(0.0);
    }

    if (widget.settings.fadeToVideo) {
      Future.delayed(const Duration(seconds: 2), () async {
        if (mounted) {
          await _fadeImageOut();
        }
      });
    } else {
      _controller.initialize().then((value) {
        if (mounted && !_lostFocus) {
          _controller.play();
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fadeImageOut() async {
    // Start measuring the time.
    final startTime = DateTime.now();

    // Initialize the controller if it's not already initialized.
    await _controller.initialize().catchError((err) {
      debugPrint(err.toString());
    });

    // Calculate the remaining time for the fade-out animation.
    final elapsedTime = DateTime.now().difference(startTime);
    final remainingTime = max(0, 500 - elapsedTime.inMilliseconds);

    // Update the state and start the fade-out animation.
    setState(() {
      _showImage = false;
    });

    // Start playing the video after the remaining fade-out time.
    Future.delayed(Duration(milliseconds: remainingTime), () {
      if (mounted && !_lostFocus) {
        _controller.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FocusDetector(
      onFocusLost: () {
        debugPrint('Focus lost');
        if (mounted) {
          _controller.pause();
          setState(() {
            _lostFocus = true;
          });
        }
      },
      onFocusGained: () {
        debugPrint('Focus gained');
        if (mounted) {
          if (_controller.value.isInitialized) {
            _controller.play();
          }
          setState(() {
            _lostFocus = false;
          });
        }
      },
      child: _buildVideoPlayer(),
    );
  }

  Widget _buildVideoPlayer() {
    if (_lostFocus) {
      return Image.file(
        File(widget.game.imageUrl!),
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      );
    } else if (widget.settings.fadeToVideo) {
      return FadeIndexedStack(
        duration: const Duration(milliseconds: 100),
        index: _showImage ? 0 : 1,
        sizing: StackFit.expand,
        children: [
          Image.file(
            File(widget.game.imageUrl!),
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
        ],
      );
    } else {
      return _controller.value.isInitialized
          ? AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            )
          : const Center(child: CircularProgressIndicator());
    }
  }
}
