import 'package:flutter/material.dart';
import 'services/sheet_service.dart';

class CompatibilityDetails extends StatefulWidget {
  final String device;

  const CompatibilityDetails({super.key, required this.device});

  @override
  State<CompatibilityDetails> createState() => _CompatibilityDetailsState();
}

class _CompatibilityDetailsState extends State<CompatibilityDetails> {
  final SheetService _svc = SheetService();
  bool _loading = true;
  String? _error;

  /// Структура: { steamId: { profile: { 'avg': double, 'count': int } } }
  late Map<String, Map<String, Map<String, num>>> _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final all = await _svc.fetchMeasurements();
      // Оставляем только замеры для нашего устройства
      final filtered = all.where((r) => r.device == widget.device);

      // Группируем по игре (SteamID) и профилю
      final Map<String, Map<String, List<double>>> temp = {};
      for (var r in filtered) {
        temp.putIfAbsent(r.steamId, () => {});
        temp[r.steamId]!
            .putIfAbsent(r.settingsProfile, () => [])
            .add(r.fps);
      }

      // Считаем avg и count
      _stats = {};
      temp.forEach((steamId, byProfile) {
        final Map<String, Map<String, num>> profileStats = {};
        byProfile.forEach((profile, fpsList) {
          final count = fpsList.length;
          final sum = fpsList.reduce((a, b) => a + b);
          profileStats[profile] = {
            'avg': sum / count,
            'count': count,
          };
        });
        _stats[steamId] = profileStats;
      });

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text('Совместимость на ${widget.device}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Ошибка: $_error'))
              : _stats.isEmpty
                  ? const Center(
                      child: Text(
                        'Нет данных для этого устройства',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView(
                      children: _stats.entries.map((gameEntry) {
                        final steamId = gameEntry.key;
                        final profiles = gameEntry.value;
                        return ExpansionTile(
                          title: Text('Игра SteamID: $steamId'),
                          children: profiles.entries.map((p) {
                            final avg = p.value['avg']!;
                            final count = p.value['count']!;
                            return ListTile(
                              title: Text(p.key),
                              subtitle: Text(
                                  'Средний FPS: ${avg.toStringAsFixed(1)} ($count замеров)'),
                            );
                          }).toList(),
                        );
                      }).toList(),
                    ),
    );
  }
}
