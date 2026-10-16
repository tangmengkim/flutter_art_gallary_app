import 'dart:convert';

import 'package:dio/dio.dart';


class ResponseInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {


    final rawData = response.data;
    if (rawData == null) {
      return handler.next(response);
    }

    if (rawData is List) {
      response.data = rawData;
      return handler.next(response);
    }

    final decodedData = rawData is String ? jsonDecode(rawData) : rawData;
    if (decodedData is! Map<String, dynamic>) {
      response.data = decodedData;
      return handler.next(response);
    }

    final jsonMap = decodedData;
    jsonMap.forEach((key, value) {
    },);

      response.data = jsonMap; // full resp return
    

    return handler.next(response);
  }




}
