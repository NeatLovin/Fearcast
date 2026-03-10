import 'package:flutter/material.dart';
import '../utilities/drawer_menu.dart';
import '../utilities/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../main.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  String _selectedLanguage = 'English';
  String _selectedScarySound = 'scream_sound';
  int _selectedInterval = 10;
  String _selectedFearfulSound = 'calm_sound';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;

@override
  void initState() {
    super.initState();
    _loadPreferences();
    _initializeDefaultPreferences();
  }

Future<void> triggerTestNotification(String channelId, String title, String body) async {
  await flutterLocalNotificationsPlugin.show(
    0,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        channelId, 
        channelId == 'calm_channel' ? 'Calm Notification' : 
        channelId == 'goofy_channel' ? 'Goofy Notification' :
        channelId == 'groovy_channel' ? 'Groovy Notification' : 'Scary Notification',
        channelDescription: 'Notification for testing $channelId',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
      ),
    ),
  );
}

Future<void> _loadPreferences() async {
    if (_userId == null) return;

    final doc = await _firestore.collection('settings').doc(_userId).get();
    if (doc.exists) {
      setState(() {
        _selectedLanguage = doc['userLang'] ?? 'English';
        _selectedScarySound = doc['userScarySound'] ?? 'scream_sound';
        _selectedFearfulSound = doc['userFearfulSound'] ?? 'calm_sound';
        _selectedInterval = doc['notificationInterval'] ?? 10;
      });
    }
  }

Future<void> _initializeDefaultPreferences() async {
    if (_userId == null) return;

    final doc = await _firestore.collection('settings').doc(_userId).get();
    if (!doc.exists) {
      await _firestore.collection('settings').doc(_userId).set({
        'userLang': _selectedLanguage,
        'userScarySound': _selectedScarySound,
        'userFearfulSound': _selectedFearfulSound,
        'notificationInterval': _selectedInterval,
      });
    }
  }

