// lib/services/steam_models.dart

/// Модель одной игры для хранения и передачи
class GameRecord {
  final String appid;
  final String name;
  final int playtime; // минуты

  GameRecord({
    required this.appid,
    required this.name,
    required this.playtime,
  });

  /// Создание из JSON ответа Steam Web API
  factory GameRecord.fromSteamApi(Map<String, dynamic> json) {
    return GameRecord(
      appid: json['appid'].toString(),
      name: json['name'] as String,
      playtime: (json['playtime_forever'] as num?)?.toInt() ?? 0,
    );
  }

  /// Сериализация/десериализация в локальный кеш
  factory GameRecord.fromJson(Map<String, dynamic> json) {
    return GameRecord(
      appid: json['appid'] as String,
      name: json['name'] as String,
      playtime: (json['playtime'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'appid': appid,
    'name': name,
    'playtime': playtime,
  };
}
