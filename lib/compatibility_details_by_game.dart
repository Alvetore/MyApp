import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/sheet_service.dart';
import 'measurement_form.dart';

/// Экран подробностей по игре: группы замеров по устройствам и профилям
class CompatibilityDetailsByGame extends StatefulWidget {
  final String steamId;
  final String gameName;

  const CompatibilityDetailsByGame({
    Key? key,
    required this.steamId,
    required this.gameName,
  }) : super(key: key);

  @override
  _CompatibilityDetailsByGameState createState() => _CompatibilityDetailsByGameState();
}

class _CompatibilityDetailsByGameState extends State<CompatibilityDetailsByGame> {
  final SheetService _svc = SheetService();
  bool _loading = true;
  String? _error;
  late Map<String, Map<String, List<MeasurementRecord>>> _data;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Загружает данные замеров из сервиса и обновляет состояние
  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedDevices = prefs.getStringList(DeviceSettingsScreen.prefsKey) ?? [];

      final allRecords = await _svc.fetchMeasurements();
      final records = allRecords.where((r) => r.steamId == widget.steamId).toList();

      final devices = savedDevices.isNotEmpty
          ? savedDevices
          : records.map((r) => r.device).toSet().toList();

      final data = <String, Map<String, List<MeasurementRecord>>>{};
      for (final r in records) {
        if (!devices.contains(r.device)) continue;
        data.putIfAbsent(r.device, () => {});
        data[r.device]!.putIfAbsent(r.settingsProfile, () => []).add(r);
      }

      _data = data;
      setState(() => _loading = false);
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
      appBar: AppBar(title: Text(widget.gameName)),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Новый замер',
        child: const Icon(Icons.add),
        onPressed: _onAddMeasurement,
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('Ошибка: $_error'));
    if (_data.isEmpty) return const Center(child: Text('Нет данных для этой игре'));

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: _data.entries.map((deviceEntry) {
          final device = deviceEntry.key;
          final profiles = deviceEntry.value;
          return ExpansionTile(
            title: Text(device, style: const TextStyle(fontWeight: FontWeight.bold)),
            children: profiles.entries.map((profileEntry) {
              final profile = profileEntry.key;
              final list = profileEntry.value;
              final count = list.length;
              final avgFps = list.map((e) => e.fps).reduce((a, b) => a + b) / count;
              return ListTile(
                title: Text('$profile — ${avgFps.toStringAsFixed(1)} FPS'),
                subtitle: Text('$count замеров'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileDetailsScreen(
                        profile: profile,
                        records: list,
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  /// Открывает форму и обрабатывает возвращённый новый замер
  Future<void> _onAddMeasurement() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDevices = prefs.getStringList(DeviceSettingsScreen.prefsKey) ?? [];
    final device = savedDevices.isNotEmpty ? savedDevices.first : null;
    if (device == null) return;

    // Открываем MeasurementForm и ждём новый MeasurementRecord
    final newRecord = await Navigator.push<MeasurementRecord>(
      context,
      MaterialPageRoute(
        builder: (_) => MeasurementForm(
          device: device,
          presetSteamId: widget.steamId,
        ),
      ),
    );

    if (newRecord != null) {
      // Мгновенно добавляем запись в локальную карту данных
      setState(() {
        _data.putIfAbsent(newRecord.device, () => {});
        final profiles = _data[newRecord.device]!;
        profiles.putIfAbsent(newRecord.settingsProfile, () => []);
        profiles[newRecord.settingsProfile]!.add(newRecord);
      });
    }
  }
}

/// Экран подробных замеров для выбранного профиля
class ProfileDetailsScreen extends StatelessWidget {
  final String profile;
  final List<MeasurementRecord> records;

  const ProfileDetailsScreen({
    Key? key,
    required this.profile,
    required this.records,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Замеры: $profile')),
      body: ListView.builder(
        itemCount: records.length,
        itemBuilder: (_, i) {
          final r = records[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text('${r.fps.toStringAsFixed(1)} FPS'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Устройство: ${r.device}'),
                  Text('Пользователь: ${r.submittedBy}'),
                  const SizedBox(height: 4),
                  Text('Комментарий: ${r.comment}'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Константы настроек устройств
class DeviceSettingsScreen {
  static const prefsKey = 'selectedDevices';
}