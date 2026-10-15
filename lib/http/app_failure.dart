import 'package:dio/dio.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_failure.freezed.dart';

@freezed
sealed class AppFailure with _$AppFailure implements Exception {
  const AppFailure._();

  const factory AppFailure.serverBusiness({
    dynamic errorCode, 
    dynamic errors,    
    int? id,
    @Default('A backend business logic failure occurred.') String message,
  }) = _ServerBusiness;

  const factory AppFailure.timeout({
    @Default('Connection timed out. Please try again.') String message,
  }) = _Timeout;

  const factory AppFailure.noInternet({
    @Default('No internet connection.') String message,
  }) = _NoInternet;

  const factory AppFailure.server({
    int? statusCode,
    String? errorDescription,
    @Default('A server error occurred.') String message,
  }) = _Server;

  const factory AppFailure.cancelled({
    @Default('Request was cancelled.') String message,
  }) = _Cancelled;

  const factory AppFailure.unknown({
    @Default('Something went wrong.') String message,
  }) = _Unknown;

  factory AppFailure.fromDioException(DioException error) {
    if (error.error is AppFailure) {
      return error.error as AppFailure;
    }

    return switch (error.type) {
      DioExceptionType.connectionTimeout || 
      DioExceptionType.sendTimeout || 
      DioExceptionType.receiveTimeout => const AppFailure.timeout(),
      
      DioExceptionType.connectionError => const AppFailure.noInternet(),
      
      DioExceptionType.cancel => const AppFailure.cancelled(),
      
      DioExceptionType.badResponse => AppFailure.server(
          statusCode: error.response?.statusCode,
          errorDescription: _extractMessage(error.response),
          message: _extractMessage(error.response) ?? 'Server error: ${error.response?.statusCode}',
        ),
      _ => const AppFailure.unknown(),
    };
  }

  factory AppFailure.fromAny(Object error) {
    if (error is AppFailure) return error;
    if (error is DioException) return AppFailure.fromDioException(error);
    return AppFailure.unknown(message: error.toString());
  }

  /// 👈 ដំណោះស្រាយ៖ ប្រើប្រាស់ Native Dart Switch Expression លើ Sealed Class ជំនួសឱ្យ AppFailurePatterns
  String get errorMessage {
    return switch (this) {
      _ServerBusiness(message: final msg) => msg,
      _Timeout(message: final msg) => msg,
      _NoInternet(message: final msg) => msg,
      _Server(message: final msg) => msg,
      _Cancelled(message: final msg) => msg,
      _Unknown(message: final msg) => msg,
    };
  }
}

String? _extractMessage(Response? response) {
  if (response?.data != null && response?.data is Map) {
    return response?.data['message'] ?? response?.data['error'];
  }
  return null;
}
