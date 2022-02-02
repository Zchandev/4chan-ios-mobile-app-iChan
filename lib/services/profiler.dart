class Profiler {
  static int time;

  static void start() {
    time = DateTime.now().microsecondsSinceEpoch;
  }

  static void stop([String tag = '']) {
    final diff = DateTime.now().microsecondsSinceEpoch - time;
    if (tag.isNotEmpty) {
      print("$tag - finished in $diff");
    } else {
      print("Finished in $diff");
    }
    time = DateTime.now().microsecondsSinceEpoch;
  }
}
