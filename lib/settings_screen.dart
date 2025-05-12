import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'import_profile_screen.dart';
import 'steam_login_screen.dart';
import 'config.dart';
import 'services/sheet_service.dart';

/// Экран «Настройки» приложения
/// Включает настройку темы, ника пользователя, импорт библиотеки (двумя способами),
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
      themeNotifier.value = _themeMode;  // <-- топ-левел
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _themeKey,
      _themeMode.toString().split('.').last,
    );
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

  /// Диалог выбора метода импорта библиотеки
  void _showImportOptions() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Выберите метод импорта'),
        children: [
          SimpleDialogOption(
            child: const Text('По ссылке на профиль Steam'),
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
          SimpleDialogOption(
            child: const Text('Через Steam Login'),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SteamLoginScreen(),
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
          const Text(
            'Тема приложения',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Светлая'),
            value: ThemeMode.light,
            groupValue: _themeMode,
            onChanged: (v) => setState(() {
              _themeMode = v!;
              themeNotifier.value = _themeMode;
            }),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Тёмная'),
            value: ThemeMode.dark,
            groupValue: _themeMode,
            onChanged: (v) => setState(() {
              _themeMode = v!;
              themeNotifier.value = _themeMode;
            }),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Системная'),
            value: ThemeMode.system,
            groupValue: _themeMode,
            onChanged: (v) => setState(() {
              _themeMode = v!;
              themeNotifier.value = _themeMode;
            }),
          ),
          const Divider(),

          // Ник пользователя
          TextField(
            controller: _nickController,
            decoration: const InputDecoration(
              labelText: 'Ник пользователя',
              helperText: 'Будет использоваться при отправке замеров',
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),

          // Импорт библиотеки Steam
          ListTile(
            leading: const Icon(Icons.import_contacts),
            title: const Text('Импорт библиотеки Steam'),
            onTap: _showImportOptions,
          ),
          const Divider(),

          // Очистка кэша
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Очистить кэш'),
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Кэш очищен')),
              );
            },
          ),
          const Divider(),

          // Выбор устройств
          ListTile(
            leading: const Icon(Icons.devices),
            title: const Text('Настройка устройств'),
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

/// Экран выбора устройств
class DeviceSettingsScreen extends StatelessWidget {
  static const prefsKey = 'selectedDevices';

  const DeviceSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройка устройств')),
      body: FutureBuilder<List<String>>(
        future: SheetService().fetchDevices(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final devices = snap.data ?? [];
          return ListView(
            children: devices
                .map((d) => CheckboxListTile(
              value: true,
              title: Text(d),
              onChanged: (_) {},
            ))
                .toList(),
          );
        },
      ),
    );
  }
}
