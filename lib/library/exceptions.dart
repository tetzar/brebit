class UserNotFoundException implements Exception {
  String cause;

  UserNotFoundException(this.cause);
}

class UnauthorizedException implements Exception {
  String cause;

  UnauthorizedException(this.cause);
}

class InvalidTokenException implements Exception {
  String cause;

  InvalidTokenException(this.cause);
}

class RecordNotFoundException implements Exception {
  String cause;

  RecordNotFoundException(this.cause);
}

class InvalidUrlException implements Exception {
  String cause;
  String causedAt;

  InvalidUrlException(this.cause, this.causedAt);
}

class UnExpectedException implements Exception {
  String cause;
  String causedAt;
  int statusCode;

  UnExpectedException(this.cause, this.causedAt, this.statusCode);
}

class CreateRecordFailedException implements Exception {
  String cause;

  CreateRecordFailedException(this.cause);
}

class FirebaseNotFoundException implements Exception {
  String cause;

  FirebaseNotFoundException(this.cause);
}

class AccessDeniedException implements Exception {
  String cause;

  AccessDeniedException(this.cause);
}