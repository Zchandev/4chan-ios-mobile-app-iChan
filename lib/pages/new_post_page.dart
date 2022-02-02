import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ichan/blocs/blocs.dart';
import 'package:ichan/blocs/thread/data.dart';
import 'package:ichan/models/models.dart';
import 'package:ichan/models/thread_storage.dart';
import 'package:ichan/pages/reply/fourchan_captcha.dart';
import 'package:ichan/pages/reply/reply.dart';
import 'package:ichan/services/exports.dart';
import 'package:ichan/services/file_tools.dart';
import 'package:ichan/ui/haptic.dart';
import 'package:ichan/services/my.dart' as my;
import 'package:ichan/widgets/media/rounded_image.dart';
import 'package:ichan/widgets/media/zoomable_image.dart';

class FormUI {
  FormUI({
    this.state,
    this.thread,
    this.board,
    this.isSage = false,
    this.isOp = false,
    this.isName = false,
    this.autosageOn = true,
    this.name = '',
    this.postTitle = '',
    this.postBody = '',
    this.fillingCaptcha = false,
    this.isExpanded = false,
  }) : loadedAt = DateTime.now().millisecondsSinceEpoch;

  final Board board;
  final Thread thread;
  PostState state;
  String name;
  String postTitle;
  String postBody;
  bool isSage;
  bool isOp;
  bool fillingCaptcha;
  bool isName;
  bool autosageOn;
  bool isExpanded;
  int loadedAt;

  ThreadData get current => my.threadBloc.getThreadData(thread.toKey);
  ThreadStorage get fav => current?.threadStorage ?? my.favs.get(thread.toKey);
  Platform get platform => board?.platform ?? thread.platform;

  void readDefaults() {
    if (isNewThread) {
      postTitle = my.prefs.getString('thread_title');
      postBody = my.prefs.getString('thread_body');
    } else {
      assert(thread != null);

      if (fav?.extras['op'] != null) {
        isOp = fav.extras['op'];
      } else {
        if (fav.opCookie.isNotEmpty) {
          isOp = true;
        }
      }

      if (fav.extras['name'] != null && fav.extras['name'].isNotEmpty) {
        name = fav.extras['name'];
        isName = true;
      }

      if (fav.extras['sage'] != null) {
        isSage = fav.extras['sage'];
      }

      if (fav.extras['body'] != null) {
        postBody = fav.extras['body'];
      }
    }
  }

  void savePostText(String text) {
    // print("Saved body: $text");
    fav.extras['body'] = text;
    fav.putOrSave();
  }

  void saveThreadText(String title, String body) {
    my.prefs.put('thread_title', title);
    my.prefs.put('thread_body', body);
    // print("Saved thread");
  }

  void updateDefaults() {
    if (!isNewThread && fav?.isNotEmpty == true) {
      fav.extras['op'] = isOp;
      fav.extras['sage'] = isSage;
      fav.extras['name'] = name;
      fav.putOrSave();
    }
  }

  bool get titleEnabled => board.id != 'b';
  bool get passcodeEnabled => platform == Platform.dvach
      ? my.prefs.getBool('passcode_enabled')
      : my.prefs.getBool('fourchan_passcode_enabled');

  bool get isNewThread => board != null;
  bool get showImages => !(state.files == null || state.files.isEmpty || (fillingCaptcha == true));

  String get threadOrBoardText {
    return isNewThread ? "Create thread in /${board.id}/" : thread.titleOrBody;
  }

  String get navbarText {
    if (state is PostCreating) {
      return "Upload: ${(state.percent * 100).round()}%";
    } else {
      return threadOrBoardText;
    }
  }

  String get submitButtonCaption {
    if (state is PostCreating) {
      return "Cancel";
    } else if (isOp) {
      return "OP";
    } else if (isSage) {
      return "SAGE";
    } else {
      return "Send";
    }
  }
}

class NewPostPage extends StatefulWidget {
  const NewPostPage({this.thread, this.board});
  final Thread thread;
  final Board board;

