import 'package:universal_html/html.dart';

class Htmlz {
  static String parseBody(String body) {
    if (body.endsWith('<br>')) {
      body = body.substring(0, body.length - 4);
    }
    return body.replaceAll('\\r\\n', '<br>').replaceAll("\\t", '  ');
  }

  static String cleanTags(String body) {
    return body.replaceAll(RegExp("<[^>]*>", multiLine: true), "");
  }

  static String replaceNewline(String body) {
    return body.replaceAll('<br>', '\n');
  }

  static String strip(String body) {
    final text = Element.span()..appendHtml(body.replaceAll('<br>', '\n'));
    return text.innerText;
  }

  static String toHuman(String body) => cleanTags(unescape(replaceNewline(body)));

  static String unescape(String body) {
    return body
        .replaceAll('&gt;', '>')
        .replaceAll("&lt;", '<')
        .replaceAll("&amp;", '&')
        .replaceAll("&quot;", '"')
        .replaceAll("&apos;", '\'')
        .replaceAll("&#47;", '/')
        .replaceAll("&#92;", '\\')
        .replaceAll("&#039;", "'")
        .replaceAll("&#39;", "'")
        .replaceAll("&nbsp;", ' ')
        .replaceAll("&copy;", '©');
  }
}
