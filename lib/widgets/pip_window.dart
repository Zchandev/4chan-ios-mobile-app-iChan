import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ichan/blocs/player_bloc.dart';
import 'package:ichan/services/exports.dart';
import 'package:ichan/widgets/youtube_player_widget.dart';
import 'package:ichan/services/my.dart' as my;

class PipWindow extends StatefulWidget {
  const PipWindow({Key key}) : super(key: key);

  @override
  _PipWindowState createState() => _PipWindowState();
}

class _PipWindowState extends State<PipWindow> {
  @override
  Widget build(BuildContext context) {
    final position = ValueNotifier<Map>({'top': 0.0, 'bottom': null});

    return BlocBuilder<PlayerBloc, PlayerState>(
      // buildWhen: (previous, current) => current is PlayerYoutubeStart,
      builder: (context, state) {
        if (state is PlayerYoutubeActive && state?.url != null) {
          // if (my.prefs.getBool('disable_autoturn')) {
          System.setAutoturn('auto');
          // }

          return ValueListenableBuilder(
              valueListenable: position,
              builder: (context, val, snapshot) {
                return Positioned(
                  top: position.value['top'],
                  bottom: position.value['bottom'],
                  child: SafeArea(
                    top: true,
                    bottom: true,
                    child: Stack(
                      children: [
                        Hero(
                          tag: "pip",
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onVerticalDragEnd: (details) {
                              if (details.primaryVelocity.abs() >=
                                  Consts.verticalGestureVelocity / 2) {
                                if (details.primaryVelocity > 0) {
                                  position.value = {'top': null, 'bottom': 0.0};
                                } else {
                                  position.value = {'top': 0.0, 'bottom': null};
                                }
                              }
                            },
                            child: YoutubePlayerWidget(url: state.url),
                          ),
                        ),
                        Container(
                          alignment: Alignment.topLeft,
                          height: 30,
                          width: 30,
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () {
                              my.playerBloc.add(const PlayerYoutubeClosed());
                            },
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.all(5.0),
                              child: const Icon(FontAwesomeIcons.times,
                                  size: 15, color: CupertinoColors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              });
        }

        // if empty state
        return Container();
      },
    );
  }
}
