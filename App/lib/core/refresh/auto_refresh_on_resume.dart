import 'dart:async';

import 'package:flutter/widgets.dart';

mixin AutoRefreshOnResume<T extends StatefulWidget> on State<T> {
  StreamSubscription<void>? _refreshSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
    _refreshSubscription = onRefreshRequested?.listen((_) {
      onRefresh();
    });
  }

  @override
  void dispose() {
    _refreshSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

  Stream<void>? get onRefreshRequested;

  void onRefresh();

  late final WidgetsBindingObserver _lifecycleObserver =
      _ResumeObserver(onResumed: onRefresh);
}

mixin PeriodicRefresh<T extends StatefulWidget> on State<T> {
  Timer? _periodicRefreshTimer;

  Duration get refreshInterval => const Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    _periodicRefreshTimer = Timer.periodic(refreshInterval, (_) {
      if (!mounted) {
        return;
      }
      onPeriodicRefresh();
    });
  }

  @override
  void dispose() {
    _periodicRefreshTimer?.cancel();
    super.dispose();
  }

  void onPeriodicRefresh();
}

class _ResumeObserver with WidgetsBindingObserver {
  _ResumeObserver({required this.onResumed});

  final VoidCallback onResumed;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResumed();
    }
  }
}
