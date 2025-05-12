import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'import_profile_screen.dart';
import 'config.dart';
import 'services/sheet_service.dart';

/// Экран «Настройки» приложения
/// Включает настройку темы, ника пользователя, импорт библиотеки,
/// очистку кэша и выбор устройств.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _themeKey = 'themeMode';
  static const _nickKey = 'userNick';

  ThemeMode _themeMode = ThemeMode.dark;
  late TextEditingController _nickController;

  @override
  void initState() {
    super.initState();
    _nickController = TextEditingController();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final storedTheme = prefs.getString(_themeKey);
    final storedNick = prefs.getString(_nickKey) ?? '';
    ThemeMode mode;
    switch (storedTheme) {
      case 'light':
        mode = ThemeMode.light;
        break;
      case 'system':
        mode = ThemeMode.system;
        break;
      default:
        mode = ThemeMode.dark;
    }
    setState(() {
      _themeMode = mode;
      _nickController.text = storedNick;
      themeNotifier.value = _themeMode;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, _themeMode.toString().split('.').last);
    await prefs.setString(_nickKey, _nickController.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Настройки сохранены')),
    );
  }

  @override
  void dispose() {
    _nickController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'Сохранить настройки',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Тема приложения', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          RadioListTile<ThemeMode>(
            title: const Text('Светлая'),
            value: ThemeMode.light,
            groupValue: _themeMode,
            onChanged: (v) => setState(() { _themeMode = v!; themeNotifier.value = _themeMode; }),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Тёмная'),
            value: ThemeMode.dark,
            groupValue: _themeMode,
            onChanged: (v) => setState(() { _themeMode = v!; themeNotifier.value = _themeMode; }),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Системная'),
            value: ThemeMode.system,
            groupValue: _themeMode,
            onChanged: (v) => setState(() { _themeMode = v!; themeNotifier.value = _themeMode; }),
          ),
          const Divider(),
          TextField(
            controller: _nickController,
            decoration: const InputDecoration(
              labelText: 'Ник пользователя',
              helperText: 'Будет использоваться при отправке замеров',
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.import_contacts),
            title: const Text('Импорт библиотеки Steam'),
            onTap: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const ImportProfileScreen()),
              );
              if (result == true && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Библиотека импортирована')),
                );
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: const Text('Очистить кэш'),
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('importedGames');
              await prefs.remove(DeviceSettingsScreen.prefsKey);
              await prefs.remove(_nickKey);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Локальные данные очищены')),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.devices),
            title: const Text('Выбор устройств'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DeviceSettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Экран выбора устройств (отдельное окно)
class DeviceSettingsScreen extends StatefulWidget {
  static const prefsKey = 'selectedDevices';
  const DeviceSettingsScreen({Key? key}) : super(key: key);

  @override
  State<DeviceSettingsScreen> createState() => _DeviceSettingsScreenState();
}

class _DeviceSettingsScreenState extends State<DeviceSettingsScreen> {
  final SheetService _sheetService = SheetService();
  List<String> _devices = [];
  Set<String> _selected = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    try {
      final list = await _sheetService.fetchDevices();
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(DeviceSettingsScreen.prefsKey) ?? [];
      setState(() {
        _devices = list;
        _selected = saved.toSet();
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _saveDevices() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(DeviceSettingsScreen.prefsKey, _selected.toList());
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Устройства сохранены')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Выбор устройств'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveDevices,
            tooltip: 'Сохранить устройства',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text('Ошибка: $_error'))
          : ListView(
        children: _devices.map((d) {
          return CheckboxListTile(
            title: Text(d),
            value: _selected.contains(d),
            onChanged: (v) => setState(() {
              if (v == true) _selected.add(d);
              else _selected.remove(d);
            }),
          );
        }).toList(),
      ),
    );
  }
}
