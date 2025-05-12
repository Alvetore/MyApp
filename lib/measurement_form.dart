import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_screen.dart';
import 'services/sheet_service.dart';  // MeasurementRecord, DeviceSettingsScreen.prefsKey
import 'services/api_service.dart';    // Measurement, ApiService

/// Форма добавления замера FPS
/// При наличии сохранённых устройств показывает их, иначе полный список;
/// Если передан presetSteamId, поле SteamID скрыто и заполнено автоматически.
class MeasurementForm extends StatefulWidget {
  final String device;
  final String? presetSteamId;

  const MeasurementForm({
    Key? key,
    required this.device,
    this.presetSteamId,
  }) : super(key: key);

  @override
  _MeasurementFormState createState() => _MeasurementFormState();
}

class _MeasurementFormState extends State<MeasurementForm> {
  final _formKey = GlobalKey<FormState>();
  final _steamIdCtrl = TextEditingController();
  final _fpsCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();

  List<String> _devices = [];
  List<String> _oss = [];
  List<String> _profiles = [];

  String? _selectedDevice;
  String? _selectedOs;
  String? _selectedProfile;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedDevice = widget.device;
    if (widget.presetSteamId != null) {
      _steamIdCtrl.text = widget.presetSteamId!;
    }
    _loadLists();
  }

  Future<void> _loadLists() async {
    try {
      final svc = SheetService();
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(DeviceSettingsScreen.prefsKey) ?? [];

      // Устройства: из настроек, если есть, иначе с сервиса
      final devicesFromSvc = await svc.fetchDevices();
      final devices = (widget.presetSteamId != null && saved.isNotEmpty)
          ? saved
          : devicesFromSvc;

      final oss = await svc.fetchOperatingSystems();
      final profiles = await svc.fetchSettingsProfiles();

      setState(() {
        _devices = devices;
        _oss = oss;
        _profiles = profiles;

        // Подставляем первые варианты по умолчанию, если ещё null
        _selectedDevice ??= _devices.isNotEmpty ? _devices.first : null;
        _selectedOs ??= _oss.isNotEmpty ? _oss.first : null;
        _selectedProfile ??= _profiles.isNotEmpty ? _profiles.first : null;

        _error = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final prefs    = await SharedPreferences.getInstance();
    final userNick = prefs.getString('userNick') ?? 'Anonymous';

    // 1) Создаём DTO для отправки
    final meas = Measurement(
      submittedBy:     userNick,
      device:          _selectedDevice!,
      os:              _selectedOs!,
      steamId:         _steamIdCtrl.text,
      settingsProfile: _selectedProfile!,
      fps:             double.parse(_fpsCtrl.text.replaceAll(',', '.')),
      comment:         _commentCtrl.text,
    );

    // 2) Отправляем на сервер
    final success = await ApiService().sendMeasurement(meas);

    setState(() => _loading = false);

    if (success) {
      // 3) Собираем именно MeasurementRecord (поля без 'os')
      final record = MeasurementRecord(
        steamId:         meas.steamId,
        device:          meas.device,
        settingsProfile: meas.settingsProfile,
        fps:             meas.fps,
        comment:         meas.comment,
        submittedBy:     meas.submittedBy,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Замер успешно отправлен')),
      );

      // 4) Возвращаем record родителю
      Navigator.pop<MeasurementRecord>(context, record);
    } else {
      setState(() => _error = 'Не удалось отправить замер');
    }
  }

  @override
  void dispose() {
    _steamIdCtrl.dispose();
    _fpsCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Новый замер')),
      body: _error != null
          ? Center(child: Text('Ошибка: $_error'))
          : (_devices.isEmpty || _oss.isEmpty || _profiles.isEmpty)
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              //  Устройство (если несколько вариантов)
              if (_devices.length > 1) ...[
                DropdownButtonFormField<String>(
                  value: _selectedDevice,
                  decoration: const InputDecoration(labelText: 'Устройство'),
                  items: _devices
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedDevice = v),
                ),
                const SizedBox(height: 12),
              ],

              // ОС
              DropdownButtonFormField<String>(
                value: _selectedOs,
                decoration: const InputDecoration(labelText: 'OS'),
                items: _oss
                    .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedOs = v),
                validator: (v) => v == null ? 'Выберите ОС' : null,
              ),
              const SizedBox(height: 12),

              // Профиль
              DropdownButtonFormField<String>(
                value: _selectedProfile,
                decoration: const InputDecoration(labelText: 'Профиль'),
                items: _profiles
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedProfile = v),
                validator: (v) => v == null ? 'Выберите профиль' : null,
              ),
              const SizedBox(height: 12),

              // SteamID
              if (widget.presetSteamId == null) ...[
                TextFormField(
                  controller: _steamIdCtrl,
                  decoration: const InputDecoration(labelText: 'SteamID'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty ? 'Введите SteamID' : null,
                ),
                const SizedBox(height: 12),
              ],

              // FPS
              TextFormField(
                controller: _fpsCtrl,
                decoration: const InputDecoration(labelText: 'FPS'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final f = double.tryParse(v?.replaceAll(',', '.') ?? '');
                  return f == null ? 'Неверное значение FPS' : null;
                },
              ),
              const SizedBox(height: 12),

              // Комментарий
              TextFormField(
                controller: _commentCtrl,
                decoration: const InputDecoration(labelText: 'Комментарий (опционально)'),
                keyboardType: TextInputType.multiline,
                maxLines: null,
              ),
              const SizedBox(height: 20),

              // Отправка
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _submit,
                child: const Text('Отправить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
