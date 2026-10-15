import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'app_failure.dart';

extension MapDioExceptionToAppFailure<T> on AsyncValue<T> {
  /// Automatically intercepts any raw DioException within the state container
  /// and transforms it instantly into your type-safe AppFailure model.
  AsyncValue<T> mapNetworkErrors() {
    if (hasError && error is DioException) {
      final appFailure = AppFailure.fromDioException(error as DioException);
      return AsyncValue.error(appFailure, stackTrace!);
    }
    // Return unchanged if no raw DioException exists
    return this;
  }
}
