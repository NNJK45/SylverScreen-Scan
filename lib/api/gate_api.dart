import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiConfig {
  const ApiConfig._();
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5067',
  );
}

class GateApiException implements Exception {
  GateApiException(this.message, [this.statusCode]);
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class GateSession {
  const GateSession({
    required this.token,
    required this.name,
    required this.email,
    required this.role,
  });
  final String token;
  final String name;
  final String email;
  final String role;

  factory GateSession.fromJson(Map<String, dynamic> json) => GateSession(
    token: json['token'] as String,
    name: json['name'] as String? ?? 'Agent SylverScreen',
    email: json['email'] as String? ?? '',
    role: json['role'] as String? ?? '',
  );
}

class GateProjection {
  const GateProjection({
    required this.id,
    required this.movieName,
    required this.cinemaName,
    required this.hallName,
    required this.startsAt,
    required this.endsAt,
    required this.status,
  });
  final String id;
  final String movieName;
  final String cinemaName;
  final String hallName;
  final DateTime startsAt;
  final DateTime endsAt;
  final String status;

  factory GateProjection.fromJson(Map<String, dynamic> json) => GateProjection(
    id: json['id'] as String,
    movieName: json['movieName'] as String? ?? 'Projection',
    cinemaName: json['cinemaName'] as String? ?? '',
    hallName: json['hallName'] as String? ?? '',
    startsAt: DateTime.parse(json['startsAt'] as String).toLocal(),
    endsAt: DateTime.parse(json['endsAt'] as String).toLocal(),
    status: json['status'] as String? ?? 'upcoming',
  );
}

class GateTicket {
  const GateTicket({
    required this.id,
    required this.sequenceNumber,
    required this.customerName,
    required this.checkedIn,
    this.checkedInDate,
  });
  final String id;
  final int sequenceNumber;
  final String customerName;
  final bool checkedIn;
  final DateTime? checkedInDate;

  factory GateTicket.fromJson(Map<String, dynamic> json) => GateTicket(
    id: json['id'] as String,
    sequenceNumber: json['sequenceNumber'] as int? ?? 0,
    customerName: json['customerName'] as String? ?? 'Client',
    checkedIn: json['checkedIn'] as bool? ?? false,
    checkedInDate: json['checkedInDate'] == null
        ? null
        : DateTime.parse(json['checkedInDate'] as String).toLocal(),
  );
}

class GateScanResult {
  const GateScanResult({
    required this.status,
    required this.message,
    this.ticketId,
    this.movieName,
    this.cinemaName,
    this.hallName,
    this.customerName,
    this.totalAmount = 0,
    this.projectionStart,
    this.projectionEnd,
    this.firstCheckedInDate,
  });
  final String status;
  final String message;
  final String? ticketId;
  final String? movieName;
  final String? cinemaName;
  final String? hallName;
  final String? customerName;
  final double totalAmount;
  final DateTime? projectionStart;
  final DateTime? projectionEnd;
  final DateTime? firstCheckedInDate;

  factory GateScanResult.fromJson(Map<String, dynamic> json) => GateScanResult(
    status: json['status'] as String? ?? 'rejected',
    message: json['message'] as String? ?? 'Erreur de validation.',
    ticketId: json['ticketId'] as String?,
    movieName: json['movieName'] as String?,
    cinemaName: json['cinemaName'] as String?,
    hallName: json['hallName'] as String?,
    customerName: json['customerName'] as String?,
    totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
    projectionStart: json['projectionDate'] == null
        ? null
        : DateTime.parse(json['projectionDate'] as String).toLocal(),
    projectionEnd: json['projectionEndDate'] == null
        ? null
        : DateTime.parse(json['projectionEndDate'] as String).toLocal(),
    firstCheckedInDate: json['firstCheckedInDate'] == null
        ? null
        : DateTime.parse(json['firstCheckedInDate'] as String).toLocal(),
  );
}

class GateScanHistory {
  const GateScanHistory({
    required this.id,
    required this.status,
    required this.scannedAt,
    this.reason,
  });
  final String id;
  final String status;
  final DateTime scannedAt;
  final String? reason;

