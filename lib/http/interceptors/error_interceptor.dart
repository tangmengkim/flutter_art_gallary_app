import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';

import '../app_failure.dart';
import '../base_response.dart';

class ErrorInterceptor extends Interceptor {
  ErrorInterceptor();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // ─── CASE 1: Network Connectivity Failures ───
    final isNetworkError =
        err.type == DioExceptionType.connectionError ||
        err.error is SocketException ||
        err.message?.contains('Failed host lookup') == true;

    if (isNetworkError && err.response == null) {
      final networkException = DioException(
        requestOptions: err.requestOptions,
        type: DioExceptionType.connectionError, 
        message: err.message,
        error: err.error,
      );
      
      print('=======◀ CONNECTION ERROR ──> ${err.requestOptions.uri}');
      return handler.next(networkException);
    }

    // ─── CASE 2: Server Business Error (400, 422, 500, etc.) ───
    if (err.response != null) {
      try {
        final rawData = err.response?.data;
        Map<String, dynamic> jsonMap;

        if (rawData is String) {
          jsonMap = jsonDecode(rawData) as Map<String, dynamic>;
        } else if (rawData is Map<String, dynamic>) {
          jsonMap = rawData;
        } else {
          return handler.next(err); 
        }

        final baseResponse = BaseResponse<dynamic>.fromJson(
          jsonMap,
          (json) => json,
        );

        final wrappedException = DioException(
          requestOptions: err.requestOptions,
          response: err.response,
          type: DioExceptionType.badResponse,
          error: AppFailure.serverBusiness(
            errorCode: baseResponse.errorCode,
            errors: baseResponse.errors,
            message: baseResponse.message ?? 'An HTTP bad response failure occurred.',
          ),
        );
        
        print('=======◀ SERVER BUSINESS ERROR [${baseResponse.errorCode}] ──> ${err.requestOptions.uri}');
        return handler.next(wrappedException);
      } catch (_) {
        return handler.next(err);
      }
    }

    return handler.next(err);
  }
}
