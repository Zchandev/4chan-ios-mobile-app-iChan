import 'package:flutter/cupertino.dart';
import 'package:flutter_html/html_parser.dart';
import 'package:ichan/services/exports.dart';
import 'package:ichan/services/my.dart' as my;

import 'thread.dart';

typedef ReplyCallback = void Function(BuildContext, {ThreadLink threadLink});
typedef LinkCallback = void Function();

class PostBody extends StatelessWidget {
  const PostBody({
    Key key,
    @required this.body,
    @required this.thread,
    this.replyCallback,
    this.padding,
  }) : super(key: key);

  final String body;
  final Thread thread;
  final ReplyCallback replyCallback;
  final EdgeInsets padding;

  Future<void> youtubeLink(BuildContext context, String url) async {
    const actions = [
      ActionSheet(text: 'Picture in picture', value: 'pip'),
      ActionSheet(text: 'Open in Youtube', value: 'app'),
      ActionSheet(text: 'Open in browser', value: 'safari'),
    ];

    final result = await Interactive(context).modal(actions);
    if (result == "pip") {
      my.playerBloc.add(PlayerYoutubeLinkPressed(url: url));
    } else if (result == 'app') {
      if (await canLaunch(url)) {
        await launch(url, forceSafariVC: false);
      }
    } else {
      System.launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
      child: DefaultTextStyle(
        style: TextStyle(
          inherit: true,
          height: 1.25,
          letterSpacing: -0.1,
          fontWeight: my.prefs.fontWeight,
        ),
        child: Html(
          data: body,
          onLinkTap: (url, data) {
            // print('url = $url');
            if (replyCallback == null) {
              return;
            }

            if (url.contains('youtube') || url.contains('youtu.be')) {
              youtubeLink(context, url);
              return;
            }

            final isPostLink = data['class'] == 'post-reply-link';

            final fav = my.favs.get(thread.toKey) as ThreadStorage;
            final isFavorite = fav?.isFavorite == true;

            if (isPostLink) {
              final boardName = data['href'].split('/')[1];
              final threadLink = ThreadLink(
                postId: data['data-num'] ?? '',
                threadId: data['data-thread'],
                threadTitle: data['data-thread'],
                boardName: boardName,
                platform: thread.platform,
              );

              if (data['data-thread'] != thread.outerId &&
                  isFavorite &&
                  (bodyContainsWords() || isTripleLink(threadLink))) {
                maybeReplaceFav(context, threadLink);
              } else {
                replyCallback(context, threadLink: threadLink);
              }
              return;
            }

            final isFourchanPostLink = url.startsWith('#p');
            if (isFourchanPostLink) {
              final postId = url.replaceFirst('#p', '');
              final threadLink = ThreadLink(
                postId: postId,
                threadId: thread.outerId,
                threadTitle: thread.title,
                boardName: thread.boardName,
                platform: thread.platform,
              );

              replyCallback(context, threadLink: threadLink);
            }

            final threadLink = urlToThreadLink(url);

            if (threadLink != null) {
              if (isFavorite && (isTripleLink(threadLink) || bodyContainsWords())) {
                maybeReplaceFav(context, threadLink);
              } else {
                if (threadLink.threadId == thread.outerId) {
                  replyCallback(context, threadLink: threadLink);
                } else {
                  Routz.of(context).toThread(threadLink: threadLink);
                }
              }
              return;
            }

            final fourchanThreadLink = fourchanUrlToThreadLink(url);

            if (fourchanThreadLink != null) {
              if (isFavorite && (isTripleLink(fourchanThreadLink) || bodyContainsWords())) {
                maybeReplaceFav(context, fourchanThreadLink);
              } else {
                if (fourchanThreadLink.threadId == thread.outerId) {
                  replyCallback(context, threadLink: fourchanThreadLink);
                } else {
                  Routz.of(context).toThread(threadLink: fourchanThreadLink);
                }
              }
              return;
            }

            final archiveThreadLink = urlToArchiveThreadLink(url);

            if (archiveThreadLink != null) {
              Routz.of(context).toThread(threadLink: archiveThreadLink);
              return;
            }

            final board = urlToBoardLink(url);
            if (board != null) {
              Routz.of(context).toBoard(board);
              return;
            }

            if (url.endsWith('catalog.html')) {
              final board = url.split('/')[1];
              final query = data['title'];
              Routz.of(context).toBoard(Board(board, platform: thread.platform), query: query);
              return;
            }

            if (url.startsWith('http')) {
              System.launchUrl(url);
            }
          },
          style: {
            'body': Style(
              fontSize: FontSize(my.prefs.postFontSize),
              fontWeight: my.prefs.fontWeight, // do not remove
              margin: EdgeInsets.zero,
              padding: padding,
              color: my.theme.fontColor,
            ),
            "html": Style(
              fontSize: FontSize(my.prefs.postFontSize),
            ),
            "a": Style(
              color: my.theme.linkColor,
              fontWeight: my.prefs.fontWeight, // do not remove
              textDecoration: TextDecoration.none,
            ),
            'p': Style(
              margin: const EdgeInsets.only(bottom: 10.0),
            ),
            "i": Style(fontStyle: FontStyle.italic),
          },
          customRender: {
            "thread": (context, child, attr, element) {
              double height = thread.isTitleInBody ? 115.0 : 80.0;
              if (Consts.isIpad) {
                height += 30;
              }

              return Container(
                height: height,
                child: Text(element.text,
                    overflow: TextOverflow.fade,
                    style: TextStyle(
                      fontSize: my.prefs.postFontSize,
                      color: my.theme.fontColor,
                    )),
              );
            },
            "catalogThread": (context, child, attr, element) {
              double height = thread.isTitleInBody ? 115.0 : 80.0;
              if (Consts.isIpad) {
                height += 30;
              }

              return Container(
                height: height,
                child: Text(element.text,
                    overflow: TextOverflow.fade,
                    style: TextStyle(
                      fontSize: my.prefs.postFontSize,
                      color: my.theme.fontColor,
                    )),
              );
            },
            "span": (RenderContext context, Widget child, attributes, element) {
              switch (attributes['class']) {
                case 'unkfunc':
                  return Text(
                    element.text,
                    style: TextStyle(
                      color: my.theme.quoteColor,
                      fontSize: my.prefs.postFontSize,
                      fontWeight: my.prefs.fontWeight, // do not remove
                    ),
                  );
                case 'quote':
                  return Text(
                    element.text,
                    style: TextStyle(
                      color: my.theme.quoteColor,
                      fontSize: my.prefs.postFontSize,
                      fontWeight: my.prefs.fontWeight, // do not remove
                    ),
                  );
                case 'spoiler':
                  // return PostBody(
                  //   body: element.innerHtml,
                  //   thread: thread,
                  //   replyCallback: replyCallback,
                  //   backgroundColor: my.theme.spoilerBackgroundColor,
                  // );
                  return Text(
                    element.text,
                    style: TextStyle(
                      color: my.theme.fontColor,
                      backgroundColor: my.theme.spoilerBackgroundColor,
                      fontSize: my.prefs.postFontSize,
                      fontWeight: my.prefs.fontWeight, // do not remove
                    ),
                  );
                case 's':
                  return Text(
                    element.text,
                    style: TextStyle(
                      // color: my.theme.fontColor,
                      color: my.theme.fontColor, // do not remove
                      decoration: TextDecoration.lineThrough,
                      fontSize: my.prefs.postFontSize,
                      fontWeight: my.prefs.fontWeight,
                    ),
                  );
                case 'u':
                  return Text(
                    element.text,
                    style: TextStyle(
                      color: my.theme.fontColor, // do not remove
                      decoration: TextDecoration.underline,
                      fontSize: my.prefs.postFontSize,
                      fontWeight: my.prefs.fontWeight,
                    ),
                  );
                case 'o':
                  return Text(
                    element.text,
                    style: TextStyle(
                      color: my.theme.fontColor, // do not remove
                      decoration: TextDecoration.overline,
                      fontSize: my.prefs.postFontSize,
                      fontWeight: my.prefs.fontWeight,
                    ),
                  );
                default:
                  // print(
                  // "WAS NOT FOUND ELEMENT WITH CLASS: ${attributes['class']} AND TEXT ${element.text}");
                  return Text(
                    element.text,
                    style: TextStyle(
                      color: my.theme.fontColor,
                      fontSize: my.prefs.postFontSize,
                      fontWeight: my.prefs.fontWeight, // do not remove
                    ),
                  );
              }
            },
          },

          // css: ".post-reply-link { color: orange; }",
        ),
      ),
    );
  }

