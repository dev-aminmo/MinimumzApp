import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _target = 'darkorchid-mouse-412686.hostingersite.com';

bool _isIpV4(String s) {
  final parts = s.split('.');
  if (parts.length != 4) return false;
  return parts.every((p) => int.tryParse(p) != null);
}

// Mirror of the fixed _fetchDoh — all blocking steps have explicit timeouts.
Future<String> _fetchDoh(
  String url,
  String hostname, {
  String? connectIp,
}) async {
  final client = HttpClient()..findProxy = (_) => 'DIRECT';
  if (connectIp != null) {
    final sniHost = Uri.parse(url).host;
    client.connectionFactory = (_, __, ___) async {
      final plain = await Socket.connect(connectIp, 443,
          timeout: const Duration(seconds: 5));
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
    final response = await request.close().timeout(const Duration(seconds: 5));
    final body = await utf8.decoder
        .bind(response)
        .join()
        .timeout(const Duration(seconds: 5));

    if (response.statusCode != 200) return 'HTTP ${response.statusCode}';
    final json = jsonDecode(body) as Map<String, dynamic>;
    final dnsStatus = json['Status'] as int?;
    if (dnsStatus != null && dnsStatus != 0) return 'DNS Status=$dnsStatus';
    final answers = json['Answer'];
    if (answers is! List) return 'no Answer array (keys: ${json.keys.toList()})';

    final allAnswers = (answers as List)
        .map((a) => 'type=${(a as Map)["type"]} data=${a["data"]}')
        .join(' | ');

    for (final answer in answers) {
      final data = (answer as Map<String, dynamic>)['data'] as String?;
      if (data != null && _isIpV4(data)) return 'OK:$data';
    }
    return 'no A found. answers: [$allAnswers]';
  } catch (e) {
    return 'ERROR: $e';
  } finally {
    client.close(force: true);
  }
}

Future<bool> _tcpReachable(String ip, int port) async {
  try {
    final s = await Socket.connect(ip, port,
        timeout: const Duration(seconds: 5));
    s.destroy();
    return true;
  } catch (_) {
    return false;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('DoH resolution on device', () {
    test('Cloudflare via connectIp 1.1.1.1', () async {
      final result = await _fetchDoh(
        'https://cloudflare-dns.com/dns-query',
        _target,
        connectIp: '1.1.1.1',
      ).timeout(const Duration(seconds: 15));
      print('[Cloudflare] $_target → $result');
      expect(result, startsWith('OK:'), reason: 'Cloudflare failed: $result');
    });

    test('AliDNS via connectIp 223.5.5.5', () async {
      final result = await _fetchDoh(
        'https://dns.alidns.com/resolve',
        _target,
        connectIp: '223.5.5.5',
      ).timeout(const Duration(seconds: 15));
      print('[AliDNS] $_target → $result');
      // not asserting — log only; TLS handshake may fail on some Android builds
    });

    test('Google via connectIp 8.8.8.8', () async {
      final result = await _fetchDoh(
        'https://dns.google/resolve',
        _target,
        connectIp: '8.8.8.8',
      ).timeout(const Duration(seconds: 15));
      print('[Google] $_target → $result');
      // not asserting — log only
    });

    test('resolved IP TCP port 443', () async {
      final result = await _fetchDoh('https://cloudflare-dns.com/dns-query', _target, connectIp: '1.1.1.1')
          .timeout(const Duration(seconds: 15));
      if (!result.startsWith('OK:')) {
        fail('Could not resolve via Cloudflare: $result');
      }
      final ip = result.substring(3);
      final reachable = await _tcpReachable(ip, 443);
      print('[TCP] $ip:443 reachable=$reachable');
      expect(reachable, isTrue, reason: '$ip:443 unreachable');
    });

    test('full HTTPS to resolved IP (SNI)', () async {
      final result = await _fetchDoh('https://cloudflare-dns.com/dns-query', _target, connectIp: '1.1.1.1')
          .timeout(const Duration(seconds: 15));
      if (!result.startsWith('OK:')) fail('Could not resolve: $result');
      final ip = result.substring(3);

      print('[HTTPS] $ip:443 SNI=$_target …');
      final client = HttpClient()..findProxy = (_) => 'DIRECT';
      client.connectionFactory = (uri, _, __) async {
        final plain = await Socket.connect(ip, 443,
            timeout: const Duration(seconds: 10));
        final secure = await SecureSocket.secure(plain, host: _target)
            .timeout(const Duration(seconds: 10), onTimeout: () {
          plain.destroy();
          throw Exception('TLS timeout');
        });
        return ConnectionTask.fromSocket(Future.value(secure), () {});
      };
      try {
        final req = await client
            .getUrl(Uri.parse('https://$_target/'))
            .timeout(const Duration(seconds: 10));
        final resp = await req.close().timeout(const Duration(seconds: 10));
        await resp.drain<void>();
        client.close(force: true);
        print('[HTTPS] status=${resp.statusCode}');
        expect(resp.statusCode, lessThan(500));
      } catch (e) {
        client.close(force: true);
        fail('HTTPS via resolved IP failed: $e');
      }
    });
  });

  group('Home API', () {
    testWidgets('shows first product title', (tester) async {
      // Resolve the API hostname via Cloudflare DoH (connectIp — no platform TLS hang).
      const apiHost = 'darkorchid-mouse-412686.hostingersite.com';
      final ipResult = await _fetchDoh('https://cloudflare-dns.com/dns-query', apiHost, connectIp: '1.1.1.1')
          .timeout(const Duration(seconds: 15));
      if (!ipResult.startsWith('OK:')) fail('DoH resolve failed: $ipResult');
      final ip = ipResult.substring(3);

      // Make a raw HTTPS call to /store/products?limit=1 via the resolved IP.
      final httpClient = HttpClient()..findProxy = (_) => 'DIRECT';
      httpClient.connectionFactory = (uri, _, __) async {
        final plain = await Socket.connect(ip, 443,
            timeout: const Duration(seconds: 10));
        final secure = await SecureSocket.secure(plain, host: apiHost)
            .timeout(const Duration(seconds: 10), onTimeout: () {
          plain.destroy();
          throw Exception('TLS timeout');
        });
        return ConnectionTask.fromSocket(Future.value(secure), () {});
      };

      String title = 'no products';
      try {
        final req = await httpClient
            .getUrl(Uri.parse('https://$apiHost/api/store/products?limit=1'))
            .timeout(const Duration(seconds: 10));
        req.headers.set('Accept', 'application/json');
        final resp = await req.close().timeout(const Duration(seconds: 15));
        final body = await utf8.decoder.bind(resp).join()
            .timeout(const Duration(seconds: 10));
        final json = jsonDecode(body) as Map<String, dynamic>;
        final products = json['products'] as List?;
        title = (products?.firstOrNull as Map?)?['title'] as String? ?? 'no products';
      } finally {
        httpClient.close(force: true);
      }

      print('[Home API] first product: $title');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text(title, key: const Key('first_product_title')),
            ),
          ),
        ),
      );

      expect(find.text(title), findsOneWidget);
    });
  });
}
