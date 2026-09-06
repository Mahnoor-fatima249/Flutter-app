import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

// Keys for SharedPreferences
const _kThemeKey = 'theme_mode';
const _kLanguageKey = 'language_index';
const _kProfileNameKey = 'profile_name';
const _kProfileEmailKey = 'profile_email';
const _kProfilePhoneKey = 'profile_phone';
const _kProfileCityKey = 'profile_city';
const _kProfileStylePrefKey = 'profile_style_pref';
const _kProfileBodyTypeKey = 'profile_body_type';
const _kSelectedStylesKey = 'selected_styles';
const _kSelectedColorsKey = 'selected_colors';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildSection(context, 'Account', [
              _buildTile(context, Icons.person_outline, 'Edit Profile', const EditProfileScreen()),
              _buildTile(context, Icons.style, 'Style Preferences', const StylePreferencesScreen()),
            ]),
            _buildSection(context, 'Preferences', [
              _buildTile(context, Icons.notifications_outlined, 'Notifications', const NotificationsScreen()),
              _buildTile(context, Icons.language, 'Language', const LanguageScreen()),
              _buildTile(context, Icons.dark_mode_outlined, 'Appearance', const AppearanceScreen()),
            ]),
            _buildSection(context, 'Data', [
              _buildTile(context, Icons.storage_outlined, 'Data & Storage', const DataStorageScreen()),
              _buildTile(context, Icons.cloud_outlined, 'Backup & Sync', const BackupScreen()),
              _buildTile(context, Icons.download_outlined, 'Export Data', const ExportScreen()),
            ]),
            _buildSection(context, 'Support', [
              _buildTile(context, Icons.help_outline, 'Help & Support', const HelpScreen()),
              _buildTile(context, Icons.feedback_outlined, 'Send Feedback', const FeedbackScreen()),
              _buildTile(context, Icons.star_outline, 'Rate App', null, onTapRateApp: true),
              _buildTile(context, Icons.info_outline, 'About', const AboutScreen()),
            ]),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: AppTheme.cardDecoration,
          child: Column(children: children),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTile(BuildContext context, IconData icon, String title, Widget? screen, {bool onTapRateApp = false}) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textSecondary),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textLight),
      onTap: onTapRateApp
          ? () async {
              final uri = Uri.parse('https://play.google.com/store/apps/details?id=com.stylemate.app');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                if (context.mounted) {
                  _showRatingDialog(context);
                }
              }
            }
          : screen != null
              ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen))
              : null,
    );
  }

  void _showRatingDialog(BuildContext context) {
    int rating = 0;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Rate StyleMate'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('How would you rate this app?'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => GestureDetector(
                  onTap: () => setDialogState(() => rating = i + 1),
                  child: Icon(
                    i < rating ? Icons.star : Icons.star_border,
                    color: AppTheme.primaryColor,
                    size: 40,
                  ),
                )),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                if (rating > 0) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setInt('app_rating', rating);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Thanks for rating $rating stars!'), backgroundColor: AppTheme.successColor),
                    );
                  }
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Individual Settings Screens ---

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _outfitReminders = true;
  bool _weatherAlerts = true;
  bool _weeklyTips = false;
  bool _laundryReminders = true;
  bool _shoppingDeals = false;
  bool _newFeatureAlerts = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications'), backgroundColor: AppTheme.backgroundColor, foregroundColor: AppTheme.textPrimary, elevation: 0),
      body: ListView(
        children: [
          _buildSwitch('Outfit Reminders', 'Daily outfit suggestions', _outfitReminders, (v) => setState(() => _outfitReminders = v)),
          _buildSwitch('Weather Alerts', 'Get notified about weather changes', _weatherAlerts, (v) => setState(() => _weatherAlerts = v)),
          _buildSwitch('Weekly Style Tips', 'Fashion tips every week', _weeklyTips, (v) => setState(() => _weeklyTips = v)),
          _buildSwitch('Laundry Reminders', 'Remind you to wash clothes', _laundryReminders, (v) => setState(() => _laundryReminders = v)),
          _buildSwitch('Shopping Deals', 'Offers from partner stores', _shoppingDeals, (v) => setState(() => _shoppingDeals = v)),
          const Divider(),
          _buildSwitch('New Feature Alerts', 'Get notified when new features arrive', _newFeatureAlerts, (v) => setState(() => _newFeatureAlerts = v)),
        ],
      ),
    );
  }

  Widget _buildSwitch(String title, String subtitle, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.primaryColor,
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stylePrefCtrl = TextEditingController();
  final _bodyTypeCtrl = TextEditingController();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    _nameCtrl.text = prefs.getString(_kProfileNameKey) ?? 'Style Enthusiast';
    _emailCtrl.text = prefs.getString(_kProfileEmailKey) ?? 'user@stylemate.com';
    _phoneCtrl.text = prefs.getString(_kProfilePhoneKey) ?? '+92 300 1234567';
    _cityCtrl.text = prefs.getString(_kProfileCityKey) ?? 'Lahore';
    _stylePrefCtrl.text = prefs.getString(_kProfileStylePrefKey) ?? 'Casual, Modern';
    _bodyTypeCtrl.text = prefs.getString(_kProfileBodyTypeKey) ?? 'Average';
    setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _stylePrefCtrl.dispose();
    _bodyTypeCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kProfileNameKey, _nameCtrl.text);
    await prefs.setString(_kProfileEmailKey, _emailCtrl.text);
    await prefs.setString(_kProfilePhoneKey, _phoneCtrl.text);
    await prefs.setString(_kProfileCityKey, _cityCtrl.text);
    await prefs.setString(_kProfileStylePrefKey, _stylePrefCtrl.text);
    await prefs.setString(_kProfileBodyTypeKey, _bodyTypeCtrl.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved!'), backgroundColor: AppTheme.successColor),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Profile'), backgroundColor: AppTheme.backgroundColor, foregroundColor: AppTheme.textPrimary, elevation: 0),
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile'), backgroundColor: AppTheme.backgroundColor, foregroundColor: AppTheme.textPrimary, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.person, size: 50, color: AppTheme.primaryColor),
                  ),
                  Positioned(bottom: 0, right: 0, child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _buildField('Name', _nameCtrl),
            _buildField('Email', _emailCtrl),
            _buildField('Phone', _phoneCtrl),
            _buildField('City', _cityCtrl),
            const SizedBox(height: 20),
            _buildField('Style Preference', _stylePrefCtrl),
            _buildField('Body Type', _bodyTypeCtrl),
            const SizedBox(height: 30),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('Save Profile'),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}

