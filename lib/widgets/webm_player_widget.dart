import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ichan/blocs/player_bloc.dart';

import 'package:ichan/models/media.dart';
import 'package:ichan/services/extensions.dart';

import 'package:flutter_vlc_player/flutter_vlc_player.dart';
// class WebmPlayerWidget extends StatelessWidget {
//   const WebmPlayerWidget({key, this.media}) : super(key: key);

//   final Media media;

//   @override
//   Widget build(BuildContext context) {
//     // TODO: implement build
//     return Container();
//   }
// }

class WebmPlayerWidget extends StatefulWidget {
  const WebmPlayerWidget({Key key, this.media}) : super(key: key);

  final Media media;

  @override
  WebmPlayerState createState() => WebmPlayerState();
}

class WebmPlayerState extends State<WebmPlayerWidget> with WidgetsBindingObserver {
  VlcPlayerController playerController;
  double sliderValue = 0.0;

  String get url => widget.media.url;

  @override
  void dispose() {
    print("DISPOSE");
    WidgetsBinding.instance.removeObserver(this);
    // timer.cancel();
    // playerController = null;
    super.dispose();
    print('state is  = ${playerController.playingState}');
    playerController?.dispose();
  }

  @override
  void deactivate() {
    print("DEACTIVATE");
    // WidgetsBinding.instance.removeObserver(this);
    playerController?.pause();
    super.deactivate();
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);

    print("initState: getting webm");
    playerController = VlcPlayerController(onInit: () {
      playerController.play();
    });

    // playerController.addListener(() {
    //   print("Yes, state is ${playerController.playingState}");
    // });

    // timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
    //   if (mounted) {
    //     if (playerController.playingState == null) {
    //       playerController.setStreamUrl(widget.url);
    //     }
    //     setState(() {
    //       print(
    //           'playerController.playingState = ${playerController.playingState}');
    //       if (playerController.playingState == PlayingState.PLAYING &&
    //           sliderValue < playerController.duration.inSeconds) {
    //         sliderValue = playerController.position.inSeconds.toDouble();
    //       }
    //     });
    //   }
    // });

    // playerController.addListener(() {
    // print("Yes, state is ${playerController.playingState}");
    // });
    super.initState();
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
              // print("Putting pause");
              playerController?.pause();
            } else {
              // print("Playing back");
              playerController?.play();
            }
          } else if (state is PlayerStopped && state.media.url == url) {
            // print("Player stopped");
            playerController?.pause();
          } else if (state is PlayerResumed && state.media.url == url) {
            // print("Player resumed");
            playerController?.play();
          } else if (state is PlayerClosed) {
            // print("Player closed");
            playerController?.stop();
          }
        },
        child: SizedBox(
          width: context.screenWidth,
          height: context.screenHeight,
          // child: playerContainer,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              VlcPlayer(
                key: const ValueKey('vlc'),
                aspectRatio: widget.media.ratio,
                url: url,
                controller: playerController,
                options: const [
                  '--quiet',
                  '--no-drop-late-frames',
                  '--no-skip-frames',
                  '--rtsp-tcp'
                ],
                hwAcc: HwAcc.AUTO,
                placeholder: Container(
                  height: 250.0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const <Widget>[CupertinoActivityIndicator()],
                  ),
                ),
              ),
              // Material(
              //   child: Slider(
              //     activeColor: Colors.white,
              //     value: sliderValue,
              //     min: 0.0,
              //     max: playerController.duration == null
              //         ? 1.0
              //         : playerController.duration.inSeconds.toDouble(),
              //     onChanged: (progress) {
              //       setState(() {
              //         sliderValue = progress.floor().toDouble();
              //       });
              //       //convert to Milliseconds since VLC requires MS to set time
              //       playerController.setTime(sliderValue.toInt() * 1000);
              //     },
              //   ),
              // ),
              // GestureDetector(
              //   onTap: () {
              //     print("State is ${playerController.playingState}");
              //     if (playerController.playingState == PlayingState.PLAYING) {
              //       playerController?.pause();
              //     } else {
              //       playerController?.play();
              //     }
              //     setState(() {});
              //   },
              //   child: Container(
              //     alignment: Alignment.centerLeft,
              //     padding: const EdgeInsets.only(left: 15.0, top: 5.0),
              //     child: Icon(
              //       playerController.playingState != PlayingState.PLAYING
              //           ? OpenIconicIcons.mediaPause
              //           : OpenIconicIcons.mediaPlay,
              //       color: Colors.white,
              //       size: 20.0,
              //     ),
              //   ),
              // ),
            ],
          ),
        ));
  }
}
