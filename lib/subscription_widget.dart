import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:ui';

class SubscriptionWidget extends StatefulWidget {
  final String companyId;
  final String currentLanguage;
  final String Function(String) translate;

  const SubscriptionWidget({
    Key? key,
    required this.companyId,
    required this.currentLanguage,
    required this.translate,
  }) : super(key: key);

  @override
  State<SubscriptionWidget> createState() => _SubscriptionWidgetState();
}

class _SubscriptionWidgetState extends State<SubscriptionWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;

  Map<String, dynamic>? _subscriptionInfo;
  List<Map<String, dynamic>> _availablePlans = [];
  bool _isLoading = true;
  bool _isUpgrading = false;

  // Modern colors
  static const Color primaryColor = Color(0xFF6e38c9);
  static const Color secondaryColor = Color(0xFF9c6bff);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);

  final Map<String, Map<String, String>> _localizedStrings = {
    'en': {
      'subscription_management': 'Subscription Management',
      'current_plan': 'Current Plan',
      'upgrade_plan': 'Upgrade Plan',
      'free_plan': 'Free Plan',
      'premium_plan': 'Premium Plan',
      'pro_plan': 'Pro Plan',
      'unlimited_plan': 'Unlimited Plan',
      'monthly': 'Monthly',
      'yearly': 'Yearly',
      'employees': 'Employees',
      'unlimited': 'Unlimited',
      'days_remaining': 'Days Remaining',
      'expired': 'Expired',
      'active': 'Active',
      'trial': 'Trial',
      'start_free_trial': 'Start Free Trial',
      'upgrade_now': 'Upgrade Now',
      'current': 'Current',
      'popular': 'Popular',
      'best_value': 'Best Value',
      'save': 'Save',
      'per_month': '/month',
      'per_year': '/year',
      'features': 'Features',
      'no_ads': 'No Ads',
      'email_support': 'Email Support',
      'priority_support': 'Priority Support',
      'live_support': 'Live Support',
      'free_trial_available': 'Free Trial Available',
      'loading': 'Loading...',
      'upgrade_success': 'Plan upgraded successfully!',
      'upgrade_error': 'Failed to upgrade plan',
      'trial_started': 'Free trial started successfully!',
      'trial_error': 'Failed to start free trial',
      'confirm_upgrade': 'Confirm Upgrade',
      'upgrade_confirmation': 'Are you sure you want to upgrade to {plan}?',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
    },
    'uz': {
      'subscription_management': 'Obuna Boshqaruvi',
      'current_plan': 'Joriy Tarif',
      'upgrade_plan': 'Tarifni Yangilash',
      'free_plan': 'Tekin Tarif',
      'premium_plan': 'Premium Tarif',
      'pro_plan': 'Pro Tarif',
      'unlimited_plan': 'Cheksiz Tarif',
      'monthly': 'Oylik',
      'yearly': 'Yillik',
      'employees': 'Xodimlar',
      'unlimited': 'Cheksiz',
      'days_remaining': 'Qolgan Kunlar',
      'expired': 'Muddati Tugagan',
      'active': 'Faol',
      'trial': 'Sinov',
      'start_free_trial': 'Tekin Sinov Boshlash',
      'upgrade_now': 'Hozir Yangilash',
      'current': 'Joriy',
      'popular': 'Mashhur',
      'best_value': 'Eng Foydali',
      'save': 'Tejash',
      'per_month': '/oy',
      'per_year': '/yil',
      'features': 'Xususiyatlar',
      'no_ads': 'Reklamasiz',
      'email_support': 'Email Yordam',
      'priority_support': 'Ustuvor Yordam',
      'live_support': 'Jonli Yordam',
      'free_trial_available': 'Tekin Sinov Mavjud',
      'loading': 'Yuklanmoqda...',
      'upgrade_success': 'Tarif muvaffaqiyatli yangilandi!',
      'upgrade_error': 'Tarifni yangilashda xatolik',
      'trial_started': 'Tekin sinov muvaffaqiyatli boshlandi!',
      'trial_error': 'Tekin sinov boshlanmadi',
      'confirm_upgrade': 'Yangilashni Tasdiqlash',
      'upgrade_confirmation': '{plan} tarifiga o\'tishni tasdiqlaysizmi?',
      'cancel': 'Bekor qilish',
      'confirm': 'Tasdiqlash',
    },
    'ru': {
      'subscription_management': 'Управление Подпиской',
      'current_plan': 'Текущий План',
      'upgrade_plan': 'Обновить План',
      'free_plan': 'Бесплатный План',
      'premium_plan': 'Премиум План',
      'pro_plan': 'Про План',
      'unlimited_plan': 'Безлимитный План',
      'monthly': 'Месячный',
      'yearly': 'Годовой',
      'employees': 'Сотрудники',
      'unlimited': 'Безлимит',
      'days_remaining': 'Дней Осталось',
      'expired': 'Истек',
      'active': 'Активен',
      'trial': 'Пробный',
      'start_free_trial': 'Начать Пробный',
      'upgrade_now': 'Обновить Сейчас',
      'current': 'Текущий',
      'popular': 'Популярный',
      'best_value': 'Лучшая Цена',
      'save': 'Экономия',
      'per_month': '/месяц',
      'per_year': '/год',
      'features': 'Возможности',
      'no_ads': 'Без Рекламы',
      'email_support': 'Email Поддержка',
      'priority_support': 'Приоритетная Поддержка',
      'live_support': 'Живая Поддержка',
      'free_trial_available': 'Доступен Пробный',
      'loading': 'Загрузка...',
      'upgrade_success': 'План успешно обновлен!',
      'upgrade_error': 'Ошибка обновления плана',
      'trial_started': 'Пробный период успешно начат!',
      'trial_error': 'Не удалось начать пробный период',
      'confirm_upgrade': 'Подтвердить Обновление',
      'upgrade_confirmation': 'Вы уверены, что хотите перейти на {plan}?',
      'cancel': 'Отмена',
      'confirm': 'Подтвердить',
    },
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _loadSubscriptionData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String _translate(String key, [Map<String, String>? params]) {
    String translation = _localizedStrings[widget.currentLanguage]?[key] ??
        _localizedStrings['uz']?[key] ??
        key;

    if (params != null) {
      params.forEach((paramKey, value) {
        translation = translation.replaceAll('{$paramKey}', value);
      });
    }

    return translation;
  }

  Future<void> _loadSubscriptionData() async {
    setState(() => _isLoading = true);

    try {
      // Get current subscription info
      final subscriptionResponse = await Supabase.instance.client
          .rpc('get_company_subscription_info', params: {
        'p_company_id': widget.companyId,
      });

      // Get available plans
      final plansResponse = await Supabase.instance.client
          .from('subscription_plans')
          .select('*')
          .eq('is_active', true)
          .order('price_usd');

      setState(() {
        _subscriptionInfo = subscriptionResponse;
        _availablePlans = List<Map<String, dynamic>>.from(plansResponse);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading subscription data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startFreeTrial() async {
    setState(() => _isUpgrading = true);

    try {
      final response =
          await Supabase.instance.client.rpc('start_free_trial', params: {
        'p_company_id': widget.companyId,
      });

      if (response['success'] == true) {
        _showSnackBar(_translate('trial_started'), isSuccess: true);
        await _loadSubscriptionData();
      } else {
        _showSnackBar(response['error'] ?? _translate('trial_error'),
            isSuccess: false);
      }
    } catch (e) {
      _showSnackBar(_translate('trial_error'), isSuccess: false);
    } finally {
      setState(() => _isUpgrading = false);
    }
  }

  Future<void> _upgradePlan(String planName, String planType) async {
    final confirmed = await _showUpgradeConfirmation(planName);
    if (!confirmed) return;

    setState(() => _isUpgrading = true);

    try {
      final response = await Supabase.instance.client
          .rpc('update_company_subscription', params: {
        'p_company_id': widget.companyId,
        'p_subscription_type': planName,
        'p_duration': planType,
      });

      if (response['success'] == true) {
        _showSnackBar(_translate('upgrade_success'), isSuccess: true);
        await _loadSubscriptionData();
      } else {
        _showSnackBar(response['error'] ?? _translate('upgrade_error'),
            isSuccess: false);
      }
    } catch (e) {
      _showSnackBar(_translate('upgrade_error'), isSuccess: false);
    } finally {
      setState(() => _isUpgrading = false);
    }
  }

  Future<bool> _showUpgradeConfirmation(String planName) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: cardColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              _translate('confirm_upgrade'),
              style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary),
            ),
            content: Text(
              _translate('upgrade_confirmation',
                  {'plan': _translate('${planName}_plan')}),
              style: TextStyle(color: textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(_translate('cancel'),
                    style: TextStyle(color: textSecondary)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: Text(_translate('confirm')),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSnackBar(String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? successColor : errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: 24),
          if (_isLoading)
            _buildLoadingState()
          else ...[
            _buildCurrentPlanCard(),
            SizedBox(height: 32),
            _buildAvailablePlans(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(CupertinoIcons.star_fill, color: Colors.white, size: 24),
        ),
        SizedBox(width: 16),
        Text(
          _translate('subscription_management'),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
          SizedBox(height: 16),
          Text(
            _translate('loading'),
            style: TextStyle(color: textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPlanCard() {
    if (_subscriptionInfo == null) return SizedBox.shrink();

    final currentPlan = _subscriptionInfo!['subscription_type'] ?? 'free';
    final status = _subscriptionInfo!['subscription_status'] ?? 'active';
    final employeeLimit = _subscriptionInfo!['employee_limit'];
    final currentEmployees = _subscriptionInfo!['current_employees'] ?? 0;
    final daysRemaining = _subscriptionInfo!['days_remaining'];

    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withOpacity(0.1),
            secondaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _translate('current_plan'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: _getStatusColor(status).withOpacity(0.3)),
                ),
                child: Text(
                  _translate(status),
                  style: TextStyle(
                    color: _getStatusColor(status),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            _translate('${currentPlan}_plan'),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  icon: CupertinoIcons.group,
                  label: _translate('employees'),
                  value: employeeLimit != null
                      ? '$currentEmployees / $employeeLimit'
                      : '$currentEmployees / ${_translate('unlimited')}',
                  color: successColor,
                ),
              ),
              if (daysRemaining != null) ...[
                SizedBox(width: 16),
                Expanded(
                  child: _buildInfoCard(
                    icon: CupertinoIcons.calendar,
                    label: _translate('days_remaining'),
                    value: daysRemaining.toString(),
                    color: daysRemaining > 7 ? successColor : warningColor,
                  ),
                ),
              ],
            ],
          ),
          if (currentPlan == 'free' &&
              !(_subscriptionInfo!['free_trial_used'] ?? false)) ...[
            SizedBox(height: 20),
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        primaryColor
                            .withOpacity(0.8 + (_pulseController.value * 0.2)),
                        secondaryColor
                            .withOpacity(0.8 + (_pulseController.value * 0.2)),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor
                            .withOpacity(0.3 + (_pulseController.value * 0.2)),
                        blurRadius: 15,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _isUpgrading ? null : _startFreeTrial,
                    icon: _isUpgrading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(CupertinoIcons.gift, size: 20),
                    label: Text(
                      _translate('start_free_trial'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: textSecondary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailablePlans() {
    final groupedPlans = <String, List<Map<String, dynamic>>>{};

    for (var plan in _availablePlans) {
      final planName = plan['plan_name'];
      if (!groupedPlans.containsKey(planName)) {
        groupedPlans[planName] = [];
      }
      groupedPlans[planName]!.add(plan);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _translate('upgrade_plan'),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        SizedBox(height: 16),
        ...groupedPlans.entries
            .map((entry) => _buildPlanGroup(entry.key, entry.value)),
      ],
    );
  }

  Widget _buildPlanGroup(String planName, List<Map<String, dynamic>> plans) {
    if (planName == 'free')
      return SizedBox.shrink(); // Don't show free plan in upgrade options

    final currentPlan = _subscriptionInfo?['subscription_type'] ?? 'free';
    final isCurrentPlan = currentPlan == planName;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentPlan ? primaryColor : Colors.grey.shade200,
          width: isCurrentPlan ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _translate('${planName}_plan'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              Spacer(),
              if (isCurrentPlan)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _translate('current'),
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (planName == 'premium' && !isCurrentPlan)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _translate('popular'),
                    style: TextStyle(
                      color: warningColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: plans
                .map((plan) => Expanded(
                      child: _buildPlanOption(plan, isCurrentPlan),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanOption(Map<String, dynamic> plan, bool isCurrentPlan) {
    final planType = plan['plan_type'];
    final price = plan['price_usd'];
    final originalPrice = plan['original_price_usd'];
    final discount = plan['discount_percentage'] ?? 0;
    final employeeLimit = plan['employee_limit'];

    return Container(
      margin: EdgeInsets.only(
          right: planType == 'monthly' ? 8 : 0,
          left: planType == 'yearly' ? 8 : 0),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: planType == 'yearly'
              ? primaryColor.withOpacity(0.3)
              : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _translate(planType),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              if (discount > 0) ...[
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${_translate('save')} $discount%',
                    style: TextStyle(
                      color: successColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${price.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              Text(
                _translate(planType == 'monthly' ? 'per_month' : 'per_year'),
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
            ],
          ),
          if (discount > 0) ...[
            SizedBox(height: 4),
            Text(
              '\$${originalPrice.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 12,
                color: textSecondary,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ],
          SizedBox(height: 12),
          Text(
            employeeLimit != null
                ? '$employeeLimit ${_translate('employees')}'
                : _translate('unlimited'),
            style: TextStyle(
              fontSize: 12,
              color: textSecondary,
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isCurrentPlan || _isUpgrading
                  ? null
                  : () => _upgradePlan(plan['plan_name'], planType),
              child: _isUpgrading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      isCurrentPlan
                          ? _translate('current')
                          : _translate('upgrade_now'),
                      style: TextStyle(fontSize: 12),
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isCurrentPlan ? Colors.grey : primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 8),
                minimumSize: Size(0, 32),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return successColor;
      case 'trial':
        return warningColor;
      case 'expired':
        return errorColor;
      default:
        return textSecondary;
    }
  }
}