class StylePreferencesScreen extends StatefulWidget {
  const StylePreferencesScreen({super.key});
  @override
  State<StylePreferencesScreen> createState() => _StylePreferencesScreenState();
}

class _StylePreferencesScreenState extends State<StylePreferencesScreen> {
  final _styles = ['Casual', 'Formal', 'Sporty', 'Bohemian', 'Minimalist', 'Streetwear', 'Classic', 'Trendy'];
  final _selectedStyles = <String>{};
  final _availableColors = ['Black', 'White', 'Navy', 'Grey', 'Brown', 'Red', 'Blue', 'Green'];
  final _selectedColors = <String>{};

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final savedStyles = prefs.getStringList(_kSelectedStylesKey) ?? ['Casual', 'Trendy'];
    final savedColors = prefs.getStringList(_kSelectedColorsKey) ?? [];
    setState(() {
      _selectedStyles.addAll(savedStyles);
      _selectedColors.addAll(savedColors);
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kSelectedStylesKey, _selectedStyles.toList());
    await prefs.setStringList(_kSelectedColorsKey, _selectedColors.toList());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Style preferences saved!'), backgroundColor: AppTheme.successColor),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Style Preferences'), backgroundColor: AppTheme.backgroundColor, foregroundColor: AppTheme.textPrimary, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select your preferred styles', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10, runSpacing: 10,
              children: _styles.map((style) {
                final selected = _selectedStyles.contains(style);
                return ChoiceChip(
                  label: Text(style),
                  selected: selected,
                  onSelected: (s) => setState(() => s ? _selectedStyles.add(style) : _selectedStyles.remove(style)),
                  selectedColor: AppTheme.primaryColor,
                  labelStyle: TextStyle(color: selected ? Colors.white : AppTheme.textPrimary),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),
            const Text('Preferred Colors', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12, runSpacing: 12,
              children: _availableColors.map((c) {
                final isSelected = _selectedColors.contains(c);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (isSelected) {
                      _selectedColors.remove(c);
                    } else {
                      _selectedColors.add(c);
                    }
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: AppTheme.getColorFromName(c),
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: AppTheme.primaryColor, width: 3)
                          : null,
                      boxShadow: isSelected ? [
                        BoxShadow(color: AppTheme.primaryColor.withOpacity(0.4), blurRadius: 8, spreadRadius: 1),
                      ] : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _savePreferences,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Save Preferences'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});
  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  final _languages = ['English', 'Urdu', 'Hindi', 'Arabic', 'Turkish'];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _selectedIndex = prefs.getInt(_kLanguageKey) ?? 0);
  }

  Future<void> _saveLanguage(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLanguageKey, index);
    setState(() => _selectedIndex = index);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Language set to ${_languages[index]}'), backgroundColor: AppTheme.successColor),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Language'), backgroundColor: AppTheme.backgroundColor, foregroundColor: AppTheme.textPrimary, elevation: 0),
      body: ListView.builder(
        itemCount: _languages.length,
        itemBuilder: (ctx, i) => RadioListTile(
          title: Text(_languages[i]),
          value: i, groupValue: _selectedIndex,
          onChanged: (v) => _saveLanguage(v as int),
          activeColor: AppTheme.primaryColor,
        ),
      ),
    );
  }
}

