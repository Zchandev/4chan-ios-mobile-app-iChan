import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_statusbar_manager/flutter_statusbar_manager.dart';
import 'package:ichan/blocs/thread/barrel.dart';
import 'package:ichan/models/media.dart';
import 'package:ichan/pages/gallery_page.dart';
import 'package:ichan/pages/thread/thread.dart';
import 'package:flutter/cupertino.dart';
import 'package:ichan/services/exports.dart';
import 'package:ichan/ui/haptic.dart';
import 'package:ichan/services/my.dart' as my;
import 'package:ichan/widgets/media/media_actions.dart';
import 'package:ichan/widgets/media/media_info.dart';
import 'package:ichan/widgets/media/zoomable_image.dart';
import 'package:ichan/widgets/my/my_dismissible.dart';
import 'package:ichan/widgets/native_player_widget.dart';
import 'package:ichan/widgets/webm_player_widget.dart';

class GalleryItemPage extends StatefulWidget {
  const GalleryItemPage({
    Key key,
    @required this.mediaList,
    @required this.media,
    this.thread,
    this.origin,
  }) : super(key: key);

  static String routeName = "/gallery_item";

  final Media media;
  final Origin origin;
  final Thread thread;
  final List<Media> mediaList;

  @override
  _GalleryItemPageState createState() => _GalleryItemPageState();
}

class _GalleryItemPageState extends State<GalleryItemPage> with MediaActions {
  final currentIndex = ValueNotifier<int>(0);
  final showButtons = ValueNotifier<bool>(true);
  PageController pageController;
  Media currentMedia;
  // Widget nextImage;
  // Widget nextImage2;

  bool bottomSwipeEnabled = false;

  // STATE MODES
  // dark / light mode switch
  bool lightOn = false;

  // top menu
  bool isMenuVisible = true;

  // show/hide buttons
  // bool showButtons = true;

  // need to resume playing in dissmissible
  bool toResume = false;

  // when image has been saved
  bool justSaved = false;

  // metadata params
  bool showMetadata = false;
  bool metadataDisplay = true;
  double metadataOpacity = 0.0;

  ThreadData get threadData => my.threadBloc.getThreadData(widget.thread.toKey);
  Post get post => threadData.posts.firstWhere((e) => e.outerId == currentMedia.postId);

