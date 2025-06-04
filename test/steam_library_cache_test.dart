import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:MyApp/services/steam_library_cache.dart';
import 'package:MyApp/services/steam_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SteamLibraryCache', () {
    late SteamLibraryCache cache;
    final games = [
      GameRecord(appid: '1', name: 'Game A', playtime: 10),
      GameRecord(appid: '2', name: 'Game B', playtime: 20),
    ];

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      cache = SteamLibraryCache();
    });

    test('save, load and clear games', () async {
      await cache.saveGames(games);

      final loaded = await cache.loadGames();
      expect(loaded.map((g) => g.toJson()).toList(),
          equals(games.map((g) => g.toJson()).toList()));

      await cache.clear();
      final afterClear = await cache.loadGames();
      expect(afterClear, isEmpty);
    });
  });
}