  bool isTripleLink(ThreadLink threadLink) {
    final count1 = 'data-thread="${threadLink.outerId}"'.allMatches(body).length;
    final count2 = '${threadLink.outerId}.html</a>'.allMatches(body).length;
    return count1 >= 4 || count2 >= 3;
  }

  bool bodyContainsWords() {
    final _body = body.toLowerCase();
    return RegExp(r'(?:^|<br>|\s|\>)(перекат|перекот|новый тред)(?:.+|$|\<)').hasMatch(_body);
  }

  // todo: fix platform
  ThreadLink urlToThreadLink(String url) {
    try {
      final matches = RegExp(r"https?://2ch.+/([A-Za-z]+)/res/(\d+)\.html#?(\d+){0,1}")
          .allMatches(url)
          .toList()[0];

      final postId = matches.groupCount == 3 ? matches[3] : '';

      return ThreadLink(
        boardName: matches[1],
        threadId: matches[2],
        threadTitle: matches[2],
        postId: postId ?? '',
        platform: Platform.dvach,
      );
    } catch (e) {
      return null;
    }
  }

  ThreadLink fourchanUrlToThreadLink(String url) {
    try {
      final matches = RegExp(r"/([a-z]+)/thread/(\d+)#p(\d+)").allMatches(url).toList()[0];

      final postId = matches.groupCount == 3 ? matches[3] : '';

      return ThreadLink(
        boardName: matches[1],
        threadId: matches[2],
        threadTitle: matches[2],
        postId: postId ?? '',
        platform: Platform.fourchan,
      );
    } catch (e) {
      return null;
    }
  }

