import 'dart:developer';

import 'base.dart';

/// Sends batched behavioral events to the recommender.
class RecoEventsResource extends BaseResource {
  RecoEventsResource(super.client);

  /// POST /store/me/events/batch
  /// events: [{ type, product_id?, dwell_ms?, ts? }]
  Future<void> sendBatch(List<Map<String, dynamic>> events, {String? session}) async {
    if (events.isEmpty) return;
    try {
      await client.post('/store/me/events/batch', data: {
        if (session != null) 'session': session,
        'events': events,
      });
    } catch (error, stackTrace) {
      // Fire-and-forget — never surface event errors to the UI.
      log('reco events failed: $error', stackTrace: stackTrace);
    }
  }
}