  NewPostPageState createState() => NewPostPageState();
}

class NewPostPageState extends State<NewPostPage> with WidgetsBindingObserver {
  final postBodyController = TextEditingController();
  final titleController = TextEditingController();
  final nameController = TextEditingController();
  String captchaResponse;
  DvachCaptchaPage dvachCaptcha;
  FourchanCaptchaPage fourchanCaptcha;
  final isCaptchaVisible = ValueNotifier<bool>(false);
  FormUI form;
  bool displayCaptcha = my.prefs.showCaptcha;

  void captchaClickCallback() {
    setState(() {
      if (form.fillingCaptcha == false) {
        FocusScope.of(context).unfocus();
        form.fillingCaptcha = true;
      }
    });
  }

  void captchaSolvedCallback() {
    setState(() {
      if (form.fillingCaptcha) {
        form.fillingCaptcha = false;
      }
    });
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    form = FormUI(
      state: PostEmpty(),
      board: widget.board,
      thread: widget.thread,
      isExpanded: my.prefs.getBool("form_expanded"),
    );
    if (form.platform == Platform.fourchan) {
      displayCaptcha = true;
    }
    form.readDefaults();

    nameController.text = form.name;
    postBodyController.text = form.postBody;
    titleController.text = form.postTitle;

    postBodyController.addListener(() {
      if (form.isSage || !form.autosageOn || form.platform == Platform.fourchan) {
        return;
      }

      if (postBodyController.text
          .toLowerCase()
          .contains(RegExp(r'(?:^|\s)(sage|саж[а,и,у])\s{1}'))) {
        // print("Contains, text is $postBodyController.text");
        setState(() {
          form.isSage = true;
        });
      }
    });

    if (displayCaptcha) {
      if (form.platform == Platform.dvach) {
        dvachCaptcha = DvachCaptchaPage(
          captchaClickCallback: captchaClickCallback,
          captchaSolvedCallback: captchaSolvedCallback,
          isCaptchaVisible: isCaptchaVisible,
        );
      } else if (form.platform == Platform.fourchan) {
        fourchanCaptcha = FourchanCaptchaPage(
          captchaClickCallback: captchaClickCallback,
          captchaSolvedCallback: captchaSolvedCallback,
          isCaptchaVisible: isCaptchaVisible,
        );
      }
    }
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    saveText();
    my.postBloc.add(CreateCancel());
    postBodyController.dispose();
    titleController.dispose();
    nameController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      saveText();
    }
  }

  void saveText() {
    if (form.isNewThread) {
      form.saveThreadText(titleController.text, postBodyController.text);
    } else {
      form.savePostText(postBodyController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    _showHelp(context);

    return BlocConsumer<PostBloc, PostState>(
      listener: (context, state) {
        if (state is PostCreated) {
          titleController.clear();
          postBodyController.clear();
          if (my.prefs.getBool('back_to_thread_disabled')) {
            Navigator.pop(context, true);
          } else {
            Routz(context).backToThread();
          }
        } else if (state is ThreadCreated) {
          titleController.clear();
          postBodyController.clear();
          // my.prefs.put('thread_title', '');
          // my.prefs.put('thread_body', '');

          Routz.of(context).toThread(threadLink: state.threadLink, replace: true);
        }
        if (state is PostError) {
          final String errorMessage =
              (state is PostError) ? (state.message ?? "Unknown error") : "";

          if (displayCaptcha) {
            setState(() {
              isCaptchaVisible.value = !isCaptchaVisible.value;
              form.fillingCaptcha = false;
            });
          }

          Interactive(context).alert(const [ActionSheet(text: "OK")], content: errorMessage);
        }
      },
      builder: (context, state) {
        // print("NewPostPage state is $state");
        form.state = state;

        final submitPressed = () {
          Haptic.mediumImpact();
          if (state is PostCreating) {
            if (my.makabaApi.domain.endsWith('2ch.pm')) {
              Interactive(context).message(content: "Please change 2ch.pm to 2ch.hk");
            } else {
              my.postBloc.add(CreateCancel());
            }
          } else {
            FocusScope.of(context).unfocus();
            if (form.isNewThread) {
              submitThread(form.board);
            } else {
              submitPost(form.thread);
            }
          }
        };

        final menuButton = GestureDetector(
          onTap: () {
            showMenuPressed(context);
          },
          behavior: HitTestBehavior.translucent,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: FaIcon(FontAwesomeIcons.cog,
                size: 21,
                color: my.contextTools.isVerySmallHeight
                    ? my.theme.primaryColor
                    : my.theme.navbarFontColor),
          ),
        );

        final postIconButton = GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => submitPressed(),
            child:
                Text(form.submitButtonCaption, style: TextStyle(color: my.theme.navbarFontColor)));

        final formChildren = [
          Container(
            padding: const EdgeInsets.only(bottom: 5.0),
            child: LinearProgressIndicator(
              value: state is PostCreating ? state.percent : 0.0,
              backgroundColor: my.theme.backgroundColor,
              valueColor: AlwaysStoppedAnimation<Color>(
                my.theme.progressBarColor,
              ),
            ),
          ),
          Form(
            key: const ValueKey("form"),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Consts.sidePadding),
              child: Wrap(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onVerticalDragEnd: (details) {
                      if (details.primaryVelocity <= -1 * Consts.backGestureVelocity) {
                        FocusScope.of(context).unfocus();
                      }
                    },
                    child: Column(
                      children: <Widget>[
                        if (!form.fillingCaptcha) ...[
                          if (!form.isExpanded) ...[
                            FormMoveableButtons(
                              controller: postBodyController,
                              position: "top",
                            )
                          ],
                          if (form.isNewThread && form.titleEnabled) ...[
                            FormTextField(
                              controller: titleController,
                              placeholder: "Title",
                            ),
                          ],
                          if (form.isName) ...[
                            FormTextField(
                              controller: nameController,
                              placeholder: "Name",
                            ),
                          ],
                          Stack(
                            alignment: Alignment.topRight,
                            children: [
                              FormTextArea(
                                controller: postBodyController,
                                form: form,
                              ),
                              GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onTap: () {
                                  setState(() {
                                    form.isExpanded = !form.isExpanded;
                                    my.prefs.put("form_expanded", form.isExpanded);
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: 10.0, left: 10.0, top: 5, right: 5),
                                  child: FaIcon(
                                      form.isExpanded
                                          ? FontAwesomeIcons.minus
                                          : FontAwesomeIcons.plus,
                                      size: 10,
                                      color: my.theme.inactiveColor.withOpacity(0.5)),
                                ),
                              ),
                            ],
                          ),
                          if (!form.isExpanded) ...[
                            FormMoveableButtons(
                              controller: postBodyController,
                              position: "bottom",
                            )
                          ],
                        ],
                        Padding(
                          padding: EdgeInsets.only(
                              top: my.contextTools.isVerySmallHeight ? 0.0 : 5.0,
                              bottom: my.contextTools.isVerySmallHeight && form.fillingCaptcha
                                  ? 15.0
                                  : 0.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (form.fillingCaptcha)
                                Expanded(
                                    child: GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTap: () {
                                    setState(() {
                                      isCaptchaVisible.value = !isCaptchaVisible.value;
                                      form.fillingCaptcha = false;
                                    });
                                  },
                                  child: Center(
                                    child: Text(
                                      "Cancel",
                                      style: TextStyle(color: my.theme.alertColor),
                                    ),
                                  ),
                                ))
                              else if (!form.isExpanded)
                                FormAttachmentButtons(thread: form.thread),
                              if (my.contextTools.isVerySmallHeight && !form.isExpanded)
                                menuButton
                              else if (!form.isExpanded || form.fillingCaptcha)
                                SendButton(submitPressed: submitPressed, form: form, state: state),
                            ],
                          ),
                        ),
                        if (form.showImages && !form.isExpanded) ...[
                          FormAttachments(files: state.files)
                        ],
                      ],
                    ),
                  ),
                  if (displayCaptcha) ...[dvachCaptcha ?? fourchanCaptcha ?? Container()],
                ],
              ),
            ),
          ),
        ];

        return HeaderNavbar(
          child: Stack(
            children: [
              if (isIos) ...[
                Wrap(children: formChildren),
              ],
              if (!isIos) ...[
                ListView(
                  shrinkWrap: true,
                  children: formChildren,
                ),
              ],
            ],
          ),
          previousPageTitle: "",
          middle: Text(
            form.navbarText,
            softWrap: false,
            overflow: TextOverflow.fade,
            style: TextStyle(color: my.theme.navbarFontColor),
          ),
          trailing: Padding(
            padding: const EdgeInsets.only(left: 15.0),
            child: my.contextTools.isVerySmallHeight || (form.isExpanded && !form.fillingCaptcha)
                ? postIconButton
                : menuButton,
          ),
        );

        // }
      },
    );
  }

  void showMenuPressed(BuildContext context) async {
    final list = form.platform == Platform.dvach ? ['SAGE', 'OP', 'Name'] : ['Name'];
    Interactive(context).modalList(list).then((result) {
      if (result == 'sage') {
        if (form.isSage) {
          form.autosageOn = false;
        }
        form.isSage = !form.isSage;

        setState(() {});
      } else if (result == 'op') {
        form.isOp = !form.isOp;
        setState(() {});
      } else if (result == 'name') {
        setState(() {
          form.isName = !form.isName;
        });
      }
      form.updateDefaults();
    });
  }

  void submitPost(Thread thread) {
    assert(thread != null);

    final Map<String, dynamic> payload = {
      "body": postBodyController.text,
      "threadId": thread.outerId,
      "boardName": thread.boardName,
      "platform": thread.platform,
      "name": form.isName ? nameController.text : '',
      "isSage": form.isSage,
      "isOp": form.isOp,
      "form": form,
    };

    if (displayCaptcha) {
      if (form.platform == Platform.dvach) {
        dvachCaptcha.getCaptchaResponse().then((catchaResponse) {
          payload['captcha-key'] = Consts.recaptchaKey;
          payload['g-recaptcha-response'] = catchaResponse;
          my.postBloc.add(CreatePost(payload));
        });
      }
      if (form.platform == Platform.fourchan) {
        fourchanCaptcha.getCaptchaResponse().then((catchaResponse) {
          payload['captcha-key'] = Consts.recaptchaKey;
          payload['g-recaptcha-response'] = catchaResponse;
          my.postBloc.add(CreatePost(payload));
        });
      }
    } else {
      my.postBloc.add(CreatePost(payload));
    }

    if (form.isName) {
      form.name = nameController.text;
      form.updateDefaults();
    }
  }

  void submitThread(Board board) {
    assert(board != null);

    final Map<String, dynamic> payload = {
      "title": titleController.text,
      "body": postBodyController.text,
      "name": form.isName ? nameController.text : '',
      "platform": board.platform,
      "boardName": form.board.id,
      "isSage": form.isSage,
      "isOp": form.isOp,
      "form": form,
    };

    if (displayCaptcha) {
      if (form.platform == Platform.dvach) {
        dvachCaptcha.getCaptchaResponse().then((catchaResponse) {
          payload['captcha-key'] = Consts.recaptchaKey;
          payload['g-recaptcha-response'] = catchaResponse;
          my.postBloc.add(CreateThread(payload));
        });
      }
      if (form.platform == Platform.fourchan) {
        fourchanCaptcha.getCaptchaResponse().then((catchaResponse) {
          payload['captcha-key'] = Consts.recaptchaKey;
          payload['g-recaptcha-response'] = catchaResponse;
          my.postBloc.add(CreateThread(payload));
        });
      }
    } else {
      my.postBloc.add(CreateThread(payload));
    }

    if (form.isName) {
      form.name = nameController.text;
      form.updateDefaults();
    }
  }

  void _showHelp(BuildContext context) {
    if (my.prefs.getBool('help.post_form')) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Interactive(context).message(title: 'help.tip'.tr(), content: 'help.post_form'.tr());
      my.prefs.put('help.post_form', true);
    });
  }
}