class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({super.key});
  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  int _selectedMode = 0;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _selectedMode = prefs.getInt(_kThemeKey) ?? 0);
  }

  Future<void> _saveTheme(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kThemeKey, value);
    setState(() => _selectedMode = value);

    if (!mounted) return;

    Brightness brightness;
    Color scaffoldBg;
    Color textColor;
    Color appBarBg;
    Color cardColor;
    Color iconColor;
    Color dividerColor;

    switch (value) {
      case 1:
        brightness = Brightness.dark;
        scaffoldBg = const Color(0xFF121212);
        textColor = Colors.white;
        appBarBg = const Color(0xFF1E1E1E);
        cardColor = const Color(0xFF1E1E1E);
        iconColor = Colors.white70;
        dividerColor = Colors.white24;
        break;
      case 2:
        final platformBrightness = MediaQuery.platformBrightnessOf(context);
        final isDark = platformBrightness == Brightness.dark;
        brightness = isDark ? Brightness.dark : Brightness.light;
        scaffoldBg = isDark ? const Color(0xFF121212) : AppTheme.backgroundColor;
        textColor = isDark ? Colors.white : AppTheme.textPrimary;
        appBarBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        iconColor = isDark ? Colors.white70 : AppTheme.textSecondary;
        dividerColor = isDark ? Colors.white24 : AppTheme.dividerColor;
        break;
      default:
        brightness = Brightness.light;
        scaffoldBg = AppTheme.backgroundColor;
        textColor = AppTheme.textPrimary;
        appBarBg = Colors.white;
        cardColor = Colors.white;
        iconColor = AppTheme.textSecondary;
        dividerColor = AppTheme.dividerColor;
    }

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: brightness,
      systemNavigationBarColor: scaffoldBg,
      systemNavigationBarIconBrightness: brightness,
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value == 0 ? 'Light mode enabled' : value == 1 ? 'Dark mode enabled' : 'System default enabled'),
        backgroundColor: AppTheme.successColor,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appearance'), backgroundColor: AppTheme.backgroundColor, foregroundColor: AppTheme.textPrimary, elevation: 0),
      body: ListView(
        children: [
          RadioListTile(
            title: const Text('Light Mode'),
            subtitle: const Text('Classic light theme'),
            value: 0, groupValue: _selectedMode,
            onChanged: (v) => _saveTheme(v as int),
            activeColor: AppTheme.primaryColor,
          ),
          RadioListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Easy on the eyes'),
            value: 1, groupValue: _selectedMode,
            onChanged: (v) => _saveTheme(v as int),
            activeColor: AppTheme.primaryColor,
          ),
          RadioListTile(
            title: const Text('System Default'),
            subtitle: const Text('Follow device settings'),
            value: 2, groupValue: _selectedMode,
            onChanged: (v) => _saveTheme(v as int),
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }
}

class DataStorageScreen extends StatefulWidget {
  const DataStorageScreen({super.key});
  @override
  State<DataStorageScreen> createState() => _DataStorageScreenState();
}

class _DataStorageScreenState extends State<DataStorageScreen> {
  String _cacheSize = 'Calculating...';
  bool _autoDownload = true;
  bool _calculating = false;

  @override
  void initState() {
    super.initState();
    _calculateCacheSize();
  }

