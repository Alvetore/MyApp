import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import '../config.dart';

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
  // Ссылки на служебные листы
  final _devicesUrl   = devicesCsvUrl;
  final _osUrl        = osCsvUrl;
  final _profilesUrl  = profilesCsvUrl;

  // Получить список устройств
  Future<List<String>> fetchDevices() => _fetchList(_devicesUrl);

  // Получить список ОС
  Future<List<String>> fetchOperatingSystems() => _fetchList(_osUrl);

  // Получить список профилей графики
  Future<List<String>> fetchSettingsProfiles() => _fetchList(_profilesUrl);

  // Универсальный загрузчик для простых листов
  Future<List<String>> _fetchList(String url) async {
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) {
      throw Exception('Failed to load $url (status ${res.statusCode})');
    }
    final csvString = utf8.decode(res.bodyBytes);
    final rows = const CsvToListConverter().convert(csvString);
    return rows.skip(1).map((r) => r[0].toString()).toList();
  }

  /// Загрузить замеры с листа для конкретного устройства
  Future<List<MeasurementRecord>> fetchMeasurementsForDevice(String deviceName) async {
    // Используем sheetId из config.dart!
    final url =
        'https://docs.google.com/spreadsheets/d/$sheetId/gviz/tq?tqx=out:csv&sheet=${Uri.encodeComponent(deviceName)}';
    print('Загружаю CSV для устройства: $deviceName\nURL: $url');
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) {
      throw Exception('Failed to load measurements for $deviceName (status ${res.statusCode})');
    }

    final csvString = utf8.decode(res.bodyBytes);
    print('DEBUG: CSV raw:\n$csvString');

// 1. Явно определяем разделитель строк (eol)
// 2. Убираем BOM, если он есть
    final cleaned = csvString.replaceAll('\ufeff', ''); // убираем BOM если был
    final csvNormalized = cleaned.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

// 3. Парсим с правильным eol и настройками
    final rows = const CsvToListConverter(
      eol: '\n', // ЯВНО, чтобы даже если где-то смесь переносов, было корректно
      fieldDelimiter: ',', // по умолчанию, но можно явно указать
      shouldParseNumbers: false, // нам не нужно преобразование в числа автоматически
    ).convert(csvNormalized);

    print('DEBUG: Parsed ${rows.length} rows');
    for (int i = 0; i < rows.length; i++) {
      print('ROW[$i]: ${rows[i]}');
    }



    if (rows.isEmpty) return [];

    final header = rows.first.map((e) => e.toString().replaceAll('"', '')).toList();
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
