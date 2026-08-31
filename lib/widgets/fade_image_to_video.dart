import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:focus_detector_v2/focus_detector_v2.dart';
import 'package:video_player/video_player.dart';

import 'package:titanius/data/models.dart';

typedef VideoPlaybackSettings = ({bool fadeToVideo, bool muteVideo});

class FadeImageToVideo extends StatefulWidget {
  final Game game;
  final VideoPlaybackSettings settings;

  const FadeImageToVideo({
    super.key,
    required this.game,
    required this.settings,
  });

  @override
  FadeImageToVideoState createState() => FadeImageToVideoState();
}

class FadeImageToVideoState extends State<FadeImageToVideo> {
  VideoPlayerController? _controller;
  Timer? _initializeTimer;
  Timer? _fadeTimer;
  bool _playVideo = false;
  bool _inFocus = true;

  @override
  void initState() {
    super.initState();
    _scheduleInitialize();
  }

  @override
  void didUpdateWidget(covariant FadeImageToVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game.absoluteRomPath != widget.game.absoluteRomPath ||
        oldWidget.game.videoUrl != widget.game.videoUrl ||
        oldWidget.settings.muteVideo != widget.settings.muteVideo ||
        oldWidget.settings.fadeToVideo != widget.settings.fadeToVideo) {
      _resetVideo();
    }
  }

  void _resetVideo() {
    _initializeTimer?.cancel();
    _fadeTimer?.cancel();
    _playVideo = false;
    _disposeCurrentController();
    _scheduleInitialize();
  }

  void _disposeCurrentController() {
    final controller = _controller;
    _controller = null;
    if (controller != null) unawaited(controller.dispose());
  }

  void _scheduleInitialize() {
    _initializeTimer?.cancel();
    _initializeTimer = Timer(
      const Duration(milliseconds: 400),
      _initializeVideo,
    );
  }

  Future<void> _initializeVideo() async {
    if (!mounted || !_inFocus) return;
    final controller = VideoPlayerController.file(File(widget.game.videoUrl!))
      ..setLooping(true);
    _controller = controller;

    if (widget.settings.muteVideo) {
      controller.setVolume(0.0);
    }
    try {
      await controller.initialize();
    } catch (error) {
      if (identical(controller, _controller)) {
        _controller = null;
        await controller.dispose();
      }
      debugPrint('Unable to initialize video ${widget.game.videoUrl}: $error');
      return;
    }
    if (!mounted || controller != _controller) return;
    if (widget.settings.fadeToVideo) {
      _fadeTimer = Timer(const Duration(seconds: 2), () {
        if (_inFocus && mounted && controller.value.isInitialized) {
          setState(() {
            _playVideo = true;
          });
          controller.play();
        }
      });
    } else {
      _playVideo = true;
      if (_inFocus) {
        setState(() => _playVideo = true);
        controller.play();
      }
    }
  }

  @override
  void dispose() {
    _initializeTimer?.cancel();
    _fadeTimer?.cancel();
    _disposeCurrentController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FocusDetector(
      onFocusGained: () {
        if (mounted) {
          if (_controller == null) _scheduleInitialize();
          setState(() {
            _inFocus = true;
            if (_controller?.value.isInitialized ?? false) {
              _playVideo = true;
              _controller?.play();
            }
          });
        }
      },
      onFocusLost: () {
        if (mounted) {
          if (_controller?.value.isInitialized ?? false) {
            _controller?.pause();
          }
          setState(() {
            _inFocus = false;
            _playVideo = false;
          });
        }
      },
      child: _buildVideoPlayer(),
    );
  }

  Widget _buildVideoPlayer() {
    final controller = _controller;
    if (_playVideo &&
        _inFocus &&
        controller != null &&
        controller.value.isInitialized) {
      // This widget normally sits inside an Expanded panel, whose tight
      // constraints would force a bare AspectRatio to fill both dimensions.
      // Center loosens the child constraints so videos letterbox just like the
      // screenshot's BoxFit.contain path instead of stretching to the panel.
      return Center(
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),
      );
    } else {
      return widget.game.imageUrl == null
          ? const SizedBox.shrink()
          : Image.file(
              File(widget.game.imageUrl!),
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none,
            );
    }
  }
}
