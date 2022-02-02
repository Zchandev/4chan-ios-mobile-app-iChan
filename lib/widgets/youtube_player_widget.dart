import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class YoutubePlayerWidget extends StatefulWidget {
  const YoutubePlayerWidget({Key key, this.url}) : super(key: key);

  final String url;

  @override
  _YoutubePlayerWidgetState createState() => _YoutubePlayerWidgetState();
}

class _YoutubePlayerWidgetState extends State<YoutubePlayerWidget>
    with WidgetsBindingObserver {
  YoutubePlayerController playerController;

  void initState() {
    final videoId = YoutubePlayer.convertUrlToId(widget.url);
    // WidgetsBinding.instance.addObserver(this);
    playerController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        forceHD: true,
      ),
    );
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // print("Player ${widget.url} disposing...");
    // playerController?.dispose();
    // chewieController?.dispose();
    super.dispose();
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
    // if (state == AppLifecycleState.resumed) {
    //   playerController.play();
    // } else {
    //   playerController.pause();
    // }
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayer(
      controller: playerController,
      showVideoProgressIndicator: true,
      // progressColors: ProgressBarColors(
      //   backgroundColor: CupertinoColors.destructiveRed,
      //   playedColor: CupertinoColors.destructiveRed,
      //   bufferedColor: CupertinoColors.destructiveRed,
      //   handleColor: CupertinoColors.destructiveRed,
      // ),
      // progressIndicatorColor: CupertinoColors.destructiveRed,
      bottomActions: [
        CurrentPosition(),
        ProgressBar(isExpanded: true),
        FullScreenButton(),
      ],
    );
  }
}
