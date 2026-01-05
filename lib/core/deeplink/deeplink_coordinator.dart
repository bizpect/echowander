import 'package:flutter_riverpod/flutter_riverpod.dart';

final deepLinkCoordinatorProvider =
    NotifierProvider<DeepLinkCoordinator, DeepLinkState>(DeepLinkCoordinator.new);

class DeepLinkState {
  const DeepLinkState({this.pendingPath});

  final String? pendingPath;

  DeepLinkState copyWith({String? pendingPath, bool clearPath = false}) {
    return DeepLinkState(
      pendingPath: clearPath ? null : (pendingPath ?? this.pendingPath),
    );
  }
}

class DeepLinkCoordinator extends Notifier<DeepLinkState> {
  final List<String> _queue = [];

  @override
  DeepLinkState build() => const DeepLinkState();

  void enqueuePath(String path) {
    if (path.isEmpty) {
      return;
    }
    _queue.add(path);
    if (state.pendingPath == null) {
      _advance();
    }
  }

  void consumeCurrent() {
    if (state.pendingPath == null) {
      return;
    }
    _advance();
  }

  void _advance() {
    if (_queue.isEmpty) {
      state = state.copyWith(clearPath: true);
      return;
    }
    state = state.copyWith(pendingPath: _queue.removeAt(0));
  }
}
