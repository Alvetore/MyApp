import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Модель замера FPS, сериализуется для отправки на бэкенд
class Measurement {
  final String submittedBy;
  final String device;
  final String os;
  final String steamId;
  final String settingsProfile;
  final double fps;
  final String comment;

  Measurement({
    required this.submittedBy,
    required this.device,
    required this.os,
    required this.steamId,
    required this.settingsProfile,
    required this.fps,
    required this.comment,
  });

  Map<String, dynamic> toJson() {
    return {
      'SubmittedBy': submittedBy,
      'Device': device,
      'OS': os,
      'SteamID': steamId,
      'SettingsProfile': settingsProfile,
      'FPS': fps,
      'Comment': comment,
      'sheetName': device,
    };
  }
}

/// Сервис для отправки замеров на Google Apps Script
class ApiService {
  static const _endpoint =
      'https://script.google.com/macros/s/AKfycbwxJmqaZsm9q0y6hpaGty5ShWAv9ELk14oqRoBQDMH3lQZHr9sWttQZXY8wtEoXj1xi4w/exec';

  Future<bool> sendMeasurement(Measurement m) async {
    final body = m.toJson();
    late http.Response res;
    try {
      res = await http.post(
        Uri.parse(_endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
    } catch (e) {
      debugPrint('Error sending measurement: $e');
      return false;
    }
    // Любые коды 2xx и 3xx считаем успехом из-за редиректа
    if (res.statusCode >= 200 && res.statusCode < 400) {
      return true;
    } else {
      debugPrint('HTTP error: ${res.statusCode}\n${res.body}');
      return false;
    }
  }
}
