import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Decides what a single request returns: a [ResponseBody], or throws
/// (typically a [DioException]) to simulate a transport failure.
typedef FakeResponder = Future<ResponseBody> Function(RequestOptions options);

/// In-memory [HttpClientAdapter] that answers requests from a queue of
/// [FakeResponder]s and records every request it receives.
///
/// When the queue runs out, the last responder keeps answering, so
/// "always fail" scenarios need a single entry.
class FakeHttpClientAdapter implements HttpClientAdapter {
  FakeHttpClientAdapter(List<FakeResponder> responders)
    : assert(responders.isNotEmpty),
      _responders = List.of(responders);

  final List<FakeResponder> _responders;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    final responder = _responders.length > 1 ? _responders.removeAt(0) : _responders.single;
    return responder(options);
  }

  @override
  void close({bool force = false}) {}
}

/// Responds with [body] and [statusCode].
FakeResponder respond(String body, {int statusCode = 200}) =>
    (_) async => ResponseBody.fromString(body, statusCode);

/// Throws a [DioException] of [type], as Dio does for transport failures.
FakeResponder throwDio(DioExceptionType type) =>
    (options) async => throw DioException(requestOptions: options, type: type);