  Widget build(BuildContext context) {
    my.prefs.incrStats('media_views');

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        slidePageWidget(
          enabled: !my.prefs.getBool("disable_media_swipe"),
          child: ExtendedImageGesturePageView.builder(
            controller: pageController,
            scrollDirection: Axis.horizontal,
            onPageChanged: (index) {
              currentIndex.value = index;
              toResume = false;

              my.prefs.incrStats('media_views');

              // check video and stop it
              final media = widget.mediaList.elementAtOrNull(index);
              if (media != null && media.isVideo) {
                my.playerBloc.add(PlayerChange(media: media));
              }

              if (!my.prefs.getBool('image_preload_disabled')) {
                preloadNextItem(index - 1);
                preloadNextItem(index + 1);
                preloadNextItem(index + 2);
              }

              if (showMetadata) {
                metadataOpacity = 0.0;
                metadataDisplay = false;
                setState(() {});
                currentMedia = media;
                // print('media.path = ${media.path}');
                setState(() {
                  metadataDisplay = true;
                  metadataOpacity = 1.0;
                });
              }
            },
            itemCount: widget.mediaList.length,
            itemBuilder: (context, pos) {
              currentMedia = widget.mediaList[pos];
              return WillPopScope(
                onWillPop: () async {
                  showMenuBar();

                  closeEvent(context);

                  return true;
                },
                child: GestureDetector(
                    onLongPress: () {
                      if (currentMedia.isVideo) {
                        showVideoPopup(context, currentMedia);
                      } else {
                        showImagePopup(context, currentMedia);
                      }
                    },
                    child: galleryContent()),
              );
            },
          ),
        ),
        // ],
        currentMediaIndex(),
        totalMediaCount(),

        if (widget.origin != Origin.board) ...[
          metadataItem(),
          ValueListenableBuilder<bool>(
            valueListenable: showButtons,
            builder: (context, val, widget) {
              return Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onVerticalDragEnd: (details) {
                    if (details.primaryVelocity <= -1 * Consts.verticalGestureVelocity) {
                      toggleMetadata();
                    } else if (details.primaryVelocity >= Consts.verticalGestureVelocity) {
                      showMenuBar();
                      Navigator.pop(context);
                    }
                  },
                  child: Container(height: (showMetadata || !val || !bottomSwipeEnabled) ? 0 : 120),
                ),
              );
            },
          )
        ],
        if (widget.origin != Origin.board) ...[
          Positioned(left: 25, bottom: 25, child: galleryIcon()),
          Positioned(right: 25, bottom: 25, child: infoIcon()),
        ],
      ],
    );
  }

  void backWithoutGallery() {
    if (my.prefs.getBool("disable_media_swipe")) {
      return Navigator.pop(context);
    }
    return Navigator.pop(context, true);
  }

  void toggleMetadata() {
    setState(() {
      if (showMetadata == false) {
        metadataOpacity = 1.0;
        metadataDisplay = true;
        showMetadata = true;
      } else {
        metadataOpacity = 0.0;
        showMetadata = false;
      }
    });
  }

  Widget infoIcon() {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (showButtons.value && currentMedia.isImage) {
          toggleMetadata();
        }
      },
      child: ValueListenableBuilder(
        valueListenable: showButtons,
        builder: (context, val, widget) {
          return AnimatedOpacity(
            opacity: showButtons.value ? 1.0 : 0.0,
            duration: 0.3.seconds,
            child: Container(
                margin: const EdgeInsets.all(10.0),
                padding: const EdgeInsets.all(5.0),
                decoration: BoxDecoration(
                  color: my.theme.backgroundColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: FaIcon(
                  showMetadata ? FontAwesomeIcons.times : FontAwesomeIcons.infoCircle,
                  color: CupertinoColors.white.withOpacity(0.6),
                  size: 20,
                )),
          );
        },
      ),
    );
  }

  Widget galleryIcon() {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (!showButtons.value) {
          return;
        }
        showMenuBar();
        // if (widget.origin == Origin.gallery) {
        //   return Navigator.pop(context);
        // }

        final scrollIndex = widget.mediaList.indexOf(currentMedia);

        Routz.of(context).fadeToPage(
          GalleryPage(
            threadData: threadData,
            scrollIndex: scrollIndex,
          ),
          replace: true,
          settings: const RouteSettings(
            name: GalleryPage.routeName,
          ),
        );
      },
      child: ValueListenableBuilder(
        valueListenable: showButtons,
        builder: (context, val, widget) {
          return AnimatedOpacity(
            opacity: showButtons.value ? 1.0 : 0.0,
            duration: 0.3.seconds,
            child: Container(
                margin: const EdgeInsets.all(10.0),
                padding: const EdgeInsets.all(5.0),
                decoration: BoxDecoration(
                  color: my.theme.backgroundColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: FaIcon(
                  FontAwesomeIcons.images,
                  color: CupertinoColors.white.withOpacity(0.6),
                  size: 20,
                )),
          );
        },
      ),
    );
  }

  Positioned totalMediaCount() {
    return Positioned(
      right: 25,
      top: 0,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          if (!showButtons.value) {
            return;
          }
          showMenuBar();
          // Navigator.of(context).pop();
          return backWithoutGallery();
        },
        child: ValueListenableBuilder(
            valueListenable: showButtons,
            builder: (context, val, _) {
              return AnimatedOpacity(
                opacity: showButtons.value ? 1.0 : 0.0,
                duration: 0.3.seconds,
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Text(
                    "${widget.mediaList.length}",
                    style: TextStyle(
                        fontSize: 14,
                        color: lightOn ? Colors.black : Colors.white,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              );
            }),
      ),
    );
  }

  Positioned currentMediaIndex() {
    return Positioned(
      left: 25,
      top: 0,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          if (!showButtons.value) {
            return;
          }
          setState(() {
            lightOn = !lightOn;
          });
        },
        child: ValueListenableBuilder(
          valueListenable: showButtons,
          builder: (context, val, widget) {
            return AnimatedOpacity(
              opacity: showButtons.value ? 1.0 : 0.0,
              duration: 0.3.seconds,
              child: ValueListenableBuilder(
                valueListenable: currentIndex,
                builder: (context, value, child) {
                  return Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Text("${currentIndex.value + 1}",
                        style: TextStyle(
                          color: lightOn ? Colors.black : Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        )),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget galleryContent() {
    final color = my.prefs.getBool("disable_media_swipe") ? Colors.black : Colors.transparent;

    final container = Container(
      height: context.screenHeight,
      width: context.screenWidth,
      color: lightOn ? Colors.white : color,
      child: extBasedContent(currentMedia),
    );

    return AnimatedSwitcher(
      duration: 0.5.seconds,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeOut,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      child: showMetadata ? postItem() : container,
    );
  }

  Widget metadataItem() {
    final future = showMetadata ? currentMedia.readExif() : null;
    final _height = context.screenHeight;

    return AnimatedPositioned(
      top: showMetadata ? _height / 3 : _height,
      duration: 0.25.seconds,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity >= Consts.verticalGestureVelocity) {
            setState(() {
              showMetadata = false;
            });
          }
        },
        child: Container(
          height: _height,
          color: my.theme.backgroundMenuColor,
          padding: EdgeInsets.only(bottom: _height - _height * 2 / 3),
          width: context.screenWidth,
          child: AnimatedOpacity(
            opacity: metadataOpacity,
            duration: metadataDisplay ? 0.5.seconds : 0.0001.seconds,
            child: MediaInfo(
              key: UniqueKey(),
              media: currentMedia,
              onOverscroll: () {
                setState(() {
                  showMetadata = false;
                });
              },
              future: future,
            ),
          ),
        ),
      ),
    );
  }

  Widget postItem() {
    return Container(
      key: ValueKey(post.outerId),
      height: context.screenHeight / 3,
      color: my.theme.backgroundMenuColor,
      padding: const EdgeInsets.only(top: 50.0),
      child: SingleChildScrollView(
        child: PostItem(
          threadData: threadData,
          post: post,
          highlightMedia: currentMedia,
          origin: Origin.mediaInfo,
        ),
      ),
    );
  }

  Widget extBasedContent(Media media) {
    Widget result;

    if (media.isVideo) {
      // final player = NativePlayerWidget(key: Key("mp4-${media.url}"), media: media);
      final player = (media.ext == 'webm' && isIos)
          ? WebmPlayerWidget(key: Key("webm-${media.url}"), media: media)
          : NativePlayerWidget(key: Key("mp4-${media.url}"), media: media);

      result = MyDismissible(
        key: UniqueKey(),
        direction: DismissDirection.vertical,
        movementDuration: const Duration(milliseconds: 500),
        resizeDuration: const Duration(microseconds: 1),
        child: player,
        onDragStart: () {
          my.playerBloc.add(PlayerStop(media: media));
          return true;
        },
        onDragEnd: () {
          // print("Drag end");
          toResume = true;
          resumeLater(my.playerBloc, media);
          return true;
        },
        onDismissed: (direction) {
          toResume = false;
          closeEvent(context);

          // print("Just pop");
          Navigator.pop(context);
        },
      );
    } else {
      result = ZoomableImage(key: UniqueKey(), media: media);
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (currentMedia.isVideo) {
          return;
        }
        // print('showButtons.value = ${showButtons.value}');
        showButtons.value = !showButtons.value;
      },
      child: Stack(
        alignment: Alignment.center,
        fit: StackFit.expand,
        children: [
          result,
          AnimatedOpacity(
            opacity: justSaved ? 1.0 : 1.0,
            duration: 0.3.seconds,
            child: Offstage(
              offstage: !justSaved,
              child: Align(
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.all(15.0),
                  decoration: BoxDecoration(
                    color: my.theme.backgroundColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.fileDownload,
                    color: CupertinoColors.white,
                    size: 50,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget slidePageWidget({Widget child, bool enabled}) {
    if (!enabled) {
      return child;
    }
    final duration = (my.prefs.getBool('swipe_up_opens_gallery')) ? Duration.zero : 0.25.seconds;

    return ExtendedImageSlidePage(
      slideAxis: SlideAxis.vertical,
      slideType: SlideType.wholePage,
      slidePageBackgroundHandler: (offset, pageSize) => defaultSlidePageBackgroundHandler(
          offset: offset,
          pageSize: pageSize,
          color: CupertinoColors.black.withOpacity(0.5),
          pageGestureAxis: SlideAxis.vertical),
      resetPageDuration: duration,
      slideEndHandler: (offset, {details, state}) {
        bool result = true;
        final minDistance = Consts.isIpad ? 10.0 : 20.0;

        // Log.warn("Dx is ${offset.dx}, dy is ${offset.dy}");

        if (offset.dy >= minDistance) {
          result = true;
        } else if (offset.dy <= -1 * minDistance) {
          if (my.prefs.getBool('swipe_up_opens_gallery')) {
            showMenuBar();

            if (widget.origin != Origin.board) {
              final scrollIndex = widget.mediaList.indexOf(currentMedia);

              Routz.of(context).fadeToPage(
                GalleryPage(
                  threadData: threadData,
                  scrollIndex: scrollIndex,
                ),
                replace: true,
              );
              return false;
            } else {
              result = true;
            }
          }
        }

        if (offset.dy.abs() <= minDistance) {
          result = false;
        }

        if (result == false) {
          hideMenuBar();
          return false;
        }

        closeEvent(context);

        return true;
      },
      child: child,
    );
  }

  @override
  void initState() {
    hideMenuBar(delayed: my.contextTools.hasHomeButton);

    if (my.prefs.getBool('disable_autoturn')) {
      System.setAutoturn('auto');
    }

    if (my.prefs.getBool('swipe_bottom_for_info')) {
      bottomSwipeEnabled = true;
    }

    final index = widget.mediaList.indexWhere((e) => e.url == widget.media.url);
    if (index == -1) {
      print("widget.mediaList = ${widget.mediaList}");
    }
    assert(index != -1);

    currentIndex.value = index;
    currentMedia = widget.mediaList[index];
    pageController = PageController(initialPage: index, keepPage: true);

    if (!isIos) {
      my.playerBloc.add(PlayerChange(media: widget.media));
    }

    preloadNextItem(index - 1);
    preloadNextItem(index + 1);
    preloadNextItem(index + 2);

    super.initState();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  Future<void> resumeLater(PlayerBloc playerBloc, Media media) async {
    await Future.delayed(300.milliseconds);
    if (toResume) {
      playerBloc.add(PlayerResume(media: media));
    }
  }

  void closeEvent(BuildContext context) {
    my.playerBloc.add(const PlayerClose());

    // print("widget.origin = ${widget.origin}");

    if (my.prefs.getBool('scroll_to_post')) {
      if (widget.origin == Origin.gallery ||
          (widget.origin == Origin.thread && widget.media.url != currentMedia.url)) {
        print("true");
        scrollToPost(context);
      }
    }

    if (my.prefs.getBool('disable_autoturn')) {
      System.setAutoturn('portrait');
    }

    showMenuBar();
  }

  void hideMenuBar({bool delayed = false}) async {
    if (!isMenuVisible) {
      return;
    }

    FlutterStatusbarManager.setHidden(true, animation: StatusBarAnimation.FADE);
    isMenuVisible = false;
  }

  void showMenuBar() async {
    if (isMenuVisible || widget.origin == Origin.mediaInfo) {
      return;
    }

    FlutterStatusbarManager.setHidden(false, animation: StatusBarAnimation.FADE);
    isMenuVisible = true;
  }

  void scrollToPost(BuildContext context) {
    if (currentMedia?.postId == null) {
      return;
    }
    showMenuBar();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      my.threadBloc.add(ThreadScrollStarted(postId: currentMedia.postId, thread: widget.thread));
    });
  }

  Future<void> showVideoPopup(BuildContext context, Media media) async {
    final actionSheets = [
      if (!isIos || media.ext != 'webm') ...[
        const ActionSheet(text: "Save"),
      ],
      const ActionSheet(text: "Go to post"),
      const ActionSheet(text: "Share")
    ];

    final result = await Interactive(context).modal(actionSheets);
    if (result == "save") {
      try {
        final result = await saveMedia(media);
        showSaveResult(result);
      } catch (e) {
        print("SAVING ERROR");
        Interactive(context).message(title: "Error", content: e.toString());
      }
    } else if (result == "go to post") {
      Haptic.mediumImpact();
      Routz.of(context).backToThread();
      scrollToPost(context);
    } else if (result == "share") {
      try {
        return await shareMedia(media);
      } catch (e) {
        Interactive(context).message(title: "Error", content: e.toString());
      }
    }
  }

  Future<void> showImagePopup(BuildContext context, Media media) async {
    final sheet = [
      const ActionSheet(
        text: "Save",
      ),
      const ActionSheet(
        text: "Share",
      ),
      if ([Origin.thread, Origin.gallery, Origin.reply].contains(widget.origin)) ...[
        const ActionSheet(
          text: "Go to post",
        )
      ],
      const ActionSheet(
        text: "Find",
      ),
    ];

    final result = await Interactive(context).modal(sheet);

    if (result == "share") {
      try {
        await shareMedia(media);
      } catch (e) {
        Interactive(context).message(title: "Error", content: e.toString());
      }
    } else if (result == "save") {
      final result = await saveMedia(media);
      showSaveResult(result);
    } else if (result == "find") {
      final findSheet = [
        const ActionSheet(
          text: "Find in Google",
        ),
        const ActionSheet(
          text: "Find in Yandex",
        ),
      ];

      final findResult = await Interactive(context).modal(findSheet);
      if (findResult == "find in google") {
        final url = "https://www.google.com/searchbyimage?&image_url=${media.url}";
        System.launchUrl(url);
      } else if (findResult == "find in yandex") {
        final url = "https://yandex.ru/images/search?url=${media.url}&rpt=imageview";
        System.launchUrl(url);
      }
    } else if (result == "go to post") {
      Haptic.mediumImpact();
      Routz.of(context).backToThread();
      scrollToPost(context);
    }

    return;
  }

  void showSaveResult(bool result) {
    if (result == true) {
      setState(() {
        justSaved = true;
        Future.delayed(1.0.seconds).then((value) {
          setState(() {
            justSaved = false;
          });
        });
      });
    }
  }

  void preloadNextItem(int index) {
    if (index < 0) {
      return;
    }

    final media = widget.mediaList.elementAtOrNull(index);
    if (media != null) {
      if (media.isVideo) {
        return preloadNextItem(index + 1);
      }
      try {
        my.cacheManager
            .getSingleFile(media.url, headers: System.headersForPath(media.path))
            .then((value) {
          media.isCached = true;
        });
      } catch (e) {
        print("ERROR PRELOADING IMAGE ${media.url}");
      }
    }
    return;
  }
}
