import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class HttpInterceptor extends Interceptor {
  final Logger _logger;

  HttpInterceptor(this._logger);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    _logger.d('HttpClient.headers: ${options.headers}');
    _logger.d('HttpClient: >>> [${options.method}] ${options.path}: ${options.data}');
    return super.onRequest(options, handler);
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    _logger.d('HttpClient: <<< [${response.statusCode}] '
        '${response.requestOptions.method} ${response.requestOptions.path}: ${response.data}');
    return super.onResponse(response, handler);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    _logger.d('HttpClient: <<< ERROR [${err.response?.statusCode}] '
        '${err.requestOptions.method} ${err.requestOptions.path} ${err.response}');
    return super.onError(err, handler);
  }
}
