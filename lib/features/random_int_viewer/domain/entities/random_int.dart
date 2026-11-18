import 'package:equatable/equatable.dart';

enum RandomIntSource {
  /// From the API.
  remote,

  /// Generated on the device because the API could not be reached.
  device,
}

/// A number in `RandomIntRange` and where it came from, so the UI can say when it is
/// not from the API.
class RandomInt extends Equatable {
  final int value;
  final RandomIntSource source;

  const RandomInt.remote(this.value) : source = RandomIntSource.remote;

  const RandomInt.device(this.value) : source = RandomIntSource.device;

  bool get isFromDevice => source == RandomIntSource.device;

  @override
  List<Object?> get props => [value, source];
}