Future<void> _savePreference(String key, dynamic value) async {
    if (_userId == null) return;

    await _firestore.collection('settings').doc(_userId).set({
      key: value,
    }, SetOptions(merge: true));

    if (key == 'userLang') {
      Locale newLocale;
      switch (value) {
        case 'French':
          newLocale = Locale('fr');
          break;
        case 'German':
          newLocale = Locale('de');
          break;
        case 'Italian':
          newLocale = Locale('it');
          break;
        case 'Spanish':
          newLocale = Locale('es');
          break;
        case 'Portuguese':
          newLocale = Locale('pt');
          break;
        default:
          newLocale = Locale('en');
      }
      if (mounted) {
        MyApp.setLocale(context, newLocale);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings),
        backgroundColor: primaryColor,
      ),
      drawer: const DrawerMenu(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle(AppLocalizations.of(context)!.generalSettings, Icons.settings),
            Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSettingItem(
                      AppLocalizations.of(context)!.language,
                      AppLocalizations.of(context)!.chooseLanguage,
                      Icons.language,
                      DropdownButton<String>(
                        value: _selectedLanguage,
                        items: [
                          DropdownMenuItem(value: 'English', child: Text(AppLocalizations.of(context)!.english)),
                          DropdownMenuItem(value: 'French', child: Text(AppLocalizations.of(context)!.french)),
                          DropdownMenuItem(value: 'German', child: Text(AppLocalizations.of(context)!.german)),
                          DropdownMenuItem(value: 'Italian', child: Text(AppLocalizations.of(context)!.italian)),
                          DropdownMenuItem(value: 'Spanish', child: Text(AppLocalizations.of(context)!.spanish)),
                          DropdownMenuItem(value: 'Portuguese', child: Text(AppLocalizations.of(context)!.portuguese)),
                        ],
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedLanguage = newValue;
                            });
                            _savePreference('userLang', newValue);
                          }
                        },
                        style: TextStyle(color: errorColor, fontSize: 16),
                        dropdownColor: onPrimaryColor,
                        icon: Icon(Icons.arrow_drop_down, color: errorColor),
                        underline: Container(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle(AppLocalizations.of(context)!.notificationSettings, Icons.notifications),
            Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSettingItem(
                      AppLocalizations.of(context)!.scaryNotificationSound,
                      AppLocalizations.of(context)!.selectScarySound,
                      Icons.volume_up,
                      DropdownButton<String>(
                        value: _selectedScarySound,
                        items: [
                          DropdownMenuItem(value: 'scream_sound', child: Text('Scream')),
                          DropdownMenuItem(value: 'static_sound', child: Text('Static')),
                          DropdownMenuItem(value: 'creak_sound', child: Text('Creak')),
                        ],
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedScarySound = newValue;
                            });
                            _savePreference('userScarySound', newValue);
                            String channelId = newValue == 'scream_sound'
                                ? 'scream_channel'
                                : newValue == 'static_sound'
                                    ? 'static_channel'
                                    : 'creak_channel';
                            triggerTestNotification(channelId, 'Test Notification',
                                'Upcoming nothing. Just a test notification.');
                          }
                        },
                        style: TextStyle(color: errorColor, fontSize: 16),
                        dropdownColor: onPrimaryColor,
                        icon: Icon(Icons.arrow_drop_down, color: errorColor),
                        underline: Container(),
                      ),
                    ),
                    const Divider(),
                    _buildSettingItem(
                      AppLocalizations.of(context)!.fearfulNotificationSound,
                      AppLocalizations.of(context)!.chooseFearfulSound,
                      Icons.music_note,
                      DropdownButton<String>(
                        value: _selectedFearfulSound,
                        items: [
                          DropdownMenuItem(value: 'calm_sound', child: Text('Calm')),
                          DropdownMenuItem(value: 'groovy_sound', child: Text('Groovy')),
                          DropdownMenuItem(value: 'goofy_sound', child: Text('Goofy')),
                        ],
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedFearfulSound = newValue;
                            });
                            _savePreference('userFearfulSound', newValue);
                            String channelId = newValue == 'calm_sound'
                                ? 'calm_channel'
                                : newValue == 'groovy_sound'
                                    ? 'groovy_channel'
                                    : 'goofy_channel';
                            triggerTestNotification(channelId, 'Test Notification',
                                'Upcoming nothing. Just a test notification.');
                          }
                        },
                        style: TextStyle(color: errorColor, fontSize: 16),
                        dropdownColor: onPrimaryColor,
                        icon: Icon(Icons.arrow_drop_down, color: errorColor),
                        underline: Container(),
                      ),
                    ),
                    const Divider(),
                    _buildSettingItem(
                      AppLocalizations.of(context)!.notificationInterval,
                      AppLocalizations.of(context)!.setNotificationInterval,
                      Icons.timer,
                      DropdownButton<int>(
                        value: _selectedInterval,
                        items: [
                          DropdownMenuItem(value: 5, child: Text('5s')),
                          DropdownMenuItem(value: 10, child: Text('10s')),
                          DropdownMenuItem(value: 20, child: Text('20s')),
                          DropdownMenuItem(value: 30, child: Text('30s')),
                        ],
                        onChanged: (int? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedInterval = newValue;
                            });
                            _savePreference('notificationInterval', newValue);
                          }
                        },
                        style: TextStyle(color: errorColor, fontSize: 16),
                        dropdownColor: onPrimaryColor,
                        icon: Icon(Icons.arrow_drop_down, color: errorColor),
                        underline: Container(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      child: Row(
        children: [
          Icon(icon, color: primaryColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: primaryColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(String title, String subtitle, IconData icon, Widget trailing) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, right: 16.0),
                  child: Icon(icon, color: primaryColor.withOpacity(0.8), size: 24),
                ),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.2,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 120,
            margin: EdgeInsets.zero,
            padding: EdgeInsets.zero,
            child: Theme(
              data: Theme.of(context).copyWith(
                buttonTheme: const ButtonThemeData(
                  alignedDropdown: true,
                ),
              ),
              child: trailing,
            ),
          ),
        ],
      ),
    );
  }
}
