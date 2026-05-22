import 'dart:collection';

/// Log tags for structured logging.
enum LogTag { auth, chat, rtc, schedule }

/// A single log entry produced by [AppLogger].
class LogEntry {
  final DateTime timestamp;
  final LogTag tag;
  final String message;

  const LogEntry({
    required this.timestamp,
    required this.tag,
    required this.message,
  });

  @override
  String toString() =>
      '[${timestamp.toIso8601String()}] [${tag.name.toUpperCase()}] $message';
}

/// Singleton logger with a fixed-capacity circular buffer (capacity 20).
class AppLogger {
  AppLogger._();

  static final AppLogger _instance = AppLogger._();

  /// Access the singleton instance.
  static AppLogger get instance => _instance;

  static const int _capacity = 20;
  final Queue<LogEntry> _buffer = Queue<LogEntry>();

  /// Log a [message] under [tag]. Oldest entry is dropped when buffer is full.
  void log(LogTag tag, String message) {
    if (_buffer.length >= _capacity) {
      _buffer.removeFirst();
    }
    final entry = LogEntry(
      timestamp: DateTime.now(),
      tag: tag,
      message: message,
    );
    _buffer.addLast(entry);
    // ignore: avoid_print
    print(entry.toString());
  }

  /// Convenience static method so callers can write AppLogger.log(...).
  static void write(LogTag tag, String message) =>
      _instance.log(tag, message);

  /// Returns an unmodifiable snapshot of the current log buffer.
  List<LogEntry> get entries => List.unmodifiable(_buffer);

  /// Clears all entries from the buffer.
  void clear() => _buffer.clear();
}
