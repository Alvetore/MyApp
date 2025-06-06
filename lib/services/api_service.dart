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
  final String sheet;

  Measurement({
    required this.submittedBy,
    required this.device,
    required this.os,
    required this.steamId,
    required this.settingsProfile,
    required this.fps,
    required this.comment,
    required this.sheet,
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
      'Sheet': sheet,
    };
  }
}

/// Сервис для отправки замеров на Google Apps Script
class ApiService {
  static const _endpoint =
      'https://script.google.com/macros/s/AKfycbwxJmqaZsm9q0y6hpaGty5ShWAv9ELk14oqRoBQDMH3lQZHr9sWttQZXY8wtEoXj1xi4w/exec';

  Future<bool> sendMeasurement(Measurement m) async {
    final body = m.toJson();
    print('POST MEASUREMENT: ' + jsonEncode(body));  // <-- дебаг тут

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

    print('RESPONSE: ${res.statusCode}');
    print('BODY: ${res.body}'); // <-- дебаг тут

    if (res.statusCode >= 200 && res.statusCode < 400) {
      return true;
    } else {
      debugPrint('HTTP error: ${res.statusCode}\n${res.body}');
      return false;
    }
  }

}
