import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_config.dart';
import '../core/network/api_exception.dart';
import '../core/storage/secure_token_storage.dart';

typedef VoidCallback = void Function();

class ApiService {
  static VoidCallback? _onUnauthorized;
  static http.Client _client = http.Client();

  static void registerUnauthorizedHandler(VoidCallback handler) {
    _onUnauthorized = handler;
  }

  static void configureClient(http.Client client) {
    _client = client;
  }

  static void resetClient() {
    _client = http.Client();
  }

  static Uri _uri(String path, [Map<String, String>? queryParameters]) {
    return Uri.parse(AppConfig.apiBaseUrl).replace(
      path: path,
      queryParameters: queryParameters,
    );
  }

  static dynamic _decodeBody(http.Response response) {
    if (response.body.isEmpty) {
      return null;
    }
    return jsonDecode(response.body);
  }

  static String _errorMessage(http.Response response, String fallback) {
    try {
      final body = _decodeBody(response);
      if (body is Map<String, dynamic>) {
        return body['message']?.toString() ??
            body['error']?.toString() ??
            fallback;
      }
    } catch (_) {}
    return response.body.isEmpty ? fallback : response.body;
  }

  static Map<String, dynamic> _normalizeSensor(Map<String, dynamic> item) {
    return {
      'id': item['id'],
      'deviceId': item['deviceId'],
      'suhu':
          (item['temperature'] as num?)?.toDouble() ??
          (item['suhu'] as num?)?.toDouble(),
      'kelembaban':
          (item['humidity'] as num?)?.toDouble() ??
          (item['kelembaban'] as num?)?.toDouble(),
      'heater': item['heater'] == true || item['heater'] == 1,
      'kipas': item['kipas'] == true || item['kipas'] == 1,
      'exhaust': item['exhaust'] == true || item['exhaust'] == 1,
      'mode': item['mode']?.toString(),
      'createdAt': item['createdAt'] ?? item['created_at'],
    };
  }

  static Map<String, dynamic> _normalizeNotification(Map<String, dynamic> item) {
    return {
      'id': item['id'],
      'eventKey': item['eventKey']?.toString() ?? '',
      'title': item['title']?.toString() ?? '',
      'message': item['message']?.toString() ?? '',
      'severity': item['severity']?.toString() ?? 'INFO',
      'read': item['read'] == true,
      'createdAt': item['createdAt']?.toString(),
      'readAt': item['readAt']?.toString(),
    };
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<void> _persistUserProfile(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nama', user['nama']?.toString() ?? 'Pengguna');
    await prefs.setString('email', user['email']?.toString() ?? '');
    await prefs.setString('lokasi', user['lokasi']?.toString() ?? 'Belum diisi');
    await prefs.setString(
      'jenis_kopi',
      user['jenisKopi']?.toString() ?? 'Arabika',
    );
    await prefs.setString('nama_alat', user['namaAlat']?.toString() ?? 'ATMA-01');
  }

  static Future<T> _handleUnauthorized<T>([String? message]) async {
    await clearSession();
    _onUnauthorized?.call();
    throw SessionExpiredException(
      message ?? 'Sesi login berakhir. Silakan masuk lagi.',
    );
  }

  static Never _handleNetworkError(Object e) {
    if (e is SocketException) {
      throw const ApiException('Tidak ada koneksi internet. Silakan periksa koneksi Anda.');
    }
    if (e is TimeoutException) {
      throw const ApiException('Koneksi ke server terputus (Timeout). Silakan coba lagi.');
    }
    if (e is ApiException) {
      throw e;
    }
    throw ApiException('Terjadi kesalahan jaringan: ${e.toString().replaceAll("Exception: ", "")}');
  }

  static Future<http.Response> _get(
    String path, {
    Map<String, String>? queryParameters,
    bool authenticated = true,
  }) async {
    try {
      return await _client
          .get(
            _uri(path, queryParameters),
            headers:
                authenticated
                    ? await _authHeaders()
                    : const {'Content-Type': 'application/json'},
          )
          .timeout(AppConfig.requestTimeout);
    } catch (e) {
      _handleNetworkError(e);
    }
  }

  static Future<http.Response> _post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    try {
      return await _client
          .post(
            _uri(path),
            headers:
                authenticated
                    ? await _authHeaders()
                    : const {'Content-Type': 'application/json'},
            body: jsonEncode(body ?? const <String, dynamic>{}),
          )
          .timeout(AppConfig.requestTimeout);
    } catch (e) {
      _handleNetworkError(e);
    }
  }

