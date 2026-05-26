import 'dart:convert';
import 'dart:io';

bool _isIpV4(String s) {
  final parts = s.split('.');
  if (parts.length != 4) return false;
  return parts.every((p) => int.tryParse(p) != null);
}

// Queries a DoH endpoint for an A record.
// [connectIp]: bypass system DNS by connecting to this IP directly while
//   presenting the DoH server's real hostname as SNI for cert validation.
// Every blocking step has an explicit timeout so nothing can hang indefinitely.
Future<String> _fetchDoh(
  String url,
  String hostname, {
  String? connectIp,
}) async {
  final client = HttpClient()..findProxy = (_) => 'DIRECT';
  if (connectIp != null) {
    final sniHost = Uri.parse(url).host;
    client.connectionFactory = (_, __, ___) async {
      final plain = await Socket.connect(
        connectIp,
        443,
        timeout: const Duration(seconds: 5),
      );
      // SecureSocket.secure() has no built-in timeout — add one explicitly.
      // On some Android devices the TLS handshake can hang indefinitely.
      final secure = await SecureSocket.secure(plain, host: sniHost)
          .timeout(const Duration(seconds: 5), onTimeout: () {
        plain.destroy();
        throw Exception('TLS handshake timeout');
      });
      return ConnectionTask.fromSocket(Future.value(secure), () {});
    };
  }
  try {
    final request = await client
        .getUrl(Uri.parse('$url?name=${Uri.encodeComponent(hostname)}&type=A'))
        .timeout(const Duration(seconds: 5));
    request.headers.set('Accept', 'application/dns-json');
    final response = await request.close()
        .timeout(const Duration(seconds: 5));
    if (response.statusCode == 200) {
      final body = await utf8.decoder.bind(response).join()
          .timeout(const Duration(seconds: 5));
      final json = jsonDecode(body) as Map<String, dynamic>;

      // Status 0 = NOERROR; non-zero means NXDOMAIN / SERVFAIL etc.
      final status = json['Status'] as int?;
      if (status != null && status != 0) throw Exception('DNS status $status');

      // Guard against missing or non-list Answer (e.g. NXDOMAIN with Status 0).
      final rawAnswers = json['Answer'];
      if (rawAnswers is! List) throw Exception('no A record');

      for (final answer in rawAnswers) {
        final data = (answer as Map<String, dynamic>)['data'] as String?;
        if (data != null && _isIpV4(data)) return data;
      }
    }
    throw Exception('no A record');
  } finally {
    client.close(force: true);
  }
}

// In-memory resolved-IP cache — keyed by hostname, expires after 5 minutes.
final _ipCache = <String, ({String ip, DateTime expiry})>{};

// Resolves a hostname by racing three DoH providers, all via connectIp so
// every TLS handshake goes through our explicit SecureSocket.secure().timeout()
// path — no platform TLS hangs possible:
//   • Cloudflare — 1.1.1.1,   SNI cloudflare-dns.com
//   • AliDNS     — 223.5.5.5, SNI dns.alidns.com
//   • Google     — 8.8.8.8,   SNI dns.google
// Whichever responds first wins. Falls back to original hostname if all fail.
// Successful results are cached for 5 minutes so reconnections are instant.
Future<String> dohResolve(String hostname) async {
  if (_isIpV4(hostname)) return hostname;
  final now = DateTime.now();
  final cached = _ipCache[hostname];
  if (cached != null && now.isBefore(cached.expiry)) return cached.ip;
  try {
    final ip = await Future.any([
      _fetchDoh('https://cloudflare-dns.com/dns-query', hostname, connectIp: '1.1.1.1'),
      _fetchDoh('https://dns.alidns.com/resolve', hostname, connectIp: '223.5.5.5'),
      _fetchDoh('https://dns.google/resolve', hostname, connectIp: '8.8.8.8'),
    ]).timeout(const Duration(seconds: 8));
    _ipCache[hostname] = (ip: ip, expiry: now.add(const Duration(minutes: 5)));
    return ip;
  } catch (_) {
    return hostname;
  }
}

// Creates an HttpClient whose connectionFactory resolves every hostname via
// dohResolve before opening the TCP socket — system DNS is never called.
//
// For HTTPS: opens a plain socket to the resolved IP then upgrades to TLS
// with the original hostname as SNI so cert validation passes normally.
// For HTTP: returns the plain socket directly.
HttpClient makeDohHttpClient() {
  final client = HttpClient();
  client.findProxy = (_) => 'DIRECT';
  client.connectionFactory =
      (Uri uri, String? proxyHost, int? proxyPort) async {
    final host = uri.host;
    final port =
        uri.hasPort ? uri.port : (uri.scheme == 'https' ? 443 : 80);
    final resolvedIp = await dohResolve(host);

    final plain = await Socket.connect(
      resolvedIp,
      port,
      timeout: const Duration(seconds: 10),
    );

    if (uri.scheme == 'https') {
      final secure = await SecureSocket.secure(plain, host: host)
          .timeout(const Duration(seconds: 10), onTimeout: () {
        plain.destroy();
        throw Exception('TLS handshake timeout');
      });
      return ConnectionTask.fromSocket(Future.value(secure), () {});
    }

    return ConnectionTask.fromSocket(Future.value(plain), () {});
  };
  return client;
}
