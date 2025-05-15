import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'import_profile_screen.dart';
import 'config.dart';
import 'services/sheet_service.dart';

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
      SnackBar(content: Text(AppLocalizations.of(context)!.save_done)),
    );
  }

  @override
  void dispose() {
    _nickController.dispose();
    super.dispose();
  }

  void _showImportOptions() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(AppLocalizations.of(context)!.import_steam),
        children: [
          SimpleDialogOption(
            child: Text(AppLocalizations.of(context)!.import_by_url),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ImportProfileScreen(),
                ),
              );
            },
          ),
          // Если нужно добавить другие методы импорта, добавить тут
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.settings_title),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: loc.save,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            loc.theme,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          RadioListTile<ThemeMode>(
            title: Text(loc.theme_light),
            value: ThemeMode.light,
            groupValue: _themeMode,
            onChanged: (v) {
              setState(() {
                _themeMode = v!;
                themeNotifier.value = _themeMode;
              });
            },
          ),
          RadioListTile<ThemeMode>(
            title: Text(loc.theme_dark),
            value: ThemeMode.dark,
            groupValue: _themeMode,
            onChanged: (v) {
              setState(() {
                _themeMode = v!;
                themeNotifier.value = _themeMode;
              });
            },
          ),
          RadioListTile<ThemeMode>(
            title: Text(loc.theme_system),
            value: ThemeMode.system,
            groupValue: _themeMode,
            onChanged: (v) {
              setState(() {
                _themeMode = v!;
                themeNotifier.value = _themeMode;
              });
            },
          ),
          const Divider(),

          // Ник пользователя
          TextField(
            controller: _nickController,
            decoration: InputDecoration(
              labelText: loc.user_nick,
              helperText: loc.user_nick,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),

          // Импорт библиотеки Steam (выбор метода)
          ListTile(
            leading: const Icon(Icons.import_contacts),
            title: Text(loc.import_steam),
            onTap: _showImportOptions,
          ),
          const Divider(),

          // Очистка кэша
          ListTile(
            leading: const Icon(Icons.delete),
            title: Text(loc.cache_clear),
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(loc.cache_cleared)),
              );
            },
          ),
          const Divider(),

          // Настройка устройств
          ListTile(
            leading: const Icon(Icons.devices),
            title: Text(loc.device_settings),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DeviceSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// DeviceSettingsScreen — тут аналогично меняются тексты на локализованные

class DeviceSettingsScreen extends StatelessWidget {
  static const prefsKey = 'selectedDevices';

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.device_settings)),
      body: FutureBuilder<List<String>>(
        future: SheetService().fetchDevices(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final devices = snap.data ?? [];
          return ListView(
            children: devices.map((d) {
              return CheckboxListTile(
                value: true, // здесь логику отметки реализуйте по своему
                title: Text(d),
                onChanged: (v) {
                  // сохранить изменения
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
