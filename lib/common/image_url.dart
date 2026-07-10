import 'package:minimumz/data/src/data_store.dart';
import 'package:minimumz/di/di.dart';

/// Rewrites image URLs whose host is a **private/LAN IP** (e.g. a local Laravel
/// dev server like http://192.168.10.51/...) to the app's current API host, so
/// product images are reachable from a physical device during local testing.
///
/// Public/production hosts (a real domain or CDN) are NEVER touched — the guard
/// only matches RFC-1918 private ranges and localhost — so production images
/// keep working unchanged.
String? fixImageUrl(String? url) {
  if (url == null || url.isEmpty) return url;

  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasAuthority) return url;

  // Only rewrite obvious local/dev hosts; leave public hosts alone.
  if (!_isPrivateHost(uri.host)) return url;

  try {
    final base = Uri.parse(getIt<DataStore>().baseUrl);
    return uri
        .replace(
          scheme: base.scheme,
          host: base.host,
          port: base.hasPort ? base.port : (base.scheme == 'https' ? 443 : 80),
        )
        .toString();
  } catch (_) {
    return url; // DI not ready / unpar. base — fail safe, return original.
  }
}

/// True for localhost and RFC-1918 private IPv4 ranges:
/// 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 (and 127.0.0.0/8).
bool _isPrivateHost(String host) {
  if (host == 'localhost') return true;

  final m = RegExp(r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$').firstMatch(host);
  if (m == null) return false;

  final a = int.parse(m.group(1)!);
  final b = int.parse(m.group(2)!);

  if (a == 127) return true;                 // loopback
  if (a == 10) return true;                  // 10.0.0.0/8
  if (a == 192 && b == 168) return true;     // 192.168.0.0/16
  if (a == 172 && b >= 16 && b <= 31) return true; // 172.16.0.0/12
  return false;
}
