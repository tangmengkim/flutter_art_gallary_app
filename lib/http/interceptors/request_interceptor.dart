import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class RequestInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      print('► NETWORK REQUEST [${options.method}] ──> ${options.uri}');
      print('Payload: ${options.data}');
    }
    super.onRequest(options, handler);
  }
}