class SendButton extends StatefulWidget {
  const SendButton({
    Key key,
    @required this.submitPressed,
    @required this.form,
    @required this.state,
  }) : super(key: key);

  final Function submitPressed;
  final FormUI form;
  final PostState state;

  @override
  _SendButtonState createState() => _SendButtonState();
}

class _SendButtonState extends State<SendButton> {
  int lastPostTimestamp = 0;
  int timeDiff = 0;
  int cooldown;

  @override
  void initState() {
    cooldown = widget.form.platform == Platform.dvach ? 15 : 60;
    lastPostTimestamp = my.prefs.getInt("last_post_ts");
    startCounter();
    super.initState();
  }

  void startCounter() {
    timeDiff = lastPostTimestamp.timeDiffInSeconds;

    if (timeDiff <= cooldown) {
      Future.delayed(1.seconds).then((value) {
        setState(() {});
        startCounter();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      onPressed: () => widget.submitPressed(),
      color: submitButtonColor,
      child: Text(
        submitButtonCaption,
        style: TextStyle(color: my.theme.buttonTextColor, fontWeight: FontWeight.w600),
      ),
    );
  }

  Color get submitButtonColor {
    if (widget.state is PostCreating || timeDiff < cooldown) {
      return my.theme.inactiveColor;
    } else if (widget.form.isSage) {
      return my.theme.alertColor;
    } else if (widget.form.isOp) {
      return my.theme.quoteColor;
    } else {
      return my.theme.primaryColor;
    }
  }

  String get submitButtonCaption {
    if (widget.state is PostCreating) {
      return "Cancel";
    } else if (timeDiff < cooldown) {
      return "${cooldown - timeDiff}";
    } else if (widget.form.isOp) {
      return "OP";
    } else if (widget.form.isSage) {
      return "SAGE";
    } else {
      return "Send";
    }
  }
}

class FormAttachments extends StatelessWidget {
  const FormAttachments({Key key, this.files}) : super(key: key);

  final List<File> files;

  @override
  Widget build(BuildContext context) {
    final imgHeight = my.contextTools.isSmallWidth ? 70.0 : 100.0;

    return Container(
      key: const ValueKey("images-list"),
      height: imgHeight,
      width: double.infinity,
      child: ListView.builder(
          padding: const EdgeInsets.only(left: 5.0),
          scrollDirection: Axis.horizontal,
          itemCount: files == null ? 0 : files.length,
          itemBuilder: (context, index) {
            final file = files[index];
            if (file == null) {
              return Container(
                width: imgHeight,
                height: imgHeight,
                child: const CupertinoActivityIndicator(),
              );
            }
            final fileTools = FileTools(path: files[index].path);
            final thumb = fileTools.isVideo
                ? FutureBuilder<ThumbnailResult>(
                    future: fileTools.videoThumbnail(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Container(child: snapshot.data.image);
                      } else {
                        return Container();
                      }
                    })
                : RoundedImage(image: FileImage(files[index]));

            return Hero(
              tag: file.path,
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  Container(
                      height: imgHeight,
                      width: imgHeight,
                      child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () {
                              Routz.of(context).fadeToPage(ZoomableImage(file: files[index]));
                            },
                            child: thumb,
                          ))),
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      my.postBloc.add(RemoveFile(file: files[index]));
                    },
                    child: Container(
                      height: 20,
                      width: 20,
                      alignment: Alignment.center,
                      // margin: const EdgeInsets.all(5.0),
                      decoration: BoxDecoration(
                        color: CupertinoColors.inactiveGray,
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: const Icon(FontAwesomeIcons.times,
                          size: 11, color: CupertinoColors.white),
                    ),
                  ),
                ],
              ),
            );
          }),
    );
  }
}
