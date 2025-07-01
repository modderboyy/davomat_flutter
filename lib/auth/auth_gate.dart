import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../features/home/presentation/pages/main_page.dart';
import '../features/admin/presentation/pages/admin_main_page.dart';
import 'login_page.dart';

class AuthGate extends StatefulWidget {
  final String currentLanguage;
  final List<Map<String, dynamic>> accounts;
  final String? activeAccountId;
  final Function(String) onLanguageChanged;
  final Function(List<Map<String, dynamic>>, String?) onAccountsChanged;

  const AuthGate({
    super.key,
    required this.currentLanguage,
    required this.accounts,
    required this.activeAccountId,
    required this.onLanguageChanged,
    required this.onAccountsChanged,
  });

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    try {
      final session = supabase.auth.currentSession;
      
      if (session != null) {
        final userResponse = await supabase
            .from('users')
            .select('is_super_admin, is_active')
            .eq('id', session.user.id)
            .maybeSingle();

        if (userResponse != null) {
          final isActive = userResponse['is_active'] ?? true;
          final isSuperAdmin = userResponse['is_super_admin'] ?? false;

          if (isActive) {
            setState(() {
              _isLoggedIn = true;
              _isAdmin = isSuperAdmin;
            });
          } else {
            await supabase.auth.signOut();
          }
        }
      }
    } catch (e) {
      print('Auth check error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_isLoggedIn) {
      return ModernLoginPage(
        currentLanguage: widget.currentLanguage,
        accounts: widget.accounts,
        onLanguageChanged: widget.onLanguageChanged,
        onAccountsChanged: widget.onAccountsChanged,
        onLoginSuccess: () {
          _checkAuthState();
        },
      );
    }

    if (_isAdmin) {
      return AdminMainPage(
        currentLanguage: widget.currentLanguage,
        onLanguageChanged: widget.onLanguageChanged,
      );
    }

    return MainPage(
      currentLanguage: widget.currentLanguage,
      accounts: widget.accounts,
      activeAccountId: widget.activeAccountId,
      onLanguageChanged: widget.onLanguageChanged,
      onAccountsChanged: widget.onAccountsChanged,
    );
  }
}