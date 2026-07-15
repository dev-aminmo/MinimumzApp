import 'dart:async';

import 'package:minimumz/data/data.dart';
import 'package:minimumz/di/di.dart';
import 'package:minimumz/domain/repository/preference_repository.dart';

/// Client-side event buffer for the recommender.
///
/// Impressions (a product card entering the viewport) and taps are recorded
/// locally and flushed to `/me/events/batch` in batches, per docs §4.2:
///   • flush at ~20 buffered, OR
///   • 3 s after activity settles (debounce), OR
///   • every 15 s during continuous activity, OR
///   • on lifecycle events (app background / feed dispose) via [flushNow].
///
/// Same product in one session is coalesced to a single impression. Guests are
/// skipped (the endpoint is authenticated).
class RecoEventTracker {
  RecoEventTracker._();
  static final RecoEventTracker instance = RecoEventTracker._();

  static const int _batchSize = 20;
  static const int _hardCap = 50;
  static const Duration _debounce = Duration(seconds: 3);
  static const Duration _maxInterval = Duration(seconds: 15);

  final List<Map<String, dynamic>> _buffer = [];
  final Set<int> _seenThisSession = {};   // coalesce impressions per session
  String? _session;
  Timer? _debounceTimer;
  Timer? _maxIntervalTimer;

  /// Attach the active feed session so events are attributed to it.
  void setSession(String? session) => _session = session;

  bool get _isGuest => getIt<PreferenceRepository>().isGuest;

  /// A product scrolled into view (weak/negative fatigue signal).
  void impression(int productId, {int? dwellMs}) {
    if (_isGuest) return;
    if (!_seenThisSession.add(productId)) return;   // already counted this session
    _add({'type': 'impression', 'product_id': productId, if (dwellMs != null) 'dwell_ms': dwellMs});
  }

  /// A product was tapped / its details opened (positive signal).
  void view(int productId) {
    if (_isGuest) return;
    _add({'type': 'view', 'product_id': productId});
  }

  /// User explicitly dismissed a recommendation (negative signal).
  void dismiss(int productId) {
    if (_isGuest) return;
    _add({'type': 'dismiss', 'product_id': productId});
  }

  void _add(Map<String, dynamic> event) {
    event['ts'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _buffer.add(event);

    if (_buffer.length >= _hardCap) {
      flushNow();
      return;
    }
    if (_buffer.length >= _batchSize) {
      flushNow();
      return;
    }
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, flushNow);
    _maxIntervalTimer ??= Timer(_maxInterval, flushNow);
  }

  /// Flush the buffer immediately (call on app background / feed dispose).
  void flushNow() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _maxIntervalTimer?.cancel();
    _maxIntervalTimer = null;
    if (_buffer.isEmpty || _isGuest) return;

    final batch = List<Map<String, dynamic>>.from(_buffer);
    _buffer.clear();
    getIt<DataStore>().recoEvents.sendBatch(batch, session: _session);
  }

  /// Reset per-session impression coalescing (on a fresh feed session).
  void resetSession(String? session) {
    _session = session;
    _seenThisSession.clear();
  }
}
