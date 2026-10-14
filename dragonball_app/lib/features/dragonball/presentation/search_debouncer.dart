
import 'dart:async';

class SearchDebouncer {
  Timer? _timer;

  void run(Duration delay, void Function() action) {
    _timer?.cancel();

    _timer = Timer(delay, () {
      _timer = null;
      action();
    });
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    cancel();
  }
}
