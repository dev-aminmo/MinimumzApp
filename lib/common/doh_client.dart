import 'dart:convert';
import 'dart:io';

bool _isIpV4(String s) {
  final parts = s.split('.');
  if (parts.length != 4) return false;
  return parts.every((p) => int.tryParse(p) != null);
}

// Queries a DoH endpoint for an A record.
// [connectIp]: if set, connects to this IP directly (bypassing DNS for the
//   DoH server itself) while sending SNI = the DoH server's hostname.
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
      final secure = await SecureSocket.secure(plain, host: sniHost);
      return ConnectionTask.fromSocket(Future.value(secure), () {});
    };
  }
  try {
    final request = await client.getUrl(
      Uri.parse('$url?name=${Uri.encodeComponent(hostname)}&type=A'),
    );
    request.headers.set('Accept', 'application/dns-json');
    final response = await request.close();
    if (response.statusCode == 200) {
      final body = await utf8.decoder.bind(response).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      final answers = json['Answer'] as List?;
      if (answers != null) {
        for (final answer in answers) {
          final data = (answer as Map<String, dynamic>)['data'] as String?;
          if (data != null && _isIpV4(data)) return data;
        }
      }
    }
    throw Exception('no A record');
  } finally {
    client.close(force: true);
  }
}

// Resolves a hostname by racing two DoH providers:
//   • AliDNS  (223.5.5.5)  — always reachable in China without VPN
//   • Cloudflare (1.1.1.1) — reachable globally / via VPN
// Whichever responds first wins. Falls back to original hostname if both fail.
Future<String> dohResolve(String hostname) async {
  if (_isIpV4(hostname)) return hostname;
  try {
    return await Future.any([
      // AliDNS: connect to 223.5.5.5 by IP, SNI = dns.alidns.com
      _fetchDoh(
        'https://dns.alidns.com/dns-query',
        hostname,
        connectIp: '223.5.5.5',
      ),
      // Cloudflare: 1.1.1.1 has a cert for its own IP, no SNI trick needed
      _fetchDoh('https://1.1.1.1/dns-query', hostname),
    ]).timeout(const Duration(seconds: 6));
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
      final secure = await SecureSocket.secure(plain, host: host);
      return ConnectionTask.fromSocket(Future.value(secure), () {});
    }

    return ConnectionTask.fromSocket(Future.value(plain), () {});
  };
  return client;
}
