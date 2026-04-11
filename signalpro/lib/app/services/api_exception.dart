import 'package:dio/dio.dart';

class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

ApiException mapDioError(DioException error) {
  final statusCode = error.response?.statusCode;
  final data = error.response?.data;

  if (statusCode == 413) {
    return ApiException(
      'Upload is too large. Please use smaller images (recommended below 2MB each).',
    );
  }

  if (data is Map<String, dynamic>) {
    final detail = data['detail'];
    if (detail is String && detail.trim().isNotEmpty) {
      return ApiException(detail);
    }

    if (detail is List && detail.isNotEmpty) {
      final first = detail.first;
      if (first is Map<String, dynamic>) {
        final msg = first['msg'];
        if (msg is String && msg.trim().isNotEmpty) {
          return ApiException(msg);
        }
      }
    }
  }

  if (error.type == DioExceptionType.connectionError ||
      error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.sendTimeout) {
    return ApiException('Unable to connect to server. Please try again.');
  }

  return ApiException('Request failed. Please try again.');
}
