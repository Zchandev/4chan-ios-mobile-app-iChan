import 'package:hive/hive.dart';

part 'platform.g.dart';

@HiveType(typeId: 2)
enum Platform {
  @HiveField(0)
  all,
  @HiveField(1)
  zchan,
  @HiveField(2)
  dvach,
  @HiveField(3)
  fourchan,
}
