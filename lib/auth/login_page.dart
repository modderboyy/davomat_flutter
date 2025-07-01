import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../main.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/app_constants.dart';
import '../core/localization/app_localizations.dart';

class ModernLoginPage extends StatefulWidget {
  final String currentLanguage;
  final List<Map<String, dynamic>> accounts;
  final Function(String) onLanguageChanged;
  final Function(List<Map<String, dynamic>>, String?) onAccountsChanged;
  final VoidCallback onLoginSuccess;

  const ModernLoginPage({
    super.key,
    required this.currentLanguage,
    required this.accounts,
    required this.onLanguageChanged,
    required this.onAccountsChanged,
    required this.onLoginSuccess,
  });

  @override
  State<ModernLoginPage> createState() => _ModernLoginPageState();
}

class _ModernLoginPageState extends State<ModernLoginPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoginMode = true;
  bool _isLoading = false;
  bool _showForgotPassword = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _resetEmailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: AppConstants.normalAnimation,
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: AppConstants.slowAnimation,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _resetEmailController.dispose();
    super.dispose();
  }

  String _translate(String key) {
    return AppLocalizations.translate(key, widget.currentLanguage);
  }

  Future<void> _handleEmailLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar(_translate('fill_all_fields'), isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.session != null) {
        await _saveAccount(response.user!);
        widget.onLoginSuccess();
      }
    } on AuthException catch (e) {
      _showSnackBar(e.message, isError: true);
    } catch (e) {
      _showSnackBar(_translate('login_error'), isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSocialLogin(String provider) async {
    setState(() => _isLoading = true);

    try {
      if (provider == 'modder_auth') {
        _showSnackBar(_translate('coming_soon'), isError: false);
        return;
      }

      await supabase.auth.signInWithOAuth(
        Provider.values.firstWhere(
          (p) => p.name == provider,
          orElse: () => Provider.google,
        ),
      );
    } catch (e) {
      _showSnackBar(_translate('social_login_error'), isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    if (_resetEmailController.text.isEmpty) {
      _showSnackBar(_translate('enter_email'), isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await supabase.auth.resetPasswordForEmail(_resetEmailController.text.trim());
      _showSnackBar(_translate('reset_email_sent'), isError: false);
      setState(() => _showForgotPassword = false);
    } catch (e) {
      _showSnackBar(_translate('reset_error'), isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAccount(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = List<Map<String, dynamic>>.from(widget.accounts);
    
    final existingIndex = accounts.indexWhere((acc) => acc['id'] == user.id);
    
    final accountData = {
      'id': user.id,
      'email': user.email,
      'name': user.userMetadata?['full_name'] ?? user.email?.split('@')[0],
      'avatar_url': user.userMetadata?['avatar_url'],
      'last_login': DateTime.now().toIso8601String(),
    };

    if (existingIndex != -1) {
      accounts[existingIndex] = accountData;
    } else {
      accounts.add(accountData);
    }

    await prefs.setString('saved_accounts', jsonEncode(accounts));
    await prefs.setString('active_account_id', user.id);
    
    widget.onAccountsChanged(accounts, user.id);
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.errorColor : AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.normalRadius),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.largeSpacing),
              child: Column(
                children: [
                  const SizedBox(height: AppConstants.extraLargeSpacing),
                  _buildHeader(),
                  const SizedBox(height: AppConstants.extraLargeSpacing),
                  _buildModeSelector(),
                  const SizedBox(height: AppConstants.largeSpacing),
                  if (_showForgotPassword)
                    _buildForgotPasswordForm()
                  else
                    _buildLoginForm(),
                  const SizedBox(height: AppConstants.largeSpacing),
                  _buildLanguageSelector(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.accentColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppConstants.largeRadius),
          ),
          child: const Icon(
            CupertinoIcons.building_2_fill,
            color: AppTheme.textPrimary,
            size: 40,
          ),
        ),
        const SizedBox(height: AppConstants.normalSpacing),
        Text(
          _translate('app_name'),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: AppConstants.smallSpacing),
        Text(
          _translate('app_subtitle'),
          style: const TextStyle(
            fontSize: 16,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.normalRadius),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModeButton(
              title: _translate('login'),
              isSelected: _isLoginMode,
              onTap: () => setState(() {
                _isLoginMode = true;
                _showForgotPassword = false;
              }),
            ),
          ),
          Expanded(
            child: _buildModeButton(
              title: _translate('register'),
              isSelected: !_isLoginMode,
              onTap: () => setState(() => _isLoginMode = false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppConstants.fastAnimation,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.smallRadius),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    if (_isLoginMode) {
      return Column(
        children: [
          _buildEmailPasswordForm(),
          const SizedBox(height: AppConstants.normalSpacing),
          _buildSocialButtons(),
          const SizedBox(height: AppConstants.normalSpacing),
          _buildForgotPasswordButton(),
        ],
      );
    } else {
      return _buildSocialButtons();
    }
  }

  Widget _buildEmailPasswordForm() {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: _translate('email'),
            prefixIcon: const Icon(CupertinoIcons.mail),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: AppConstants.normalSpacing),
        TextField(
          controller: _passwordController,
          decoration: InputDecoration(
            labelText: _translate('password'),
            prefixIcon: const Icon(CupertinoIcons.lock),
          ),
          obscureText: true,
        ),
        const SizedBox(height: AppConstants.largeSpacing),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleEmailLogin,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_translate('login')),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Column(
      children: [
        if (!_isLoginMode) ...[
          Text(
            _translate('register_with_social'),
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: AppConstants.normalSpacing),
        ],
        _buildSocialButton(
          title: _translate('continue_with_google'),
          icon: CupertinoIcons.globe,
          onTap: () => _handleSocialLogin('google'),
        ),
        const SizedBox(height: AppConstants.normalSpacing),
        _buildSocialButton(
          title: _translate('continue_with_github'),
          icon: CupertinoIcons.device_laptop,
          onTap: () => _handleSocialLogin('github'),
        ),
        const SizedBox(height: AppConstants.normalSpacing),
        _buildSocialButton(
          title: _translate('continue_with_modder_auth'),
          icon: CupertinoIcons.shield,
          onTap: () => _handleSocialLogin('modder_auth'),
          isComingSoon: true,
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    bool isComingSoon = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : onTap,
        icon: Icon(icon),
        label: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title),
            if (isComingSoon) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _translate('soon'),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.backgroundColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: AppTheme.dividerColor),
        ),
      ),
    );
  }

  Widget _buildForgotPasswordButton() {
    return TextButton(
      onPressed: () => setState(() => _showForgotPassword = true),
      child: Text(
        _translate('forgot_password'),
        style: const TextStyle(color: AppTheme.textSecondary),
      ),
    );
  }

  Widget _buildForgotPasswordForm() {
    return Column(
      children: [
        Text(
          _translate('reset_password_title'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: AppConstants.smallSpacing),
        Text(
          _translate('reset_password_subtitle'),
          style: const TextStyle(color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppConstants.largeSpacing),
        TextField(
          controller: _resetEmailController,
          decoration: InputDecoration(
            labelText: _translate('email'),
            prefixIcon: const Icon(CupertinoIcons.mail),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: AppConstants.largeSpacing),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleForgotPassword,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_translate('send_reset_link')),
          ),
        ),
        const SizedBox(height: AppConstants.normalSpacing),
        TextButton(
          onPressed: () => setState(() => _showForgotPassword = false),
          child: Text(
            _translate('back_to_login'),
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.normalSpacing),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.normalRadius),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.globe, color: AppTheme.textSecondary),
          const SizedBox(width: AppConstants.normalSpacing),
          Expanded(
            child: Text(
              _translate('language'),
              style: const TextStyle(color: AppTheme.textPrimary),
            ),
          ),
          DropdownButton<String>(
            value: widget.currentLanguage,
            underline: const SizedBox(),
            dropdownColor: AppTheme.cardColor,
            items: const [
              DropdownMenuItem(value: 'en', child: Text('English')),
              DropdownMenuItem(value: 'uz', child: Text('O\'zbekcha')),
              DropdownMenuItem(value: 'ru', child: Text('Русский')),
            ],
            onChanged: (value) {
              if (value != null) {
                widget.onLanguageChanged(value);
              }
            },
          ),
        ],
      ),
    );
  }
}