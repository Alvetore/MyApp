import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import '../config.dart';

/// Запись одного замера из таблицы Measurements
class MeasurementRecord {
  final String submittedBy;
  final String device;
  final String steamId;
  final String settingsProfile;
  final double fps;
  final String comment;

  MeasurementRecord({
    required this.submittedBy,
    required this.device,
    required this.steamId,
    required this.settingsProfile,
    required this.fps,
    required this.comment,
  });
}

class SheetService {
  // CSV‐ссылки на листы (список устройств, ОС и профилей не меняются)
  final _devicesUrl = devicesCsvUrl;
  final _osUrl      = osCsvUrl;
  final _profilesUrl = profilesCsvUrl;

  /// Внутренний метод: загружает CSV и возвращает список строк первого столбца
  Future<List<String>> _fetchList(String url) async {
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) {
      throw Exception('Failed to load $url (status ${res.statusCode})');
    }
    final csvString = utf8.decode(res.bodyBytes);
    final rows = const CsvToListConverter().convert(csvString);
    return rows.skip(1).map((r) => r[0].toString()).toList();
  }

  /// Получить список устройств
  Future<List<String>> fetchDevices() => _fetchList(_devicesUrl);

  /// Получить список ОС
  Future<List<String>> fetchOperatingSystems() => _fetchList(_osUrl);

  /// Получить список профилей графики
  Future<List<String>> fetchSettingsProfiles() =>
      _fetchList(_profilesUrl);

  /// Загрузить замеры с листа для конкретного устройства
  Future<List<MeasurementRecord>> fetchMeasurementsForDevice(String deviceName) async {
    final sheetId = '<ТВОЙ_SHEET_ID>'; // Лучше вынести в config.dart
    final url =
        'https://docs.google.com/spreadsheets/d/$sheetId/gviz/tq?tqx=out:csv&sheet=${Uri.encodeComponent(deviceName)}';

    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) {
      throw Exception('Failed to load measurements for $deviceName (status ${res.statusCode})');
    }

    final csvString = utf8.decode(res.bodyBytes);
    final rows = const CsvToListConverter().convert(csvString);

    if (rows.isEmpty) return [];

    final header = rows.first.map((e) => e.toString()).toList();

    final idxSubmittedBy = header.indexOf('SubmittedBy');
    final idxDevice = header.indexOf('Device');
    final idxSteamId = header.indexOf('SteamID');
    final idxProfile = header.indexOf('SettingsProfile');
    final idxFps = header.indexOf('FPS');
    final idxComment = header.indexOf('Comment');

    if ([idxSubmittedBy, idxDevice, idxSteamId, idxProfile, idxFps].any((i) => i < 0)) {
      throw Exception(
          'Не найдена одна из колонок (убедись, что заголовки: SubmittedBy, Device, SteamID, SettingsProfile, FPS)');
    }

    final data = <MeasurementRecord>[];
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length <= idxFps) continue;
      var rawFps = row[idxFps].toString().replaceAll(',', '.');
      final fpsValue = double.tryParse(rawFps) ?? 0.0;
      data.add(MeasurementRecord(
        submittedBy: row[idxSubmittedBy].toString(),
        device: row[idxDevice].toString(),
        steamId: row[idxSteamId].toString(),
        settingsProfile: row[idxProfile].toString(),
        fps: fpsValue,
        comment: idxComment >= 0 && idxComment < row.length ? row[idxComment].toString() : '',
      ));
    }

    return data;
  }
}