  // todo: fix platform
  ThreadLink urlToArchiveThreadLink(String url) {
    try {
      final matches = RegExp(r"https?://2ch.+/([A-Za-z]+)/arch/(.+)/res/(\d+)\.html#?(\d+){0,1}")
          .allMatches(url)
          .toList()[0];

      final postId = matches.groupCount == 4 ? matches[4] : '';

      return ThreadLink(
        boardName: matches[1],
        threadId: matches[3],
        threadTitle: matches[3],
        archiveDate: matches[2],
        postId: postId ?? '',
        platform: Platform.dvach,
      );
    } catch (e) {
      return null;
    }
  }

  Board urlToBoardLink(String url) {
    try {
      final matches = RegExp(r"https?://2ch.{1,5}/([a-zA-Z]{1,5})/?$").firstMatch(url)[1];

      return Board(matches, platform: thread.platform);
    } catch (e) {
      return null;
    }
  }

  Future<void> maybeReplaceFav(BuildContext context, ThreadLink threadLink) async {
    final actualData = my.threadBloc.getThreadData(thread.toKey);

    final fav = actualData.threadStorage;
    final newThreadFav = ThreadStorage.findById(threadLink.toKey);
    if (fav.isFavorite && (newThreadFav.isEmpty || !newThreadFav.isFavorite)) {
      final result = await Interactive(context).alert(const [
        ActionSheet(text: 'Replace', value: 'replace', color: CupertinoColors.activeGreen),
        ActionSheet(text: 'Just open', value: 'open')
      ], title: 'Replace favorite thread?');

      if (result == 'replace') {
        final existingNew = ThreadStorage.find(
          boardName: threadLink.boardName,
          platform: threadLink.platform,
          threadId: threadLink.outerId,
        );

        if (existingNew.isEmpty) {
          final newFav = ThreadStorage(
            platform: threadLink.platform,
            boardName: threadLink.boardName,
            threadId: threadLink.outerId,
            threadTitle: "${fav.threadTitle} (NEW)",
            isFavorite: true,
            visits: fav.visits,
          );
          newFav.putOrSave();
        } else {
          existingNew.isFavorite = true;
          existingNew.visits = fav.visits;
          existingNew.save();
        }
        fav.isFavorite = false;
        fav.save();
        my.favoriteBloc.favoriteUpdated();
      }
    }

    Routz.of(context).toThread(threadLink: threadLink);
  }
}
