import 'dart:io';
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
  bool _playVideo = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.game.videoUrl!))..setLooping(true);

    if (widget.settings.muteVideo) {
      _controller.setVolume(0.0);
    }

    if (widget.settings.fadeToVideo) {
      _controller.initialize();
      Future.delayed(const Duration(seconds: 2), () async {
        if (mounted && _controller.value.isInitialized) {
          setState(() {
            _playVideo = true;
          });
          _controller.play();
        }
      });
    } else {
      _playVideo = true;
      _controller.initialize().then((value) {
        if (mounted) {
          _controller.play();
          // force aspect ratio
          setState(() {
            _playVideo = true;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FocusDetector(
      onFocusLost: () {
        debugPrint('Focus lost');
        if (mounted) {
          _controller.dispose();
          setState(() {
            _playVideo = false;
          });
        }
      },
      child: _buildVideoPlayer(),
    );
  }

  Widget _buildVideoPlayer() {
    if (_playVideo) {
      return AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: VideoPlayer(_controller),
      );
    } else {
      return Image.file(
        File(widget.game.imageUrl!),
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      );
    }
  }
}
