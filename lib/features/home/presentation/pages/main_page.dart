import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../../main.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../widgets/modern_bottom_nav.dart';
import '../widgets/account_switcher.dart';
import 'home_page.dart';
import 'attendance_page.dart';
import 'profile_page.dart';

class MainPage extends StatefulWidget {
  final String currentLanguage;
  final List<Map<String, dynamic>> accounts;
  final String? activeAccountId;
  final Function(String) onLanguageChanged;
  final Function(List<Map<String, dynamic>>, String?) onAccountsChanged;

  const MainPage({
    super.key,
    required this.currentLanguage,
    required this.accounts,
    required this.activeAccountId,
    required this.onLanguageChanged,
    required this.onAccountsChanged,
  });

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  String? _companyId;
  bool _hasCompany = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _checkUserCompany();
  }

  void _initializeControllers() {
    _pageController = PageController();
    _fabAnimationController = AnimationController(
      duration: AppConstants.normalAnimation,
      vsync: this,
    );
    _fabAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    ));
    _fabAnimationController.forward();
  }

  Future<void> _checkUserCompany() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final userResponse = await supabase
          .from('users')
          .select('company_id')
          .eq('id', userId)
          .maybeSingle();

      if (userResponse != null && userResponse['company_id'] != null) {
        setState(() {
          _companyId = userResponse['company_id'];
          _hasCompany = true;
        });
      }
    } catch (e) {
      print('Error checking user company: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _translate(String key) {
    return AppLocalizations.translate(key, widget.currentLanguage);
  }

  void _onTabChanged(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: AppConstants.normalAnimation,
      curve: Curves.easeInOut,
    );
  }

  Future<void> _showAccountSwitcher() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AccountSwitcher(
        currentLanguage: widget.currentLanguage,
        accounts: widget.accounts,
        activeAccountId: widget.activeAccountId,
        onAccountChanged: widget.onAccountsChanged,
        onAddAccount: () {
          Navigator.pop(context);
          // Navigate to login page to add new account
        },
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
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

    return Scaffold(
      appBar: _buildAppBar(),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        children: [
          HomePage(
            currentLanguage: widget.currentLanguage,
            hasCompany: _hasCompany,
            companyId: _companyId,
          ),
          AttendancePage(
            currentLanguage: widget.currentLanguage,
            companyId: _companyId,
          ),
          ProfilePage(
            currentLanguage: widget.currentLanguage,
            hasCompany: _hasCompany,
            onLanguageChanged: widget.onLanguageChanged,
          ),
        ],
      ),
      bottomNavigationBar: ModernBottomNav(
        currentIndex: _currentIndex,
        onTabChanged: _onTabChanged,
        translate: _translate,
      ),
      floatingActionButton: _currentIndex == 0
          ? ScaleTransition(
              scale: _fabAnimation,
              child: FloatingActionButton(
                onPressed: () {
                  // Navigate to QR scanner
                },
                backgroundColor: AppTheme.primaryColor,
                child: const Icon(
                  CupertinoIcons.qrcode_viewfinder,
                  color: AppTheme.textPrimary,
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(_getPageTitle()),
      actions: [
        GestureDetector(
          onTap: _showAccountSwitcher,
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primaryColor,
              backgroundImage: widget.accounts.isNotEmpty &&
                      widget.accounts
                          .firstWhere(
                            (acc) => acc['id'] == widget.activeAccountId,
                            orElse: () => {},
                          )
                          .containsKey('avatar_url')
                  ? NetworkImage(widget.accounts
                      .firstWhere(
                        (acc) => acc['id'] == widget.activeAccountId,
                        orElse: () => {'avatar_url': null},
                      )['avatar_url'])
                  : null,
              child: widget.accounts.isEmpty ||
                      !widget.accounts
                          .firstWhere(
                            (acc) => acc['id'] == widget.activeAccountId,
                            orElse: () => {},
                          )
                          .containsKey('avatar_url')
                  ? const Icon(
                      CupertinoIcons.person_fill,
                      color: AppTheme.textPrimary,
                      size: 20,
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  String _getPageTitle() {
    switch (_currentIndex) {
      case 0:
        return _translate('home');
      case 1:
        return _translate('attendance');
      case 2:
        return _translate('profile');
      default:
        return _translate('home');
    }
  }
}