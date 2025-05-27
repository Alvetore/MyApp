import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_screen.dart';
import 'services/sheet_service.dart';  // MeasurementRecord, DeviceSettingsScreen.prefsKey
import 'services/api_service.dart';    // Measurement, ApiService
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
    final loc = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final prefs = await SharedPreferences.getInstance();
    String userNick = prefs.getString('userNick') ?? '';
    if (userNick.trim().isEmpty) userNick = 'Anonymous';

    final meas = Measurement(
      submittedBy:     userNick,
      device:          _selectedDevice!,
      os:              _selectedOs!,
      steamId:         _steamIdCtrl.text,
      settingsProfile: _selectedProfile!,
      fps:             double.parse(_fpsCtrl.text.replaceAll(',', '.')),
      comment:         _commentCtrl.text,
      sheet: _selectedDevice!,
    );

    final success = await ApiService().sendMeasurement(meas);

    setState(() => _loading = false);

    if (success) {
      final record = MeasurementRecord(
        steamId:         meas.steamId,
        device:          meas.device,
        settingsProfile: meas.settingsProfile,
        fps:             meas.fps,
        comment:         meas.comment,
        submittedBy:     meas.submittedBy,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.measurementSent)),
      );
      Navigator.pop<MeasurementRecord>(context, record);
    } else {
      setState(() => _error = loc.measurementSendFailed);
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
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.newMeasurement)),
      body: _error != null
          ? Center(child: Text('${loc.error}: $_error'))
          : (_devices.isEmpty || _oss.isEmpty || _profiles.isEmpty)
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_devices.length > 1) ...[
                DropdownButtonFormField<String>(
                  value: _selectedDevice,
                  decoration: InputDecoration(labelText: loc.device),
                  items: _devices
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedDevice = v),
                ),
                const SizedBox(height: 12),
              ],

              DropdownButtonFormField<String>(
                value: _selectedOs,
                decoration: InputDecoration(labelText: loc.os),
                items: _oss
                    .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedOs = v),
                validator: (v) => v == null ? loc.chooseOs : null,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _selectedProfile,
                decoration: InputDecoration(labelText: loc.profile),
                items: _profiles
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedProfile = v),
                validator: (v) => v == null ? loc.chooseProfile : null,
              ),
              const SizedBox(height: 12),

              if (widget.presetSteamId == null) ...[
                TextFormField(
                  controller: _steamIdCtrl,
                  decoration: InputDecoration(labelText: loc.steamId),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty ? loc.enterSteamId : null,
                ),
                const SizedBox(height: 12),
              ],

              TextFormField(
                controller: _fpsCtrl,
                decoration: InputDecoration(labelText: loc.fps),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final f = double.tryParse(v?.replaceAll(',', '.') ?? '');
                  return f == null ? loc.invalidFps : null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _commentCtrl,
                decoration: InputDecoration(labelText: loc.commentOptional),
                keyboardType: TextInputType.multiline,
                maxLines: null,
              ),
              const SizedBox(height: 20),

              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _submit,
                child: Text(loc.send),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
