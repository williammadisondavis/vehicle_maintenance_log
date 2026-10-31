
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  AppSettings._();

  static final AppSettings instance = AppSettings._();

  bool darkMode = false;
  bool showCosts = true;
  bool maintenanceReminders = true;
  double warningMiles = 500;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    darkMode = prefs.getBool('darkMode') ?? false;
    showCosts = prefs.getBool('showCosts') ?? true;
    maintenanceReminders =
        prefs.getBool('maintenanceReminders') ?? true;
    warningMiles = prefs.getDouble('warningMiles') ?? 500;

    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    darkMode = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
  }

  Future<void> setShowCosts(bool value) async {
    showCosts = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showCosts', value);
  }

  Future<void> setReminders(bool value) async {
    maintenanceReminders = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('maintenanceReminders', value);
  }

  Future<void> setWarningMiles(double value) async {
    warningMiles = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('warningMiles', value);
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final settings = AppSettings.instance;

  @override
  void initState() {
    super.initState();
    settings.addListener(refresh);
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    settings.removeListener(refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Appearance',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SwitchListTile(
          title: const Text('Dark Mode'),
          subtitle: const Text('Use a dark color theme'),
          secondary: const Icon(Icons.dark_mode),
          value: settings.darkMode,
          onChanged: settings.setDarkMode,
        ),
        const Divider(),
        Text(
          'Maintenance Preferences',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Maintenance Warnings'),
          subtitle: const Text(
            'Show upcoming maintenance warnings in the planner',
          ),
          secondary: const Icon(Icons.notifications_outlined),
          value: settings.maintenanceReminders,
          onChanged: settings.setReminders,
        ),
        const SizedBox(height: 12),
        ListTile(
          title: const Text('Warning Distance'),
          subtitle: Text(
            'Warn when maintenance is within '
            '${settings.warningMiles.round()} miles',
          ),
        ),
        Slider(
          value: settings.warningMiles,
          min: 100,
          max: 2000,
          divisions: 19,
          label: '${settings.warningMiles.round()} miles',
          onChanged: settings.setWarningMiles,
        ),
        const Divider(),
        Text(
          'Display',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SwitchListTile(
          title: const Text('Show Service Costs'),
          subtitle: const Text(
            'Display maintenance spending on the dashboard',
          ),
          secondary: const Icon(Icons.attach_money),
          value: settings.showCosts,
          onChanged: settings.setShowCosts,
        ),
        const Divider(),
        const ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('Vehicle Maintenance Log'),
          subtitle: Text(
            'Settings are saved locally on this device.',
          ),
        ),
      ],
    );
  }
}
