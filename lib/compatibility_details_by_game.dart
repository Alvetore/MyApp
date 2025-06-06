import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/sheet_service.dart';
import 'measurement_form.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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

  /// Загружает данные замеров из всех устройств (листов) и группирует
  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedDevices = prefs.getStringList(DeviceSettingsScreen.prefsKey) ?? [];

      // Если ничего не выбрано — подтянуть все доступные устройства (по умолчанию)
      List<String> devices = savedDevices;
      if (devices.isEmpty) {
        devices = await _svc.fetchDevices();
      }

      // Параллельно загружаем замеры по каждому устройству
      final allRecords = <MeasurementRecord>[];
      for (final device in devices) {
        try {
          final records = await _svc.fetchMeasurementsForDevice(device);
          allRecords.addAll(records.where((r) => r.steamId == widget.steamId));
        } catch (e) {
          // Если не удалось получить с устройства — просто скипаем (например, если лист пустой)
        }
      }

      // Группируем по устройству и профилю
      final data = <String, Map<String, List<MeasurementRecord>>>{};
      for (final r in allRecords) {
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
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(widget.gameName)),
      body: _buildBody(loc),
      floatingActionButton: FloatingActionButton(
        tooltip: loc.addMeasurementTooltip,
        child: const Icon(Icons.add),
        onPressed: _onAddMeasurement,
      ),
    );
  }

  Widget _buildBody(AppLocalizations loc) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('${loc.errorPrefix}: $_error'));
    if (_data.isEmpty) return Center(child: Text(loc.noMeasurementsForGame));

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
                title: Text('$profile — ${avgFps.toStringAsFixed(1)} ${loc.fps}'),
                subtitle: Text(loc.measurementsCount(count)),
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
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text('${loc.measurements}: $profile')),
      body: ListView.builder(
        itemCount: records.length,
        itemBuilder: (_, i) {
          final r = records[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text('${r.fps.toStringAsFixed(1)} ${loc.fps}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${loc.device}: ${r.device}'),
                  Text('${loc.user}: ${r.submittedBy}'),
                  const SizedBox(height: 4),
                  Text('${loc.comment}: ${r.comment.isNotEmpty ? r.comment : loc.noComment}'),
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
