import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atma_app/core/config/app_config.dart';
import 'package:atma_app/core/network/api_exception.dart';
import 'package:atma_app/core/storage/secure_token_storage.dart';
import 'package:atma_app/service/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SecureTokenStorage.useMemoryStorageForTesting(true);
    await SecureTokenStorage.clearToken();
    ApiService.resetClient();
  });

  tearDown(() {
    SecureTokenStorage.useMemoryStorageForTesting(false);
    ApiService.resetClient();
  });

  test('API base URL default uses production API host', () {
    expect(AppConfig.apiBaseUrl, 'https://api.atma.biz.id');
  });

  test('register sends request and returns response body', () async {
    ApiService.configureClient(
      MockClient((request) async {
        expect(request.url.path, '/auth/register');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['nama'], 'ATMA User');
        expect(body['email'], 'user@example.com');
        return http.Response(jsonEncode({'message': 'Register berhasil'}), 200);
      }),
    );

    final result = await ApiService.register(
      'user@example.com',
      'Password123',
      'ATMA User',
    );

    expect(result['message'], 'Register berhasil');
  });

  test('login success persists token and user profile', () async {
    var loginCalled = false;

    ApiService.configureClient(
      MockClient((request) async {
        if (request.url.path == '/auth/login') {
          loginCalled = true;
          return http.Response(jsonEncode({'token': 'jwt-token'}), 200);
        }
        if (request.url.path == '/auth/me') {
          expect(request.headers['authorization'], 'Bearer jwt-token');
          return http.Response(
            jsonEncode({
              'id': 1,
              'nama': 'ATMA User',
              'email': 'user@example.com',
              'lokasi': 'Sleman',
              'jenisKopi': 'Arabika',
              'namaAlat': 'ATMA-01',
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      }),
    );

    final result = await ApiService.login('user@example.com', 'Password123');

    expect(loginCalled, isTrue);
    expect(result['token'], 'jwt-token');
    expect(await SecureTokenStorage.readToken(), 'jwt-token');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('nama'), 'ATMA User');
    expect(prefs.getString('email'), 'user@example.com');
  });

  test('login failure maps backend error', () async {
    ApiService.configureClient(
      MockClient(
        (_) async => http.Response(
          jsonEncode({'message': 'Email atau password salah'}),
          401,
        ),
      ),
    );

    expect(
      () => ApiService.login('user@example.com', 'wrong-password'),
      throwsA(isA<ApiException>()),
    );
  });

  test('session restore reads saved token', () async {
    await SecureTokenStorage.saveToken('saved-token');
    expect(await ApiService.isLoggedIn(), isTrue);
  });

  test('unauthorized current user clears session', () async {
    await SecureTokenStorage.saveToken('expired-token');
    var unauthorizedCalled = false;
    ApiService.registerUnauthorizedHandler(() {
      unauthorizedCalled = true;
    });
    ApiService.configureClient(
      MockClient(
        (_) async =>
            http.Response(jsonEncode({'message': 'Sesi login berakhir'}), 401),
      ),
    );

    await expectLater(
      ApiService.getCurrentUser(),
      throwsA(isA<SessionExpiredException>()),
    );

    expect(unauthorizedCalled, isTrue);
    expect(await SecureTokenStorage.readToken(), isNull);
  });

  test('logout clears local session even if backend returns 200', () async {
    await SecureTokenStorage.saveToken('jwt-token');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nama', 'ATMA User');

    ApiService.configureClient(
      MockClient((request) async {
        expect(request.url.path, '/auth/logout');
        return http.Response(jsonEncode({'message': 'Logout berhasil'}), 200);
      }),
    );

    await ApiService.logout();

    expect(await SecureTokenStorage.readToken(), isNull);
    expect(prefs.getString('nama'), isNull);
  });

  test('forgot password, verify code, and reset password flows work', () async {
    ApiService.configureClient(
      MockClient((request) async {
        if (request.url.path == '/auth/forgot-password') {
          return http.Response(
            jsonEncode({
              'message': 'Jika email terdaftar, kode reset password akan dikirim',
            }),
            202,
          );
        }
        if (request.url.path == '/auth/verify-reset-code') {
          return http.Response(
            jsonEncode({
              'resetSessionToken': 'reset-session-token',
              'message': 'Kode reset valid',
            }),
            200,
          );
        }
        if (request.url.path == '/auth/reset-password') {
          return http.Response(
            jsonEncode({'message': 'Password berhasil diperbarui'}),
            200,
          );
        }
        return http.Response('Not Found', 404);
      }),
    );

    final forgot = await ApiService.forgotPassword('user@example.com');
    final verify = await ApiService.verifyResetCode('user@example.com', '123456');
    final reset = await ApiService.resetPassword(
      'user@example.com',
      'reset-session-token',
      'NewPassword123',
    );

    expect(forgot['message'], contains('Jika email terdaftar'));
    expect(verify['resetSessionToken'], 'reset-session-token');
    expect(reset['message'], 'Password berhasil diperbarui');
  });

  test('profile update persists local cache', () async {
    await SecureTokenStorage.saveToken('jwt-token');
    ApiService.configureClient(
      MockClient((request) async {
        expect(request.url.path, '/auth/me');
        expect(request.method, 'PUT');
        return http.Response(
          jsonEncode({
            'id': 1,
            'nama': 'Nama Baru',
            'email': 'user@example.com',
            'lokasi': 'Bantul',
            'jenisKopi': 'Robusta',
            'namaAlat': 'ATMA-02',
          }),
          200,
        );
      }),
    );

    final result = await ApiService.updateCurrentUser(
      nama: 'Nama Baru',
      lokasi: 'Bantul',
      jenisKopi: 'Robusta',
      namaAlat: 'ATMA-02',
    );

    expect(result['nama'], 'Nama Baru');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('nama'), 'Nama Baru');
    expect(prefs.getString('nama_alat'), 'ATMA-02');
  });

  test('notification list, unread count, and mark read parse correctly', () async {
    await SecureTokenStorage.saveToken('jwt-token');
    ApiService.configureClient(
      MockClient((request) async {
        if (request.url.path == '/notifications/unread-count') {
          return http.Response(jsonEncode({'unreadCount': 2}), 200);
        }
        if (request.url.path == '/notifications') {
          return http.Response(
            jsonEncode({
              'content': [
                {
                  'id': 7,
                  'eventKey': 'DEVICE_OFFLINE',
                  'title': 'Perangkat offline',
                  'message': 'Perangkat tidak mengirim telemetry.',
                  'severity': 'WARNING',
                  'read': false,
                  'createdAt': '2026-06-19T07:00:00',
                },
              ],
            }),
            200,
          );
        }
        if (request.url.path == '/notifications/7/read') {
          return http.Response(
            jsonEncode({
              'id': 7,
              'eventKey': 'DEVICE_OFFLINE',
              'title': 'Perangkat offline',
              'message': 'Perangkat tidak mengirim telemetry.',
              'severity': 'WARNING',
              'read': true,
              'createdAt': '2026-06-19T07:00:00',
              'readAt': '2026-06-19T07:05:00',
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      }),
    );

    final unreadCount = await ApiService.getUnreadNotificationCount();
    final notifications = await ApiService.getNotifications();
    final updated = await ApiService.markNotificationRead(7);

    expect(unreadCount, 2);
    expect(notifications.single['eventKey'], 'DEVICE_OFFLINE');
    expect(updated['read'], isTrue);
  });

  test('sensor latest and history normalize current contract', () async {
    await SecureTokenStorage.saveToken('jwt-token');
    ApiService.configureClient(
      MockClient((request) async {
        if (request.url.path == '/sensor/latest') {
          return http.Response(
            jsonEncode({
              'id': 1,
              'deviceId': 'atma-dryer-001',
              'temperature': 45.5,
              'humidity': 61.2,
              'heater': true,
              'kipas': false,
              'exhaust': true,
              'mode': 'AUTO',
              'createdAt': '2026-06-19T07:10:00',
            }),
            200,
          );
        }
        if (request.url.path == '/sensor') {
          return http.Response(
            jsonEncode({
              'content': [
                {
                  'id': 2,
                  'deviceId': 'atma-dryer-001',
                  'temperature': 44.0,
                  'humidity': 62.5,
                  'heater': 1,
                  'kipas': 0,
                  'exhaust': false,
                  'createdAt': null,
                },
              ],
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      }),
    );

    final latest = await ApiService.getLatestSensor();
    final history = await ApiService.getRiwayatSensor();

    expect(latest['suhu'], 45.5);
    expect(latest['kelembaban'], 61.2);
    expect(latest['mode'], 'AUTO');
    expect(history.single['createdAt'], isNull);
  });

  test('actuator command and device mode send authenticated requests', () async {
    await SecureTokenStorage.saveToken('jwt-token');
    ApiService.configureClient(
      MockClient((request) async {
        expect(request.headers['authorization'], 'Bearer jwt-token');
        if (request.url.path == '/sensor/actuator/heater') {
          return http.Response(jsonEncode({'status': 'COMMAND_SENT'}), 200);
        }
        if (request.url.path == '/sensor/device/mode') {
          return http.Response(jsonEncode({'mode': 'AUTO'}), 200);
        }
        return http.Response('Not Found', 404);
      }),
    );

    final actuatorResult = await ApiService.setActuator('heater', true);
    final modeResult = await ApiService.setDeviceMode('AUTO');

    expect(actuatorResult['status'], 'COMMAND_SENT');
    expect(modeResult['mode'], 'AUTO');
  });

  test('error response mapping prefers backend message', () async {
    ApiService.configureClient(
      MockClient(
        (_) async => http.Response(
          jsonEncode({'message': 'Backend unavailable'}),
          503,
        ),
      ),
    );

    expect(
      () => ApiService.register('user@example.com', 'Password123', 'ATMA User'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.toString(),
          'message',
          contains('Backend unavailable'),
        ),
      ),
    );
  });
}
