import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'import_profile_screen.dart';
import 'config.dart';
import 'services/sheet_service.dart';

// languageNotifier — глобальный ValueNotifier<String> из main.dart/config.dart

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _themeKey = 'themeMode';
  static const _nickKey = 'userNick';
  static const _steamNickKey = 'importedSteamNick';

  ThemeMode _themeMode = ThemeMode.dark;
  late TextEditingController _nickController;
  String _selectedLanguage = 'system';

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
    final steamNick = prefs.getString(_steamNickKey) ?? '';
    final storedLang = prefs.getString('appLanguage') ?? 'system';

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
      // Используем: пользовательский ник > ник из Steam > пусто
      _nickController.text = storedNick.isNotEmpty ? storedNick : (steamNick.isNotEmpty ? steamNick : '');
      _selectedLanguage = storedLang;
      themeNotifier.value = _themeMode;
      languageNotifier.value = _selectedLanguage;
    });
  }

  Future<void> _saveNick(String nick) async {
    final prefs = await SharedPreferences.getInstance();
    // Если пусто — сохраняем Anonymous
    String finalNick = nick.trim().isEmpty ? 'Anonymous' : nick.trim();
    await prefs.setString(_nickKey, finalNick);
  }

  @override
  void dispose() {
    _nickController.dispose();
    super.dispose();
  }

  void _showImportOptions() {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(loc.import_steam),
        children: [
          SimpleDialogOption(
            child: Text(loc.import_by_profile),
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Ник пользователя
          TextField(
            controller: _nickController,
            decoration: InputDecoration(
              labelText: loc.user_nick,
              helperText: loc.user_nick_helper,
            ),
            onEditingComplete: () {
              // Автоматическое сохранение
              FocusScope.of(context).unfocus(); // скрываем клавиатуру
              _saveNick(_nickController.text);
            },
            onSubmitted: (val) {
              _saveNick(val);
            },
          ),
          const SizedBox(height: 16),
          const Divider(),

          // Импорт библиотеки Steam
          ListTile(
            leading: const Icon(Icons.import_contacts),
            title: Text(loc.import_steam_library),
            onTap: _showImportOptions,
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
          const Divider(),

          // Тема приложения
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

          // Язык приложения
          Text(
            loc.language,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          RadioListTile<String>(
            title: Text(loc.language_system),
            value: 'system',
            groupValue: _selectedLanguage,
            onChanged: (v) {
              setState(() {
                _selectedLanguage = v!;
                languageNotifier.value = v;
              });
            },
          ),
          RadioListTile<String>(
            title: Text('English'),
            value: 'en',
            groupValue: _selectedLanguage,
            onChanged: (v) {
              setState(() {
                _selectedLanguage = v!;
                languageNotifier.value = v;
              });
            },
          ),
          RadioListTile<String>(
            title: Text('Русский'),
            value: 'ru',
            groupValue: _selectedLanguage,
            onChanged: (v) {
              setState(() {
                _selectedLanguage = v!;
                languageNotifier.value = v;
              });
            },
          ),
          const Divider(),

          // Очистка кэша
          ListTile(
            leading: const Icon(Icons.delete),
            title: Text(loc.clear_cache),
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(loc.cache_cleared)),
              );
              // После очистки настроек подгрузи их заново (чтобы не было пустого экрана)
              _loadSettings();
            },
          ),
        ],
      ),
    );
  }
}

// DeviceSettingsScreen — лейблы оставляем локализованными, остальное без изменений
class DeviceSettingsScreen extends StatefulWidget {
  static const prefsKey = 'selectedDevices';

  @override
  State<DeviceSettingsScreen> createState() => _DeviceSettingsScreenState();
}

class _DeviceSettingsScreenState extends State<DeviceSettingsScreen> {
  List<String> _devices = [];
  Set<String> _selectedDevices = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final svc = SheetService();
    final devices = await svc.fetchDevices();
    final saved = prefs.getStringList(DeviceSettingsScreen.prefsKey) ?? devices;
    setState(() {
      _devices = devices;
      _selectedDevices = saved.toSet();
    });
  }

  Future<void> _onChanged(bool? checked, String device) async {
    setState(() {
      if (checked == true) {
        _selectedDevices.add(device);
      } else {
        _selectedDevices.remove(device);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(DeviceSettingsScreen.prefsKey, _selectedDevices.toList());
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.device_settings)),
      body: _devices.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        children: _devices.map((d) {
          return CheckboxListTile(
            value: _selectedDevices.contains(d),
            title: Text(d),
            onChanged: (v) => _onChanged(v, d),
          );
        }).toList(),
      ),
    );
  }
}

