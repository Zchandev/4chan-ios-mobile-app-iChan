import 'package:flutter/foundation.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:ichan/models/models.dart';
import 'package:ichan/repositories/repositories.dart';
import 'package:ichan/services/enums.dart';
import 'package:ichan/services/exceptions.dart';
import 'package:ichan/services/my.dart' as my;

// BLOC
class CategoryBloc extends Cubit<CategoryState> {
  CategoryBloc({@required this.repo}) : super(CategoryEmpty());

  final Repo repo;
  List<Board> boards;
  List<String> categories;
  Platform selectedPlatform;

  List<Board> get favorites => my.prefs.get('favorite_boards', defaultValue: []).cast<Board>();

  List<Board> platformFavorites() {
    return favorites.where((e) => e.platform == selectedPlatform).toList();
  }

  List<Board> filterByNameStarts(String query) {
    return boards.where((e) => e.name.toLowerCase().startsWith(query.toLowerCase())).toList();
  }

  List<Board> filterByNameContains(String query) {
    return boards.where((e) => e.name.toLowerCase().contains(query.toLowerCase())).toList();
  }

  List<Board> filterByIdStarts(String query) {
    return boards.where((e) => e.id.toLowerCase().startsWith(query.toLowerCase())).toList();
  }

  Board _createBoard(String id, Platform platform) => Board(id, name: id, platform: platform);

  void favoriteBoard({String boardName, Board board}) {
    if (selectedPlatform == Platform.all) {
      return;
    }
    final _favorites = favorites;

    emit(CategoryLoading());
    board ??= boards.firstWhere((e) => e.id == boardName,
        orElse: () => _createBoard(boardName, selectedPlatform));

    if (_favorites.any((e) => e.equalsTo(board)) == false) {
      _favorites.add(board);
      my.prefs.put('favorite_boards', _favorites);
    }

    emit(CategoryLoaded(
      boards: boards,
      categories: categories,
      favoriteBoards: platformFavorites(),
      platform: selectedPlatform,
    ));
  }

  void unfavoriteBoard(Board board) {
    emit(CategoryLoading());
    my.prefs.box
        .put('favorite_boards', favorites.where((e) => e.equalsTo(board) == false).toList());

    emit(CategoryLoaded(
      boards: boards,
      categories: categories,
      favoriteBoards: platformFavorites(),
      platform: selectedPlatform,
    ));
  }

  void search(String query) {
    List<Board> filteredBoards;
    final length = query.length;

    if (length == 0) {
      emit(CategoryLoaded(
        boards: boards,
        categories: categories,
        favoriteBoards: platformFavorites(),
        platform: selectedPlatform,
      ));
    } else {
      filteredBoards = filterByIdStarts(query);
      if (filteredBoards.isEmpty) {
        filteredBoards = filterByNameContains(query);
      }

      emit(CategoryLoaded(
        boards: filteredBoards,
        categories: categories,
        favoriteBoards: const [],
        platform: selectedPlatform,
      ));
    }
  }

  Future fetchBoards([Platform platform]) async {
    emit(CategoryLoading());
    try {
      platform ??= selectedPlatform;
      // print("Fetch boards");
      assert(platform != null);
      final Map<String, dynamic> result = await repo.on(platform).fetchBoards();
      boards = result['boards'] as List<Board>;
      categories = result['categories'] as List<String>;

      emit(CategoryLoaded(
        boards: boards,
        categories: categories,
        favoriteBoards: platformFavorites(),
        platform: platform,
      ));
    } catch (error) {
      print("Got error: $error");
      final String message = error is MyException ? error.toString() : "Error";

      emit(CategoryError(message: message));
    }
  }

  void setPlatform() {
    final platforms = my.prefs.getList('platforms');
    if (platforms.isNotEmpty) {
      selectedPlatform = platforms[0];
    } else {
      selectedPlatform = Platform.fourchan;
    }
    fetchBoards(selectedPlatform);
  }
}

// STATE
abstract class CategoryState extends Equatable {
  const CategoryState();

  @override
  List<Object> get props => [];
}

class CategoryEmpty extends CategoryState {}

class CategoryLoading extends CategoryState {}

class CategoryLoaded extends CategoryState {
  const CategoryLoaded({
    @required this.boards,
    @required this.categories,
    @required this.favoriteBoards,
    @required this.platform,
  }) : assert(boards != null);

  final List<Board> boards;
  final List<Board> favoriteBoards;
  final List<String> categories;
  final Platform platform;

  @override
  List<Object> get props => [boards, categories, platform];
}

class CategoryError extends CategoryState {
  const CategoryError({this.message = "Error"});

  final String message;

  @override
  List<Object> get props => [message];
}
