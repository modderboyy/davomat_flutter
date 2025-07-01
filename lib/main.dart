import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:convert';

import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'features/auth/presentation/pages/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  await initializeDateFormatting();
  runApp(const ModernAttendanceApp());
}

final supabase = Supabase.instance.client;

class ModernAttendanceApp extends StatefulWidget {
  const ModernAttendanceApp({super.key});

  @override
  State<ModernAttendanceApp> createState() => _ModernAttendanceAppState();
}

class _ModernAttendanceAppState extends State<ModernAttendanceApp> {
  String _currentLanguage = 'en';
  List<Map<String, dynamic>> _accounts = [];
  String? _activeAccountId;

  @override
  void initState() {
    super.initState();
    _loadLanguagePreference();
    _loadAccounts();
  }

  Future<void> _loadLanguagePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentLanguage = prefs.getString('language') ?? 'en';
    });
  }

  Future<void> _loadAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final accountsJson = prefs.getString('saved_accounts') ?? '[]';
    final activeAccountId = prefs.getString('active_account_id');
    
    setState(() {
      _accounts = List<Map<String, dynamic>>.from(jsonDecode(accountsJson));
      _activeAccountId = activeAccountId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Modern Attendance System',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: AuthGate(
        currentLanguage: _currentLanguage,
        accounts: _accounts,
        activeAccountId: _activeAccountId,
        onLanguageChanged: (language) {
          setState(() => _currentLanguage = language);
        },
        onAccountsChanged: (accounts, activeId) {
          setState(() {
            _accounts = accounts;
            _activeAccountId = activeId;
          });
        },
      ),
    );
  }
}