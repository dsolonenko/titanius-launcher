import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../data/models.dart';
import '../data/settings.dart';

class FadeImageToVideo extends StatefulWidget {
  final Game gameToShow;
  final Settings settings;

  const FadeImageToVideo({super.key, required this.gameToShow, required this.settings});

  @override
  FadeImageToVideoState createState() => FadeImageToVideoState();
}

class FadeImageToVideoState extends State<FadeImageToVideo> {
  late VideoPlayerController _controller;
  double _opacity = 1.0;
  double _reverseOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.gameToShow.videoUrl!))
      ..setLooping(true)
      ..setVolume(widget.settings.muteVideo ? 0 : 1);

    if (widget.settings.fadeToVideo) {
      _controller.initialize().then((_) {});
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _fadeImageOut();
        }
      });
    } else {
      _controller.initialize().then((_) {
        setState(() {});
        _controller.play();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _fadeImageOut() {
    setState(() {
      _opacity = 0.0;
      _reverseOpacity = 1.0;
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      _controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.settings.fadeToVideo) {
      return Stack(
        children: <Widget>[
          Positioned.fill(
              child: AnimatedOpacity(
            opacity: _reverseOpacity,
            duration: const Duration(milliseconds: 500),
            child: _controller.value.isInitialized
                ? AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  )
                : const Center(child: CircularProgressIndicator()),
          )),
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: _opacity,
              duration: const Duration(milliseconds: 500),
              child: Image.file(
                File(widget.gameToShow.imageUrl!),
                fit: BoxFit.contain,
              ),
            ),
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
