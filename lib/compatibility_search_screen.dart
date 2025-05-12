import 'package:flutter/material.dart';
import 'services/sheet_service.dart';
import 'measurement_form.dart';
import 'game_search_screen.dart';
import 'compatibility_details_by_game.dart';

/// Экран выбора устройства для отправки или просмотра совместимости.
/// Если передан presetSteamId и forSubmission=false, после выбора устройства сразу откроются детали по этой игре.
class CompatibilitySearchScreen extends StatefulWidget {
  final bool forSubmission;
  final String? presetSteamId;
  final String? presetGameName;

  const CompatibilitySearchScreen({
    super.key,
    required this.forSubmission,
    this.presetSteamId,
    this.presetGameName,
  });

  @override
  State<CompatibilitySearchScreen> createState() => _CompatibilitySearchScreenState();
}

class _CompatibilitySearchScreenState extends State<CompatibilitySearchScreen> {
  final SheetService _svc = SheetService();
  List<String> _devices = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _svc.fetchDevices().then((list) {
      setState(() {
        _devices = list;
        _loading = false;
      });
    }).catchError((e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.forSubmission
            ? 'Добавить замер: выберите устройство'
            : 'Совместимость: выберите устройство'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text('Ошибка: $_error'))
          : ListView.builder(
        itemCount: _devices.length,
        itemBuilder: (ctx, i) {
          final device = _devices[i];
          return ListTile(
            leading: const Icon(Icons.devices),
            title: Text(device),
            onTap: () {
              if (widget.forSubmission) {
                // Переход к форме отправки замера
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MeasurementForm(device: device),
                  ),
                );
              } else if (widget.presetSteamId != null) {
                // Если есть presetSteamId, сразу показываем детали
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CompatibilityDetailsByGame(
                      device: device,
                      steamId: widget.presetSteamId!,
                      gameName: widget.presetGameName ?? '',
                    ),
                  ),
                );
              } else {
                // Переход к поиску игры
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GameSearchScreen(device: device),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}