  static Future<http.Response> _put(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    try {
      return await _client
          .put(
            _uri(path),
            headers: await _authHeaders(),
            body: jsonEncode(body),
          )
          .timeout(AppConfig.requestTimeout);
    } catch (e) {
      _handleNetworkError(e);
    }
  }

  static Future<http.Response> _patch(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      return await _client
          .patch(
            _uri(path),
            headers: await _authHeaders(),
            body: jsonEncode(body ?? const <String, dynamic>{}),
          )
          .timeout(AppConfig.requestTimeout);
    } catch (e) {
      _handleNetworkError(e);
    }
  }

  static Future<String?> getToken() => SecureTokenStorage.readToken();

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('nama');
    await prefs.remove('email');
    await prefs.remove('lokasi');
    await prefs.remove('jenis_kopi');
    await prefs.remove('nama_alat');
    await SecureTokenStorage.clearToken();
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _post(
      '/auth/login',
      authenticated: false,
      body: {
        'email': email.trim(),
        'password': password,
      },
    );

    if (response.statusCode != 200) {
      throw ApiException(_errorMessage(response, 'Login gagal'));
    }

    final data = Map<String, dynamic>.from(_decodeBody(response));
    final token = data['token']?.toString();
    if (token == null || token.isEmpty) {
      throw const ApiException('Token login tidak ditemukan');
    }

    await SecureTokenStorage.saveToken(token);
    final user = await getCurrentUser();
    await _persistUserProfile(user);
    return {'token': token, 'user': user};
  }

  static Future<Map<String, dynamic>> register(
    String email,
    String password,
    String nama,
  ) async {
    final response = await _post(
      '/auth/register',
      authenticated: false,
      body: {
        'email': email.trim(),
        'password': password,
        'nama': nama.trim(),
      },
    );

    if (response.statusCode != 200) {
      throw ApiException(_errorMessage(response, 'Registrasi gagal'));
    }

    final body = _decodeBody(response);
    return body is Map<String, dynamic> ? body : <String, dynamic>{};
  }

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await _post(
      '/auth/forgot-password',
      authenticated: false,
      body: {'email': email.trim()},
    );

    if (response.statusCode != 202) {
      throw ApiException(_errorMessage(response, 'Permintaan reset password gagal'));
    }

    return Map<String, dynamic>.from(_decodeBody(response) ?? <String, dynamic>{});
  }

  static Future<Map<String, dynamic>> verifyResetCode(
    String email,
    String code,
  ) async {
    final response = await _post(
      '/auth/verify-reset-code',
      authenticated: false,
      body: {
        'email': email.trim(),
        'code': code.trim(),
      },
    );

    if (response.statusCode != 200) {
      throw ApiException(_errorMessage(response, 'Verifikasi kode reset gagal'));
    }

    return Map<String, dynamic>.from(_decodeBody(response) ?? <String, dynamic>{});
  }

  static Future<Map<String, dynamic>> resetPassword(
    String email,
    String resetSessionToken,
    String newPassword,
  ) async {
    final response = await _post(
      '/auth/reset-password',
      authenticated: false,
      body: {
        'email': email.trim(),
        'resetSessionToken': resetSessionToken,
        'newPassword': newPassword,
      },
    );

    if (response.statusCode != 200) {
      throw ApiException(_errorMessage(response, 'Reset password gagal'));
    }

    return Map<String, dynamic>.from(_decodeBody(response) ?? <String, dynamic>{});
  }

  static Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await _get('/auth/me');

    if (response.statusCode == 401) {
      return _handleUnauthorized(_errorMessage(response, 'Sesi login berakhir.'));
    }
    if (response.statusCode != 200) {
      throw ApiException(_errorMessage(response, 'Gagal mengambil profil pengguna'));
    }

    return Map<String, dynamic>.from(_decodeBody(response));
  }

  static Future<Map<String, dynamic>> updateCurrentUser({
    required String nama,
    String? lokasi,
    String? jenisKopi,
    String? namaAlat,
  }) async {
    final response = await _put(
      '/auth/me',
      body: {
        'nama': nama.trim(),
        'lokasi': lokasi?.trim(),
        'jenisKopi': jenisKopi?.trim(),
        'namaAlat': namaAlat?.trim(),
      },
    );

    if (response.statusCode == 401) {
      return _handleUnauthorized(_errorMessage(response, 'Sesi login berakhir.'));
    }
    if (response.statusCode != 200) {
      throw ApiException(_errorMessage(response, 'Gagal menyimpan profil pengguna'));
    }

    final body = Map<String, dynamic>.from(_decodeBody(response));
    await _persistUserProfile(body);
    return body;
  }

  static Future<void> logout() async {
    final response = await _post('/auth/logout');
    await clearSession();

    if (response.statusCode != 200 && response.statusCode != 401) {
      throw ApiException(_errorMessage(response, 'Logout gagal'));
    }
  }

  static Future<List<Map<String, dynamic>>> getNotifications({
    int page = 0,
    int size = 20,
  }) async {
    final response = await _get(
      '/notifications',
      queryParameters: {
        'page': '$page',
        'size': '$size',
        'sort': 'createdAt,desc',
      },
    );

    if (response.statusCode == 401) {
      return _handleUnauthorized(_errorMessage(response, 'Sesi login berakhir.'));
    }
    if (response.statusCode != 200) {
      throw ApiException(_errorMessage(response, 'Gagal mengambil notifikasi'));
    }

    final body = _decodeBody(response);
    final content =
        body is Map<String, dynamic> && body['content'] is List
            ? body['content'] as List<dynamic>
            : <dynamic>[];
    return content
        .whereType<Map>()
        .map((item) => _normalizeNotification(Map<String, dynamic>.from(item)))
        .toList();
  }

  static Future<int> getUnreadNotificationCount() async {
    final response = await _get('/notifications/unread-count');

    if (response.statusCode == 401) {
      return _handleUnauthorized(_errorMessage(response, 'Sesi login berakhir.'));
    }
    if (response.statusCode != 200) {
      throw ApiException(_errorMessage(response, 'Gagal mengambil jumlah notifikasi'));
    }

    final body = Map<String, dynamic>.from(_decodeBody(response) ?? <String, dynamic>{});
    return (body['unreadCount'] as num?)?.toInt() ?? 0;
  }

  static Future<Map<String, dynamic>> markNotificationRead(int id) async {
    final response = await _patch('/notifications/$id/read');

    if (response.statusCode == 401) {
      return _handleUnauthorized(_errorMessage(response, 'Sesi login berakhir.'));
    }
    if (response.statusCode != 200) {
      throw ApiException(_errorMessage(response, 'Gagal menandai notifikasi'));
    }

    return _normalizeNotification(
      Map<String, dynamic>.from(_decodeBody(response) ?? <String, dynamic>{}),
    );
  }

  static Future<int> markAllNotificationsRead() async {
    final response = await _patch('/notifications/read-all');

    if (response.statusCode == 401) {
      return _handleUnauthorized(_errorMessage(response, 'Sesi login berakhir.'));
    }
    if (response.statusCode != 200) {
      throw ApiException(_errorMessage(response, 'Gagal menandai semua notifikasi'));
    }

    final body = Map<String, dynamic>.from(_decodeBody(response) ?? <String, dynamic>{});
    return (body['updatedCount'] as num?)?.toInt() ?? 0;
  }

  static Future<Map<String, dynamic>> getLatestSensor() async {
    final response = await _get('/sensor/latest');

    if (response.statusCode == 401) {
      return _handleUnauthorized(_errorMessage(response, 'Sesi login berakhir.'));
    }
    if (response.statusCode != 200) {
      throw ApiException(_errorMessage(response, 'Gagal mengambil data sensor terbaru'));
    }

    final data = _decodeBody(response);
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Format data sensor tidak valid');
    }
    return _normalizeSensor(data);
  }

  static Future<List<dynamic>> getRiwayatSensor({int size = 50}) async {
    final response = await _get(
      '/sensor',
      queryParameters: {
        'page': '0',
        'size': '$size',
        'sort': 'createdAt,desc',
      },
    );

    if (response.statusCode == 401) {
      return _handleUnauthorized(_errorMessage(response, 'Sesi login berakhir.'));
    }
    if (response.statusCode != 200) {
      throw ApiException(_errorMessage(response, 'Gagal mengambil riwayat sensor'));
    }

    final data = _decodeBody(response);
    final List<dynamic> rows;
    if (data is Map<String, dynamic> && data['content'] is List) {
      rows = data['content'] as List<dynamic>;
    } else if (data is List) {
      rows = data;
    } else {
      rows = [];
    }

    return rows
        .whereType<Map>()
        .map((item) => _normalizeSensor(Map<String, dynamic>.from(item)))
        .toList();
  }

  static Future<Map<String, dynamic>?> getFirstSensor() async {
    final response = await _get(
      '/sensor',
      queryParameters: {
        'page': '0',
        'size': '1',
        'sort': 'createdAt,asc',
      },
    );

    if (response.statusCode == 401) {
      return _handleUnauthorized(_errorMessage(response, 'Sesi login berakhir.'));
    }
    if (response.statusCode != 200) {
      throw ApiException(_errorMessage(response, 'Gagal mengambil data sensor pertama'));
    }

    final data = _decodeBody(response);
    final List<dynamic> rows;
    if (data is Map<String, dynamic> && data['content'] is List) {
      rows = data['content'] as List<dynamic>;
    } else if (data is List) {
      rows = data;
    } else {
      rows = [];
    }

    if (rows.isEmpty || rows.first is! Map) {
      return null;
    }

    return _normalizeSensor(Map<String, dynamic>.from(rows.first));
  }

  static Future<Map<String, dynamic>> getDeviceStatus() async {
    final response = await _get('/sensor/device/status');

    if (response.statusCode == 401) {
      return _handleUnauthorized(_errorMessage(response, 'Sesi login berakhir.'));
    }
    if (response.statusCode != 200) {
      throw ApiException(_errorMessage(response, 'Gagal mengambil status device'));
    }

    return Map<String, dynamic>.from(_decodeBody(response));
  }

  static Future<Map<String, dynamic>> getActuatorStatus() async {
    final response = await _get('/sensor/actuator/status');

    if (response.statusCode == 401) {
      return _handleUnauthorized(_errorMessage(response, 'Sesi login berakhir.'));
    }
    if (response.statusCode != 200) {
      throw ApiException(_errorMessage(response, 'Gagal mengambil status aktuator'));
    }

    return Map<String, dynamic>.from(_decodeBody(response));
  }

  static Future<Map<String, dynamic>> setActuator(String actuator, bool enabled) async {
    final response = await _post(
      '/sensor/actuator/$actuator',
      body: {'enabled': enabled},
    );

    if (response.statusCode == 401) {
      return _handleUnauthorized(_errorMessage(response, 'Sesi login berakhir.'));
    }
    if (response.statusCode != 200) {
      throw ApiException(_errorMessage(response, 'Gagal mengirim perintah $actuator'));
    }

    return Map<String, dynamic>.from(_decodeBody(response));
  }

  static Future<Map<String, dynamic>> setDeviceMode(String mode) async {
    final response = await _post(
      '/sensor/device/mode',
      body: {'mode': mode},
    );

    if (response.statusCode == 401) {
      return _handleUnauthorized(_errorMessage(response, 'Sesi login berakhir.'));
    }
    if (response.statusCode != 200) {
      throw ApiException(_errorMessage(response, 'Gagal mengubah mode device'));
    }

    return Map<String, dynamic>.from(_decodeBody(response));
  }
}
