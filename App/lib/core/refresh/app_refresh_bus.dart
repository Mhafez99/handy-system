import 'dart:async';

class AppRefreshBus {
  AppRefreshBus._();

  static final AppRefreshBus instance = AppRefreshBus._();

  final _controller = StreamController<void>.broadcast();

  Stream<void> get stream => _controller.stream;

  void notify() {
    if (_controller.isClosed) {
      return;
    }

    _controller.add(null);
  }

  void dispose() {
    _controller.close();
  }
}
