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
  double _imageOpacity = 1.0;
  double _videoOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.gameToShow.videoUrl!))
      ..setLooping(true)
      ..setVolume(widget.settings.muteVideo ? 0 : 1);

    if (widget.settings.fadeToVideo) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _fadeImageOut();
        }
      });
    } else {
      _controller.initialize().then((_) {
        if (mounted) {
          //setState(() {});
          _controller.play();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _fadeImageOut() {
    _controller.initialize().then((_) {});
    setState(() {
      _imageOpacity = 0.0;
      _videoOpacity = 1.0;
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _controller.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.settings.fadeToVideo) {
      return Stack(
        children: <Widget>[
          AnimatedOpacity(
            opacity: _videoOpacity,
            duration: const Duration(milliseconds: 1000),
            child: _videoWidget(),
          ),
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: _imageOpacity,
              duration: const Duration(milliseconds: 1000),
              child: Image.file(
                File(widget.gameToShow.imageUrl!),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      );
    } else {
      return _videoWidget();
    }
  }

  Widget _videoWidget() {
    return _controller.value.isInitialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          )
        : const Center(child: CircularProgressIndicator());
  }
}
