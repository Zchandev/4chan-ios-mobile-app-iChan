abstract class MyException extends Exception {
  factory MyException([String message]) => _MyException(message);

  int get code;
  String toString();
}

class _MyException implements MyException {
  _MyException([this.message, this.code = 0]);

  final String message;
  final int code;

  @override
  String toString() => message ?? "Error";
}

class NotFoundException extends _MyException {
  NotFoundException([this.message = 'Not found.']);

  final String message;

  @override
  int get code => 404;
}

class NoConnectionException extends _MyException {
  NoConnectionException([this.message = 'No connection.']);

  final String message;
}

class ForbiddenException extends _MyException {
  ForbiddenException([this.message = 'Forbidden.\nTry in Safari.']);

  final String message;

  @override
  int get code => 403;
}

class UnavailableException extends _MyException {
  UnavailableException([this.message = 'Unavailable.']);

  final String message;

  @override
  int get code => 503;
}

class ServerErrorException extends _MyException {
  ServerErrorException([this.message = 'Server error.']);

  final String message;

  @override
  int get code => 500;
}

class ConnectionTimeoutException extends _MyException {
  ConnectionTimeoutException([this.message = 'Connection time out.']);

  final String message;
}
