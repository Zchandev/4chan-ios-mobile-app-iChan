import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ichan/models/media.dart';

// BLOC
class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  PlayerBloc() : super(PlayerLoading());

  @override
  Stream<PlayerState> mapEventToState(PlayerEvent event) async* {
    if (event is PlayerChange) {
      print("Changing player to ${event.media.name}");
      yield PlayerLoaded(media: event.media);
    } else if (event is PlayerStop) {
      yield PlayerStopped(media: event.media);
    } else if (event is PlayerResume) {
      yield PlayerResumed(media: event.media);
    } else if (event is PlayerYoutubeLinkPressed) {
      yield PlayerYoutubeActive(url: event.url, top: event.top, bottom: event.bottom);
    } else if (event is PlayerYoutubeClosed) {
      yield const PlayerYoutubeInactive();
    } else if (event is PlayerClose) {
      yield PlayerClosed();
    }
  }
}

// EVENT
abstract class PlayerEvent extends Equatable {
  const PlayerEvent();
}

class PlayerClose extends PlayerEvent {
  const PlayerClose();

  @override
  List<Object> get props => [];
}

class PlayerYoutubeLinkPressed extends PlayerEvent {
  const PlayerYoutubeLinkPressed({this.url, this.top, this.bottom});

  final String url;
  final double top;
  final double bottom;

  @override
  List<Object> get props => [];
}

class PlayerYoutubeClosed extends PlayerEvent {
  const PlayerYoutubeClosed({this.url});

  final String url;

  @override
  List<Object> get props => [];
}

class PlayerResume extends PlayerEvent {
  const PlayerResume({this.media});

  final Media media;

  @override
  List<Object> get props => [media.md5];
}

class PlayerStop extends PlayerEvent {
  const PlayerStop({this.media});

  final Media media;

  @override
  List<Object> get props => [media.md5];
}

class PlayerChange extends PlayerEvent {
  const PlayerChange({this.media});

  final Media media;

  @override
  List<Object> get props => [media.md5];
}

// STATE
abstract class PlayerState extends Equatable {
  const PlayerState({this.media});
  final Media media;

  @override
  List<Object> get props => [if (media == null) null else media.md5];
}

class PlayerLoading extends PlayerState {}

class PlayerClosed extends PlayerState {}

class PlayerLoaded extends PlayerState {
  const PlayerLoaded({this.media});

  final Media media;

  @override
  List<Object> get props => [media.md5];
}

class PlayerStopped extends PlayerState {
  const PlayerStopped({this.media});

  final Media media;

  @override
  List<Object> get props => [media.md5];
}

class PlayerResumed extends PlayerState {
  const PlayerResumed({this.media});

  final Media media;

  @override
  List<Object> get props => [media.md5];
}

class PlayerYoutubeActive extends PlayerState {
  const PlayerYoutubeActive({this.url, this.bottom, this.top});

  final String url;
  final double top;
  final double bottom;

  @override
  List<Object> get props => [url, bottom, top];
}

class PlayerYoutubeInactive extends PlayerState {
  const PlayerYoutubeInactive();

  @override
  List<Object> get props => [];
}
