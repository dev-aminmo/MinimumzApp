import 'package:flutter/foundation.dart';

class NetworkEntry {
  NetworkEntry({
    required this.method,
    required this.url,
    required this.durationMs,
    required this.timestamp,
    this.requestHeaders,
    this.requestBody,
    this.statusCode,
    this.responseBody,
    this.error,
  });

  final String method;
  final String url;
  final Map<String, dynamic>? requestHeaders;
  final dynamic requestBody;
  final int? statusCode;
  final dynamic responseBody;
  final String? error;
  final int durationMs;
  final DateTime timestamp;

  bool get isSuccess => statusCode != null && statusCode! >= 200 && statusCode! < 300;
  bool get isError => error != null || (statusCode != null && statusCode! >= 400);
}

class NetworkLog extends ChangeNotifier {
  static final NetworkLog instance = NetworkLog._();
  NetworkLog._();

  static const _maxEntries = 150;

  final _entries = <NetworkEntry>[];
  List<NetworkEntry> get entries => List.unmodifiable(_entries);

  void add(NetworkEntry entry) {
    _entries.insert(0, entry);
    if (_entries.length > _maxEntries) _entries.removeLast();
    notifyListeners();
  }

  void clear() {
    _entries.clear();
    notifyListeners();
  }
}
