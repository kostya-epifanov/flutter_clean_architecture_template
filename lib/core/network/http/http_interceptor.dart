import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

/// Logs outgoing requests, responses and errors.
class HttpInterceptor extends Interceptor {
  final Logger _logger;

  HttpInterceptor(this._logger);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.d('HttpClient: >>> [${options.method}] ${options.uri} '
        'headers: ${options.headers} body: ${options.data}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logger.d('HttpClient: <<< [${response.statusCode}] '
        '${response.requestOptions.method} ${response.requestOptions.uri}: '
        '${response.data}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.d('HttpClient: <<< ERROR [${err.response?.statusCode}] '
        '${err.requestOptions.method} ${err.requestOptions.uri}: '
        '${err.type.name} ${err.response?.data ?? err.message}');
    handler.next(err);
  }
}
