// lib/services/steam_models.dart
import 'dart:convert';

class GameRecord {
  final int appid;
  final String name;
  final int playtime;

  GameRecord({
    required this.appid,
    required this.name,
    required this.playtime,
  });

  /// Из ответа Steam Web API
  factory GameRecord.fromSteamApi(Map<String, dynamic> json) => GameRecord(
    appid: json['appid'] as int,
    name: json['name'] as String,
    // если вам не нужен playtime, можно поставить 0
    playtime: (json['playtime_forever'] as num).toInt(),
  );

  /// Для сохранения в SharedPreferences
  Map<String, dynamic> toJson() => {
    'appid': appid,
    'name': name,
    'playtime': playtime,
  };

  factory GameRecord.fromJson(Map<String, dynamic> json) => GameRecord(
    appid: json['appid'] as int,
    name: json['name'] as String,
    playtime: json['playtime'] as int,
  );
}
