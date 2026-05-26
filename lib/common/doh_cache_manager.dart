import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'doh_client.dart';

// Singleton CacheManager that routes image downloads through the DoH-enabled
// HttpClient so image hostnames are resolved without system DNS.
class DohCacheManager extends CacheManager with ImageCacheManager {
  static const key = 'dohCachedImages';
  static final DohCacheManager instance = DohCacheManager._();
  DohCacheManager._() : super(Config(key, fileService: _DohFileService()));
}

class _DohFileService implements FileService {
  final HttpClient _client = makeDohHttpClient();

  @override
  int concurrentFetches = 5;

  @override
  Future<FileServiceResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    final request = await _client.getUrl(Uri.parse(url));
    headers?.forEach((k, v) => request.headers.set(k, v));
    final response = await request.close();
    return _DohFileResponse(response);
  }
}

class _DohFileResponse implements FileServiceResponse {
  final HttpClientResponse _response;
  _DohFileResponse(this._response);

  @override
  Stream<List<int>> get content => _response;

  @override
  int get statusCode => _response.statusCode;

  @override
  DateTime get validTill {
    final cc = _response.headers.value('cache-control') ?? '';
    final match = RegExp(r'max-age=(\d+)').firstMatch(cc);
    if (match != null) {
      final secs = int.tryParse(match.group(1)!) ?? 0;
      return DateTime.now().add(Duration(seconds: secs));
    }
    return DateTime.now().add(const Duration(days: 7));
  }

  @override
  String get fileExtension {
    final sub = _response.headers.contentType?.subType;
    return sub != null ? '.$sub' : '';
  }

  @override
  String? get eTag => _response.headers.value('etag');

  @override
  int? get contentLength {
    final l = _response.contentLength;
    return l == -1 ? null : l;
  }
}
