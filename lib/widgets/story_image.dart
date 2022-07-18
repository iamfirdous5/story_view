import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../utils.dart';
import '../controller/story_controller.dart';

/// Utitlity to load image (gif, png, jpg, etc) media just once. Resource is
/// cached to disk with default configurations of [DefaultCacheManager].
class ImageLoader {
  String url;
  LoadState state = LoadState.loading; // by default
  Image? networkImage;
  BoxFit? fit;
  ImageLoader(this.url, {this.fit});

  /// Load image from disk cache first, if not found then load from network.
  /// `onComplete` is called when [imageBytes] become available.
  void loadImage(VoidCallback onComplete) {
    networkImage = Image.network(url, fit: fit);
    final onResult = (LoadState state) {
      if (this.state != LoadState.loading) {
        onComplete();
        return;
      }
      this.state = state;
      onComplete();
    };
    networkImage?.image.resolve(ImageConfiguration()).addListener(
          ImageStreamListener(
            (_, __) => onResult(LoadState.success),
            onError: (_, __) => onResult(LoadState.failure),
          ),
        );
  }
}

/// Widget to display animated gifs or still images. Shows a loader while image
/// is being loaded. Listens to playback states from [controller] to pause and
/// forward animated media.
class StoryImage extends StatefulWidget {
  final ImageLoader imageLoader;

  final BoxFit? fit;

  final StoryController? controller;

  final String url;

  StoryImage(
    this.imageLoader,
    this.url, {
    Key? key,
    this.controller,
    this.fit,
  }) : super(key: key ?? UniqueKey());

  /// Use this shorthand to fetch images/gifs from the provided [url]
  factory StoryImage.url(
    String url, {
    StoryController? controller,
    Map<String, dynamic>? requestHeaders,
    BoxFit fit = BoxFit.fitWidth,
    Key? key,
  }) {
    return StoryImage(
      ImageLoader(url, fit: fit),
      url,
      controller: controller,
      fit: fit,
      key: key,
    );
  }

  @override
  State<StatefulWidget> createState() => StoryImageState();
}

class StoryImageState extends State<StoryImage> {
  ui.Image? currentFrame;

  Timer? _timer;

  StreamSubscription<PlaybackState>? _streamSubscription;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      this._streamSubscription =
          widget.controller!.playbackNotifier.listen((playbackState) {
        if (playbackState == PlaybackState.pause) {
          this._timer?.cancel();
        } else {
          setState(() {});
        }
      });
    }
    widget.controller?.pause();
    widget.imageLoader.loadImage(() async {
      if (mounted) {
        if (widget.imageLoader.state == LoadState.success) {
          widget.controller?.play();
          setState(() {});
        } else {
          // refresh to show error
          setState(() {});
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _streamSubscription?.cancel();

    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  Widget getContentView() {
    final fail = Center(
      child: Text('Image failed to load.', style: TextStyle(color: Colors.white)),
    );
    switch (widget.imageLoader.state) {
      case LoadState.success:
        return widget.imageLoader.networkImage ?? fail;
      case LoadState.failure:
        return fail;
      default:
        return Center(
          child: Container(
            width: 70,
            height: 70,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: getContentView(),
    );
  }
}
