import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
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
        _controller.play();
        setState(() {});
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
      _controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.settings.fadeToVideo) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _showImage
            ? Image.file(
                File(widget.game.imageUrl!),
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                key: const ValueKey<int>(1),
              )
            : _controller.value.isInitialized
                ? AspectRatio(
                    key: const ValueKey<int>(2),
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  )
                : const Center(child: CircularProgressIndicator()),
      );
    } else {
      return _controller.value.isInitialized
          ? AspectRatio(
              key: const ValueKey<int>(2),
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            )
          : const Center(child: CircularProgressIndicator());
    }
  }
}
