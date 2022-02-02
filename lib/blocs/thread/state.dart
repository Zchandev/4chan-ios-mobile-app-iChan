import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:ichan/blocs/thread/data.dart';

//////////////////////////////
/////////  STATES  ///////////
//////////////////////////////
abstract class ThreadState extends Equatable {
  const ThreadState({this.threadData});

  final ThreadData threadData;
  // int get loadedAt => null;
}

class ThreadEmpty extends ThreadState {
  const ThreadEmpty({this.threadData});

  final ThreadData threadData;

  @override
  List<Object> get props => [threadData?.thread?.toKey];
}

class ThreadLoading extends ThreadState {
  const ThreadLoading({this.threadData});

  final ThreadData threadData;

  @override
  List<Object> get props => [threadData?.thread?.toKey];
}

class ThreadError extends ThreadState {
  const ThreadError({this.threadData, this.code = 0, this.message = "Error"});

  final String message;
  final int code;
  final ThreadData threadData;

  @override
  List<Object> get props => [message, code, threadData?.thread?.toKey];
}

class ThreadMessage extends ThreadState {
  const ThreadMessage({this.threadData, this.title, this.message});

  final String title;
  final String message;
  final ThreadData threadData;

  @override
  List<Object> get props => [message, title, threadData?.thread?.toKey];
}

class ThreadLoaded extends ThreadState {
  const ThreadLoaded({this.threadData});

  final ThreadData threadData;

  @override
  List<Object> get props => [threadData?.thread?.toKey];
}

class StartScroll extends ThreadState {
  const StartScroll({
    @required this.threadData,
    @required this.index,
  }) : assert(index != null);

  final int index;
  final ThreadData threadData;

  @override
  List<Object> get props => [threadData, index];
}
