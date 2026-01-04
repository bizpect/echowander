import 'push_payload.dart';

class PushState {
  const PushState({this.foregroundMessage});

  final PushPayload? foregroundMessage;

  PushState copyWith({PushPayload? foregroundMessage, bool clearMessage = false}) {
    return PushState(
      foregroundMessage: clearMessage ? null : (foregroundMessage ?? this.foregroundMessage),
    );
  }
}