  Future<void> _calculateCacheSize() async {
    setState(() {
      _calculating = true;
      _cacheSize = 'Calculating...';
    });

    try {
      final tempDir = await getTemporaryDirectory();
      int totalSize = 0;
      final files = tempDir.listSync(recursive: true, followLinks: false);
      for (final file in files) {
        if (file is File) {
          totalSize += await file.length();
        }
      }
      setState(() {
        _cacheSize = _formatSize(totalSize);
        _calculating = false;
      });
    } catch (e) {
      setState(() {
        _cacheSize = '0.0 MB';
        _calculating = false;
      });
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Cache'),
        content: Text('Clear $_cacheSize of cached data?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final tempDir = await getTemporaryDirectory();
        final files = tempDir.listSync(recursive: true, followLinks: false);
        for (final file in files) {
          if (file is File) {
            await file.delete();
          }
        }
        await _calculateCacheSize();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cache cleared!'), backgroundColor: AppTheme.successColor),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to clear cache'), backgroundColor: AppTheme.errorColor),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data & Storage'), backgroundColor: AppTheme.backgroundColor, foregroundColor: AppTheme.textPrimary, elevation: 0),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Cache Size'),
            subtitle: Text(_cacheSize),
            trailing: _calculating
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : TextButton(onPressed: _clearCache, child: const Text('Clear')),
          ),
          const Divider(),
          const ListTile(title: Text('Images Stored'), subtitle: Text('24 items')),
          const Divider(),
          const ListTile(title: Text('Database Size'), subtitle: Text('1.2 MB')),
          const Divider(),
          SwitchListTile(
            title: const Text('Auto-download Images'),
            value: _autoDownload,
            onChanged: (v) => setState(() => _autoDownload = v),
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }
}

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});
  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  String _lastBackup = 'Never';
  bool _autoBackup = false;

  @override
  void initState() {
    super.initState();
    _loadBackupInfo();
  }

  Future<void> _loadBackupInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lastBackup = prefs.getString('last_backup_date') ?? 'Never';
      _autoBackup = prefs.getBool('auto_backup') ?? false;
    });
  }

  Future<void> _backupNow() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'wardrobe': prefs.getString('wardrobe_data') ?? '[]',
        'styles': prefs.getStringList(_kSelectedStylesKey) ?? [],
        'colors': prefs.getStringList(_kSelectedColorsKey) ?? [],
        'profile': {
          'name': prefs.getString(_kProfileNameKey) ?? '',
          'email': prefs.getString(_kProfileEmailKey) ?? '',
          'phone': prefs.getString(_kProfilePhoneKey) ?? '',
          'city': prefs.getString(_kProfileCityKey) ?? '',
        },
        'backupDate': DateTime.now().toIso8601String(),
      };

      final appDir = await getApplicationDocumentsDirectory();
      final backupFile = File('${appDir.path}/stylemate_backup.json');
      await backupFile.writeAsString(jsonEncode(data));

      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      await prefs.setString('last_backup_date', dateStr);

      setState(() => _lastBackup = dateStr);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup saved to ${backupFile.path}'), backgroundColor: AppTheme.successColor),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup failed'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  Future<void> _restoreBackup() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final backupFile = File('${appDir.path}/stylemate_backup.json');
      if (!await backupFile.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No backup found'), backgroundColor: AppTheme.warningColor),
          );
        }
        return;
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Restore Backup'),
          content: const Text('This will replace your current data. Continue?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restore')),
          ],
        ),
      );

      if (confirmed != true) return;

      final content = await backupFile.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      final prefs = await SharedPreferences.getInstance();
      if (data['wardrobe'] != null) {
        await prefs.setString('wardrobe_data', data['wardrobe']);
      }
      if (data['styles'] != null) {
        await prefs.setStringList(_kSelectedStylesKey, List<String>.from(data['styles']));
      }
      if (data['colors'] != null) {
        await prefs.setStringList(_kSelectedColorsKey, List<String>.from(data['colors']));
      }
      if (data['profile'] != null) {
        final profile = data['profile'] as Map<String, dynamic>;
        if (profile['name'] != null) await prefs.setString(_kProfileNameKey, profile['name']);
        if (profile['email'] != null) await prefs.setString(_kProfileEmailKey, profile['email']);
        if (profile['phone'] != null) await prefs.setString(_kProfilePhoneKey, profile['phone']);
        if (profile['city'] != null) await prefs.setString(_kProfileCityKey, profile['city']);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup restored successfully!'), backgroundColor: AppTheme.successColor),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restore failed'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Sync'), backgroundColor: AppTheme.backgroundColor, foregroundColor: AppTheme.textPrimary, elevation: 0),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Auto Backup'),
            subtitle: const Text('Weekly backup to local storage'),
            value: _autoBackup,
            onChanged: (v) async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('auto_backup', v);
              setState(() => _autoBackup = v);
            },
            activeColor: AppTheme.primaryColor,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.cloud_upload, color: AppTheme.primaryColor),
            title: const Text('Backup Now'),
            onTap: _backupNow,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.cloud_download, color: AppTheme.primaryColor),
            title: const Text('Restore from Backup'),
            onTap: _restoreBackup,
          ),
          const Divider(),
          ListTile(title: const Text('Last Backup'), subtitle: Text(_lastBackup)),
        ],
      ),
    );
  }
}

