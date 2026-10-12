import 'package:flutter/foundation.dart';
import 'package:shalomly_app/src/core/config/env.dart';

/// Application and Tenant Configuration.
/// Supports both build-time baked values (from `.env`) and dynamic runtime resolution.
class AppConfig {
  static const String _defaultTenantKey = 'sbc';
  static const String _defaultBaseUrl = 'http://127.0.0.1:8000/api/v1';
  static const String _defaultChurchName = 'SBC Church';

  final String tenantKey;
  final String apiBaseUrl;
  final bool isBaked;
  final String churchName;

  /// The app's API client credentials, exchanged for a guest token so public
  /// content (and the church's Theme) loads before anyone signs in. Issued by
  /// the backend's `scripts.generate_api_client`; empty when not baked in.
  final String clientId;
  final String clientSecret;

  const AppConfig({
    required this.tenantKey,
    required this.apiBaseUrl,
    required this.isBaked,
    this.churchName = _defaultChurchName,
    this.clientId = '',
    this.clientSecret = '',
  });

  /// Reads the build settings from `.env`; see [Env].
  factory AppConfig.fromEnv() => AppConfig.resolve(
    tenantKey: Env.tenantKey,
    apiBaseUrl: Env.apiBaseUrl,
    churchName: Env.churchName,
    clientId: Env.clientId,
    clientSecret: Env.clientSecret,
  );

  /// Fills empty build settings with defaults. An empty [tenantKey] makes a
  /// dynamic build, whose church comes from the Web hostname.
  factory AppConfig.resolve({
    String tenantKey = '',
    String apiBaseUrl = '',
    String churchName = '',
    String clientId = '',
    String clientSecret = '',
  }) {
    final isBaked = tenantKey.isNotEmpty;
    return AppConfig(
      tenantKey: isBaked ? tenantKey : _resolveDynamicTenantKey(),
      apiBaseUrl: apiBaseUrl.isNotEmpty ? apiBaseUrl : _defaultBaseUrl,
      isBaked: isBaked,
      churchName: churchName.isNotEmpty ? churchName : _defaultChurchName,
      clientId: clientId,
      clientSecret: clientSecret,
    );
  }

  /// Whether the app can ask the backend for a guest token.
  bool get hasClientCredentials =>
      clientId.isNotEmpty && clientSecret.isNotEmpty;

  /// In Web environments, extract subdomain from hostname; otherwise fallback to default.
  static String _resolveDynamicTenantKey() {
    if (kIsWeb) {
      final host = Uri.base.host;
      final parts = host.split('.');
      if (parts.length > 2 && parts.first != 'www') {
        return parts.first;
      }
    }
    return _defaultTenantKey;
  }

  AppConfig copyWith({
    String? tenantKey,
    String? apiBaseUrl,
    bool? isBaked,
    String? churchName,
    String? clientId,
    String? clientSecret,
  }) {
    return AppConfig(
      tenantKey: tenantKey ?? this.tenantKey,
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      isBaked: isBaked ?? this.isBaked,
      churchName: churchName ?? this.churchName,
      clientId: clientId ?? this.clientId,
      clientSecret: clientSecret ?? this.clientSecret,
    );
  }
}
