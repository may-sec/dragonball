import 'dart:async';

class SearchDebouncer {
  Timer? _timer;

  void run(Duration delay, void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}