import 'package:hive/hive.dart';
import 'package:ichan/models/thread_storage.dart';

class BoxProxy {
  const BoxProxy({this.box});

  final Box box;

  void incr(String field, {int to = 1}) {
    final _val = getInt(field);
    box.put(field, _val + to);
  }

  List getList(String field, {defaultValue}) =>
      box.get(field, defaultValue: defaultValue ?? []) as List;

  int getInt(String field, {defaultValue = 0}) => box.get(field, defaultValue: defaultValue) as int;

  double getDouble(String field, {defaultValue = 0.0}) =>
      box.get(field, defaultValue: defaultValue) as double;

  String getString(String field, {defaultValue = ''}) =>
      (box.get(field, defaultValue: defaultValue) as String) ?? defaultValue;

  bool getBool(String field, {defaultValue = false}) =>
      box.get(field, defaultValue: defaultValue) as bool;

  void delete(String field) => box.delete(field);

  Future<void> put(String field, dynamic value) async => await box.put(field, value);

  dynamic get(String field, {dynamic defaultValue}) => box.get(field, defaultValue: defaultValue);

  Iterable<dynamic> get values => box.values;
}

class FavsBox extends BoxProxy {
  FavsBox({this.box});

  final Box<ThreadStorage> box;

  List<ThreadStorage> get favorites =>
      box.values.where((e) => e.isFavorite && e.isSaved == false).toList();

  bool get hasEnoughThreads => favorites.length >= 5;
}
