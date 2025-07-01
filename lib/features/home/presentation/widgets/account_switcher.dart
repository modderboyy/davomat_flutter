import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../../main.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_localizations.dart';

class AccountSwitcher extends StatefulWidget {
  final String currentLanguage;
  final List<Map<String, dynamic>> accounts;
  final String? activeAccountId;
  final Function(List<Map<String, dynamic>>, String?) onAccountChanged;
  final VoidCallback onAddAccount;

  const AccountSwitcher({
    super.key,
    required this.currentLanguage,
    required this.accounts,
    required this.activeAccountId,
    required this.onAccountChanged,
    required this.onAddAccount,
  });

  @override
  State<AccountSwitcher> createState() => _AccountSwitcherState();
}

class _AccountSwitcherState extends State<AccountSwitcher>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: AppConstants.normalAnimation,
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  String _translate(String key) {
    return AppLocalizations.translate(key, widget.currentLanguage);
  }

  Future<void> _switchAccount(String accountId) async {
    try {
      // Find the account
      final account = widget.accounts.firstWhere(
        (acc) => acc['id'] == accountId,
        orElse: () => {},
      );

      if (account.isEmpty) return;

      // Sign out current user
      await supabase.auth.signOut();

      // Update active account
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_account_id', accountId);

      // Update accounts list with new last login
      final updatedAccounts = widget.accounts.map((acc) {
        if (acc['id'] == accountId) {
          acc['last_login'] = DateTime.now().toIso8601String();
        }
        return acc;
      }).toList();

      await prefs.setString('saved_accounts', jsonEncode(updatedAccounts));

      widget.onAccountChanged(updatedAccounts, accountId);

      // Close the modal
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_translate('account_switched')),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_translate('error_occurred')),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _removeAccount(String accountId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: Text(
          _translate('remove_account'),
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        content: Text(
          _translate('remove_account_confirmation'),
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              _translate('cancel'),
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              _translate('remove'),
              style: const TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final updatedAccounts = widget.accounts
          .where((acc) => acc['id'] != accountId)
          .toList();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_accounts', jsonEncode(updatedAccounts));

      String? newActiveId;
      if (widget.activeAccountId == accountId && updatedAccounts.isNotEmpty) {
        newActiveId = updatedAccounts.first['id'];
        await prefs.setString('active_account_id', newActiveId);
      } else if (widget.activeAccountId != accountId) {
        newActiveId = widget.activeAccountId;
      }

      widget.onAccountChanged(updatedAccounts, newActiveId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppConstants.largeRadius),
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: widget.accounts.isEmpty
                  ? _buildEmptyState()
                  : _buildAccountsList(),
            ),
            _buildAddAccountButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.largeSpacing),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.dividerColor),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppConstants.normalSpacing),
          Row(
            children: [
              const Icon(
                CupertinoIcons.person_2_fill,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: AppConstants.normalSpacing),
              Text(
                _translate('account_switcher'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.normalSpacing),
      itemCount: widget.accounts.length,
      itemBuilder: (context, index) {
        final account = widget.accounts[index];
        final isActive = account['id'] == widget.activeAccountId;

        return Container(
          margin: const EdgeInsets.only(bottom: AppConstants.normalSpacing),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(AppConstants.normalRadius),
            border: Border.all(
              color: isActive ? AppTheme.primaryColor : AppTheme.dividerColor,
              width: isActive ? 2 : 1,
            ),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor,
              backgroundImage: account['avatar_url'] != null
                  ? NetworkImage(account['avatar_url'])
                  : null,
              child: account['avatar_url'] == null
                  ? const Icon(
                      CupertinoIcons.person_fill,
                      color: AppTheme.textPrimary,
                    )
                  : null,
            ),
            title: Text(
              account['name'] ?? account['email'] ?? 'Unknown',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account['email'] ?? '',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                if (isActive)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _translate('current_account'),
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            trailing: isActive
                ? const Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    color: AppTheme.primaryColor,
                  )
                : PopupMenuButton<String>(
                    icon: const Icon(
                      CupertinoIcons.ellipsis_vertical,
                      color: AppTheme.textSecondary,
                    ),
                    color: AppTheme.cardColor,
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'switch',
                        child: Row(
                          children: [
                            const Icon(
                              CupertinoIcons.arrow_right_arrow_left,
                              color: AppTheme.textSecondary,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _translate('switch_account'),
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'remove',
                        child: Row(
                          children: [
                            const Icon(
                              CupertinoIcons.trash,
                              color: AppTheme.errorColor,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _translate('remove_account'),
                              style: const TextStyle(
                                color: AppTheme.errorColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'switch') {
                        _switchAccount(account['id']);
                      } else if (value == 'remove') {
                        _removeAccount(account['id']);
                      }
                    },
                  ),
            onTap: isActive ? null : () => _switchAccount(account['id']),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.person_badge_plus,
            size: 64,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: AppConstants.normalSpacing),
          Text(
            _translate('no_accounts'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppConstants.smallSpacing),
          Text(
            _translate('add_account_to_start'),
            style: const TextStyle(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAddAccountButton() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.largeSpacing),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppTheme.dividerColor),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: widget.onAddAccount,
          icon: const Icon(CupertinoIcons.add),
          label: Text(_translate('add_account')),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: AppTheme.textPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }
}