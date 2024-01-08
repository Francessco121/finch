import 'dart:async';

/// Schedules a component's render callback in batches.
abstract final class RenderScheduler {
  /// **Internal only.**
  factory RenderScheduler(RenderSchedulerCallback callback) => _RenderScheduler(callback);
  /// **Internal only.**
  factory RenderScheduler.noop() => _NoOpRenderScheduler();

  /// Schedules a render for the component.
  /// 
  /// If this is called multiple times before a render, each call will be batched
  /// together into a single render instead of triggering multiple.
  void scheduleRender();
}

typedef RenderSchedulerCallback = void Function();

/// Optimization for when the component doesnt implement onRender or onFirstRender.
/// 
/// Scheduling with this class will simply do nothing. This behavior is transparent
/// to the user.
final class _NoOpRenderScheduler implements RenderScheduler {
  @override
  void scheduleRender() {}
}

final class _RenderScheduler implements RenderScheduler {
  bool _scheduled = false;
  bool _runningCallback = false;

  final RenderSchedulerCallback _callback;

  _RenderScheduler(this._callback);
  
  @override
  void scheduleRender() {
    if (_runningCallback) {
      throw StateError(
        'onRender or onFirstRender resulted in a recursive scheduleRender call. '
        'This is not allowed. Components should take to not modify state during '
        'a render callback.');
    }

    if (!_scheduled) {
      _scheduled = true;
      scheduleMicrotask(_microtaskCallback);
    }
  }

  void _microtaskCallback() {
    _scheduled = false;
    _runningCallback = true;
    try {
      _callback();
    } finally {
      _runningCallback = false;
    }
  }
}