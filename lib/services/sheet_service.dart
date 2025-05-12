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
  // CSV‐ссылки на листы в твоей Google-таблице
  final _devicesUrl = devicesCsvUrl;
  final _osUrl      = osCsvUrl;
  final _profilesUrl = profilesCsvUrl;
  final _measurementsUrl = measurementsCsvUrl;

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

  /// Загрузить замеры и парсить в MeasurementRecord
  Future<List<MeasurementRecord>> fetchMeasurements() async {
    final res = await http.get(Uri.parse(_measurementsUrl));
    if (res.statusCode != 200) {
      throw Exception('Failed to load measurements (status ${res.statusCode})');
    }

    // Декодируем UTF-8
    final csvString = utf8.decode(res.bodyBytes);
    // Парсим весь CSV
    final rows = const CsvToListConverter().convert(csvString);

    if (rows.isEmpty) {
      throw Exception('CSV пустой!');
    }

    // Первая строка — заголовки
    final header = rows.first.map((e) => e.toString()).toList();
    print('🔍 CSV headers: $header');

    // Находим индексы нужных колонок
    final idxSubmittedBy   = header.indexOf('SubmittedBy');
    final idxDevice        = header.indexOf('Device');
    final idxSteamId       = header.indexOf('SteamID');
    final idxProfile       = header.indexOf('SettingsProfile');
    final idxFps           = header.indexOf('FPS');
    final idxComment       = header.indexOf('Comment');

    print('🔢 Indices → submittedBy:$idxSubmittedBy, device:$idxDevice, steamId:$idxSteamId, profile:$idxProfile, fps:$idxFps, comment:$idxComment');

    // Если какой-то индекс не найден, бросаем понятную ошибку
    if ([idxSubmittedBy, idxDevice, idxSteamId, idxProfile, idxFps]
        .any((i) => i < 0)) {
      throw Exception('Не найдена одна из колонок (убедись, что заголовки в таблице точно: SubmittedBy, Device, SteamID, SettingsProfile, FPS)');
    }

    // Теперь мапим каждую строку через найденные индексы
    final data = <MeasurementRecord>[];
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      // Защита: если строка короче, чем header
      if (row.length <= idxFps) continue;

      // Берём текстовое значение из ячейки
      var rawFps = row[idxFps].toString();
      // Заменяем запятую на точку, чтобы double.tryParse понял десятичную часть
      rawFps = rawFps.replaceAll(',', '.');
      // Теперь парсим в double
      final fpsValue = double.tryParse(rawFps) ?? 0.0;

      data.add(MeasurementRecord(
        submittedBy:   row[idxSubmittedBy].toString(),
        device:        row[idxDevice].toString(),
        steamId:       row[idxSteamId].toString(),
        settingsProfile: row[idxProfile].toString(),
        fps:           fpsValue,
        comment:       idxComment >= 0 && idxComment < row.length
            ? row[idxComment].toString()
            : '',
      ));
    }

    print('✅ Parsed ${data.length} measurement records');
    return data;
  }
}