  factory GateScanHistory.fromJson(Map<String, dynamic> json) => GateScanHistory(
    id: json['id'] as String,
    status: json['result'] as String? ?? 'rejected',
    scannedAt: DateTime.parse(json['scannedAt'] as String).toLocal(),
    reason: json['reason'] as String?,
  );
}
class GateApi {
  GateApi({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  static const _storage = FlutterSecureStorage();

  Future<GateSession> login(String email, String password) async {
    final body = await _send(
      'POST',
      '/api/gate/auth/login',
      body: {'email': email, 'password': password},
    );
    final session = GateSession.fromJson(_data(body) as Map<String, dynamic>);
    await _storage.write(key: 'gate_access_token', value: session.token);
    return session;
  }

  Future<void> logout() => _storage.delete(key: 'gate_access_token');

  Future<String?> rememberedEmail() => _storage.read(key: 'gate_remembered_email');

  Future<void> saveRememberedEmail(String? email) => email == null
      ? _storage.delete(key: 'gate_remembered_email')
      : _storage.write(key: 'gate_remembered_email', value: email);

  Future<bool> darkModeEnabled() async =>
      (await _storage.read(key: 'gate_dark_mode')) == 'true';

  Future<void> saveDarkMode(bool enabled) =>
      _storage.write(key: 'gate_dark_mode', value: enabled.toString());

  Future<String> preferredLanguage() async =>
      await _storage.read(key: 'gate_language') ?? 'fr';

  Future<void> savePreferredLanguage(String language) =>
      _storage.write(key: 'gate_language', value: language);

  Future<List<GateProjection>> projections(String token) async {
    final body = await _send('GET', '/api/gate/projections', token: token);
    return (_data(body) as List)
        .cast<Map<String, dynamic>>()
        .map(GateProjection.fromJson)
        .toList();
  }

  Future<List<GateTicket>> tickets(
    String token,
    String projectionId, {
    String? status,
    String? search,
  }) async {
    final query = <String, String>{};
    if (status != null) query['status'] = status;
    if (search != null && search.trim().isNotEmpty)
      query['search'] = search.trim();
    final suffix = query.isEmpty ? '' : '?${Uri(queryParameters: query).query}';
    final body = await _send(
      'GET',
      '/api/gate/projections/$projectionId/tickets$suffix',
      token: token,
    );
    return (_data(body) as List)
        .cast<Map<String, dynamic>>()
        .map(GateTicket.fromJson)
        .toList();
  }

  Future<List<GateScanHistory>> scans(String token) async {
    final body = await _send('GET', '/api/gate/scans?take=50', token: token);
    return (_data(body) as List)
        .cast<Map<String, dynamic>>()
        .map(GateScanHistory.fromJson)
        .toList();
  }
  Future<GateScanResult> scan(
    String token,
    String value,
    String projectionId,
  ) async {
    final body = await _send(
      'POST',
      '/api/gate/scan',
      token: token,
      body: {'token': value, 'projectionId': projectionId},
    );
    return GateScanResult.fromJson(_data(body) as Map<String, dynamic>);
  }

  Future<GateScanResult> checkIn(String token, String ticketId) async {
    final body = await _send(
      'POST',
      '/api/gate/tickets/$ticketId/check-in',
      token: token,
    );
    return GateScanResult.fromJson(_data(body) as Map<String, dynamic>);
  }

  Future<dynamic> _send(
    String method,
    String path, {
    String? token,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final headers = <String, String>{'Accept': 'application/json'};
    if (body != null) headers['Content-Type'] = 'application/json';
    if (token != null) headers['Authorization'] = 'Bearer $token';
    late http.Response response;
    try {
      response = switch (method) {
        'GET' => await _client.get(uri, headers: headers),
        'POST' => await _client.post(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        ),
        _ => throw UnsupportedError(method),
      };
    } catch (_) {
      throw GateApiException(
        'Impossible de joindre l’API SylverScreen. Vérifiez que le backend est démarré.',
      );
    }
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GateApiException(
        _message(decoded) ?? 'La requête a échoué.',
        response.statusCode,
      );
    }
    return decoded;
  }

  dynamic _data(dynamic response) {
    if (response is Map<String, dynamic> && response['data'] != null)
      return response['data'];
    throw GateApiException(_message(response) ?? 'Réponse API invalide.');
  }

  String? _message(dynamic response) =>
      response is Map<String, dynamic> ? response['message'] as String? : null;
}

