import 'package:brebit/view/settings/widgets/setting-tile.dart';

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

class NotLoggedInException implements Exception{
  String cause;

  NotLoggedInException(this.cause);
}

class ProviderValueMissingException implements Exception{
  String cause;

  ProviderValueMissingException(this.cause);
}

class RouteNotFoundException implements Exception{
  String cause;
  RouteNotFoundException(this.cause);
}