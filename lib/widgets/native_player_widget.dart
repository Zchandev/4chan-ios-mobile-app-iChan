import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:ichan/blocs/player_bloc.dart';
import 'package:ichan/models/media.dart';
import 'package:ichan/services/exports.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NativePlayerWidget extends StatefulWidget {
  const NativePlayerWidget({Key key, this.media}) : super(key: key);

  final Media media;

  @override
  _NativePlayerWidgetState createState() => _NativePlayerWidgetState();
}

class _NativePlayerWidgetState extends State<NativePlayerWidget> with WidgetsBindingObserver {
  VideoPlayerController playerController;
  ChewieController chewieController;
  Future<void> _future;
  bool soundAutoplayFix = false;

  String get url => widget.media.url;

  void initState() {
    soundAutoplayFix = !isIos;

    WidgetsBinding.instance.addObserver(this);
    playerController = VideoPlayerController.network(url);
    _future = playerController.initialize();

    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    print("Player $url disposing...");

    super.dispose();
    playerController?.dispose();
    chewieController?.dispose();
  }

  @override
  void deactivate() {
    print("DEACTIVATE");
    // WidgetsBinding.instance.removeObserver(this);
    // playerController?.pause();
    super.deactivate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      playerController.play();
    } else {
      playerController.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PlayerBloc, PlayerState>(
      listener: (context, state) {
        if (state is PlayerLoaded) {
          if (state.media.url != url) {
            // print("mp4 player pause");
            playerController?.pause();
          } else {
            // print("mp4 player back");
            playerController?.play();
          }
        } else if (state is PlayerStopped && state.media.url == url) {
          // print("mp4 player stopped");
          playerController?.pause();
        } else if (state is PlayerResumed && state.media.url == url) {
          // print("mp4 player resumed");
          playerController?.play();
        } else if (state is PlayerClosed) {
          playerController.pause();

          print("Close $url");
        }
      },
      child: Center(
        child: FutureBuilder(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              chewieController = ChewieController(
                videoPlayerController: playerController,
                aspectRatio: playerController.value.aspectRatio,
                autoPlay: !soundAutoplayFix,
                looping: true,
              );

              return AspectRatio(
                aspectRatio: playerController.value.aspectRatio,
                child: Chewie(
                  key: const ValueKey('native'),
                  controller: chewieController,
                ),
              );
            }
            return const CupertinoActivityIndicator();
          },
        ),
      ),
    );
  }
}