class ExportScreen extends StatelessWidget {
  const ExportScreen({super.key});

  Future<void> _exportCSV(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final styles = prefs.getStringList(_kSelectedStylesKey) ?? [];
      final colors = prefs.getStringList(_kSelectedColorsKey) ?? [];
      final name = prefs.getString(_kProfileNameKey) ?? 'User';

      final csv = StringBuffer();
      csv.writeln('StyleMate Wardrobe Export');
      csv.writeln('User,$name');
      csv.writeln('Export Date,${DateTime.now().toIso8601String()}');
      csv.writeln('');
      csv.writeln('Category,Item');
      csv.writeln('Preferred Styles,${styles.join("; ")}');
      csv.writeln('Preferred Colors,${colors.join("; ")}');
      csv.writeln('');
      csv.writeln('Profile Information');
      csv.writeln('Name,${prefs.getString(_kProfileNameKey) ?? ""}');
      csv.writeln('Email,${prefs.getString(_kProfileEmailKey) ?? ""}');
      csv.writeln('Phone,${prefs.getString(_kProfilePhoneKey) ?? ""}');
      csv.writeln('City,${prefs.getString(_kProfileCityKey) ?? ""}');
      csv.writeln('Style Preference,${prefs.getString(_kProfileStylePrefKey) ?? ""}');
      csv.writeln('Body Type,${prefs.getString(_kProfileBodyTypeKey) ?? ""}');

      final appDir = await getApplicationDocumentsDirectory();
      final file = File('${appDir.path}/stylemate_export.csv');
      await file.writeAsString(csv.toString());

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV exported to ${file.path}'),
            backgroundColor: AppTheme.successColor,
            action: SnackBarAction(label: 'Copy', textColor: Colors.white, onPressed: () async {
              await Clipboard.setData(ClipboardData(text: csv.toString()));
            }),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export failed'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export Data'), backgroundColor: AppTheme.backgroundColor, foregroundColor: AppTheme.textPrimary, elevation: 0),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.file_download, color: AppTheme.primaryColor),
            title: const Text('Export as CSV'),
            subtitle: const Text('Wardrobe data as spreadsheet'),
            onTap: () => _exportCSV(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.photo_library, color: AppTheme.primaryColor),
            title: const Text('Export Images'),
            subtitle: const Text('Download all clothing images'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Image export coming soon'), backgroundColor: AppTheme.warningColor),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: AppTheme.primaryColor),
            title: const Text('Export as PDF'),
            subtitle: const Text('Style report document'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PDF export coming soon'), backgroundColor: AppTheme.warningColor),
              );
            },
          ),
        ],
      ),
    );
  }
}

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});
  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  int? _expandedIndex;

  final _faqData = [
    {
      'q': 'How do I add clothes to my wardrobe?',
      'a': 'Go to the Wardrobe tab and tap the + button. You can take a photo or choose from your gallery. The AI will automatically categorize the item.',
    },
    {
      'q': 'How does the AI outfit recommendation work?',
      'a': 'Our AI considers your style preferences, the weather, and your existing wardrobe to suggest complete outfits. The more you use the app, the better it gets!',
    },
    {
      'q': 'Can I use the app offline?',
      'a': 'Yes! Most features work offline including wardrobe browsing and outfit recommendations. AI-powered features may require an internet connection.',
    },
    {
      'q': 'How do I change my style preferences?',
      'a': 'Go to Settings > Style Preferences. You can select your preferred styles and colors there. These preferences help the AI suggest better outfits.',
    },
    {
      'q': 'Is my data safe?',
      'a': 'Absolutely. Your data is stored locally on your device. You can create backups at any time through Settings > Backup & Sync.',
    },
  ];

  void _showUserGuideDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('User Guide'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _guideSection('1. Wardrobe Management', 'Add your clothing items by taking photos. The AI will identify and categorize them automatically.'),
              _guideSection('2. Outfit Recommendations', 'Get daily outfit suggestions based on weather, occasion, and your style preferences.'),
              VirtualTryOnGuideSection(),
              _guideSection('4. Voice Commands', 'Use voice commands to search your wardrobe or get outfit suggestions hands-free.'),
              _guideSection('5. AR Try-On', 'Use your camera to virtually try on outfits before wearing them.'),
            ],
          ),
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Got it!')),
        ],
      ),
    );
  }

  Widget _guideSection(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          Text(description, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Future<void> _openEmailSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@stylemate.com',
      query: 'subject=StyleMate Support Request&body=Hello, I need help with:',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No email app found. Contact support@stylemate.com'), backgroundColor: AppTheme.warningColor),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support'), backgroundColor: AppTheme.backgroundColor, foregroundColor: AppTheme.textPrimary, elevation: 0),
      body: ListView(
        children: [
          // FAQ Section Header
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text('Frequently Asked Questions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          ),
          // FAQ Items
          ...List.generate(_faqData.length, (i) {
            final isExpanded = _expandedIndex == i;
            return Column(
              children: [
                ListTile(
                  leading: Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: AppTheme.primaryColor),
                  title: Text(_faqData[i]['q']!, style: const TextStyle(fontWeight: FontWeight.w500)),
                  onTap: () => setState(() => _expandedIndex = isExpanded ? null : i),
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Text(_faqData[i]['a']!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5)),
                  ),
                  crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
                if (i < _faqData.length - 1) const Divider(height: 1),
              ],
            );
          }),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.book, color: AppTheme.primaryColor),
            title: const Text('User Guide'),
            onTap: _showUserGuideDialog,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.chat, color: AppTheme.primaryColor),
            title: const Text('Live Chat'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Live chat coming soon'), backgroundColor: AppTheme.warningColor),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.email, color: AppTheme.primaryColor),
            title: const Text('Email Support'),
            subtitle: const Text('support@stylemate.com'),
            onTap: _openEmailSupport,
          ),
        ],
      ),
    );
  }
}

class VirtualTryOnGuideSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('3. Virtual Try-On', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          const Text(
            'Select an outfit and tap "Try On" to see how it looks on you using AR technology.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});
  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _messageController = TextEditingController();
  final _subjectController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _sendFeedback() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your feedback'), backgroundColor: AppTheme.warningColor),
      );
      return;
    }

    final subject = _subjectController.text.trim().isNotEmpty ? _subjectController.text.trim() : 'App Feedback';
    final uri = Uri(
      scheme: 'mailto',
      path: 'feedback@stylemate.com',
      query: 'subject=$subject&body=${Uri.encodeComponent(message)}',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feedback submitted! Thank you.'), backgroundColor: AppTheme.successColor),
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No email app found. Please email feedback@stylemate.com'), backgroundColor: AppTheme.warningColor),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Feedback'), backgroundColor: AppTheme.backgroundColor, foregroundColor: AppTheme.textPrimary, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Subject', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(
                hintText: 'e.g. Bug report, Feature request...',
              ),
            ),
            const SizedBox(height: 16),
            const Text('Your Feedback', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Tell us what you think...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _sendFeedback,
                child: const Text('Submit Feedback'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About'), backgroundColor: AppTheme.backgroundColor, foregroundColor: AppTheme.textPrimary, elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 30),
          Center(child: Container(width: 80, height: 80, decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.checkroom, size: 40, color: Colors.white))),
          const SizedBox(height: 16),
          const Center(child: Text('StyleMate', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
          const Center(child: Text('AI Personal Stylist', style: TextStyle(color: AppTheme.textSecondary))),
          const SizedBox(height: 30),
          const ListTile(title: Text('Version'), trailing: Text('1.0.0')),
          const Divider(),
          const ListTile(title: Text('Build'), trailing: Text('2026.09')),
          const Divider(),
          const ListTile(title: Text('Flutter'), trailing: Text('3.44.9')),
          const Divider(),
          const ListTile(title: Text('License'), trailing: Text('MIT')),
          const Divider(),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                const Icon(Icons.person, size: 40, color: AppTheme.primaryColor),
                const SizedBox(height: 8),
                const Text(
                  'Developed by',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Mahnoor Fatima',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 4),
                const Text(
                  'AI Personal Stylist App',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}