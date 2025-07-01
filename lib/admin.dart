import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:DavomatYettilik/main.dart';
import 'package:DavomatYettilik/settings_page.dart';
import 'package:DavomatYettilik/admin_employee_add_widget.dart';
import 'package:DavomatYettilik/webview_page.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:ui';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with TickerProviderStateMixin {
  int _currentTab = 0;
  late TabController _tabController;
  late AnimationController _animationController;
  late AnimationController _pulseController;

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allEmployees = [];
  List<Map<String, dynamic>> _filteredEmployees = [];
  bool _showSearchResults = false;

  // Modern colors with #8c03e6
  static const Color primaryColor = Color(0xFF8c03e6);
  static const Color secondaryColor = Color(0xFFa855f7);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);

  // Data
  String? _companyName;
  String? _companyLogo;
  String? _companyId;
  String? _adminProfileImage;
  String? _adminName;
  String? _adminEmail;
  int _employeeCount = 0;
  int? _employeeLimit;
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _attendanceData = [];
  List<Map<String, dynamic>> _notifications = [];
  DateTime _selectedDate = DateTime.now();
  String _attendanceFilter = 'Barchasi';

  // Company settings
  TimeOfDay _arrivalTime = TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _departureTime = TimeOfDay(hour: 18, minute: 0);
  int _graceMinutes = 15;

  // Loading states
  bool _isLoading = true;
  bool _isUploadingLogo = false;

  String _currentLanguage = 'uz';

  final Map<String, Map<String, String>> _localizedStrings = {
    'en': {
      'admin_panel': 'Admin Panel',
      'dashboard': 'Dashboard',
      'employees': 'Employees',
      'attendance': 'Attendance',
      'settings': 'Settings',
      'company_info': 'Company Information',
      'balance': 'Balance',
      'employee_count': 'Employees',
      'upload_logo': 'Upload Logo',
      'change_logo': 'Change Logo',
      'arrival_time': 'Arrival Time',
      'departure_time': 'Departure Time',
      'grace_period': 'Grace Period (minutes)',
      'save_settings': 'Save Settings',
      'attendance_filter': 'Filter',
      'all': 'All',
      'present': 'Present',
      'absent': 'Absent',
      'late': 'Late',
      'loading': 'Loading...',
      'no_data': 'No data available',
      'success': 'Success',
      'error': 'Error',
      'settings_saved': 'Settings saved successfully',
      'logo_uploaded': 'Logo uploaded successfully',
      'select_date': 'Select Date',
      'employee_name': 'Employee Name',
      'check_in': 'Check In',
      'check_out': 'Check Out',
      'status': 'Status',
      'late_minutes': 'Late (min)',
      'search_employees': 'Search employees...',
      'notifications': 'Notifications',
      'profile': 'Profile',
      'logout': 'Logout',
      'top_up_balance': 'Top Up Balance',
      'admin_panel_access': 'Admin Panel Access',
      'external_browser': 'External Browser',
      'in_app_browser': 'In-App Browser',
      'logout_confirmation': 'Are you sure you want to logout?',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'add_employee': 'Add Employee',
      'no_employees': 'No employees found',
      'add_first_employee': 'Add your first employee',
    },
    'uz': {
      'admin_panel': 'Admin Panel',
      'dashboard': 'Boshqaruv',
      'employees': 'Xodimlar',
      'attendance': 'Davomat',
      'settings': 'Sozlamalar',
      'company_info': 'Kompaniya ma\'lumotlari',
      'balance': 'Balans',
      'employee_count': 'Xodimlar',
      'upload_logo': 'Logo yuklash',
      'change_logo': 'Logo o\'zgartirish',
      'arrival_time': 'Kelish vaqti',
      'departure_time': 'Ketish vaqti',
      'grace_period': 'Hisobsiz vaqt (minut)',
      'save_settings': 'Sozlamalarni saqlash',
      'attendance_filter': 'Filter',
      'all': 'Barchasi',
      'present': 'Kelgan',
      'absent': 'Kelmagan',
      'late': 'Kechikkan',
      'loading': 'Yuklanmoqda...',
      'no_data': 'Ma\'lumot yo\'q',
      'success': 'Muvaffaqiyat',
      'error': 'Xatolik',
      'settings_saved': 'Sozlamalar saqlandi',
      'logo_uploaded': 'Logo yuklandi',
      'select_date': 'Sana tanlash',
      'employee_name': 'Xodim nomi',
      'check_in': 'Kelish',
      'check_out': 'Ketish',
      'status': 'Holat',
      'late_minutes': 'Kechikish (min)',
      'search_employees': 'Xodimlarni qidirish...',
      'notifications': 'Bildirishnomalar',
      'profile': 'Profil',
      'logout': 'Chiqish',
      'top_up_balance': 'Hisob to\'ldirish',
      'admin_panel_access': 'Admin panelga kirish',
      'external_browser': 'Tashqi brauzer orqali kirish',
      'in_app_browser': 'Dastur ichida kirish',
      'logout_confirmation': 'Rostdan ham chiqmoqchimisiz?',
      'cancel': 'Bekor qilish',
      'confirm': 'Tasdiqlash',
      'add_employee': 'Xodim Qo\'shish',
      'no_employees': 'Xodimlar topilmadi',
      'add_first_employee': 'Birinchi xodimingizni qo\'shing',
    },
    'ru': {
      'admin_panel': 'Админ Панель',
      'dashboard': 'Панель управления',
      'employees': 'Сотрудники',
      'attendance': 'Посещаемость',
      'settings': 'Настройки',
      'company_info': 'Информация о компании',
      'balance': 'Баланс',
      'employee_count': 'Сотрудники',
      'upload_logo': 'Загрузить логотип',
      'change_logo': 'Изменить логотип',
      'arrival_time': 'Время прихода',
      'departure_time': 'Время ухода',
      'grace_period': 'Льготное время (минуты)',
      'save_settings': 'Сохранить настройки',
      'attendance_filter': 'Фильтр',
      'all': 'Все',
      'present': 'Присутствовал',
      'absent': 'Отсутствовал',
      'late': 'Опоздал',
      'loading': 'Загрузка...',
      'no_data': 'Нет данных',
      'success': 'Успех',
      'error': 'Ошибка',
      'settings_saved': 'Настройки сохранены',
      'logo_uploaded': 'Логотип загружен',
      'select_date': 'Выбрать дату',
      'employee_name': 'Имя сотрудника',
      'check_in': 'Приход',
      'check_out': 'Уход',
      'status': 'Статус',
      'late_minutes': 'Опоздание (мин)',
      'search_employees': 'Поиск сотрудников...',
      'notifications': 'Уведомления',
      'profile': 'Профиль',
      'logout': 'Выйти',
      'top_up_balance': 'Пополнить баланс',
      'admin_panel_access': 'Доступ к админ панели',
      'external_browser': 'Внешний браузер',
      'in_app_browser': 'Встроенный браузер',
      'logout_confirmation': 'Вы уверены, что хотите выйти?',
      'cancel': 'Отмена',
      'confirm': 'Подтвердить',
      'add_employee': 'Добавить Сотрудника',
      'no_employees': 'Сотрудники не найдены',
      'add_first_employee': 'Добавьте первого сотрудника',
    },
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _searchController.addListener(_onSearchChanged);
    _loadLanguagePreference();
    _loadAdminData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _pulseController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLanguagePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentLanguage = prefs.getString('language') ?? 'uz';
    });
  }

  String _translate(String key) {
    return _localizedStrings[_currentLanguage]?[key] ??
        _localizedStrings['uz']?[key] ??
        key;
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _showSearchResults = query.isNotEmpty;
      if (query.isNotEmpty) {
        _filteredEmployees = _allEmployees.where((user) {
          final name = (user['full_name'] ?? '').toString().toLowerCase();
          final email = (user['email'] ?? '').toString().toLowerCase();
          final position = (user['position'] ?? '').toString().toLowerCase();
          return name.contains(query) ||
              email.contains(query) ||
              position.contains(query);
        }).toList();
      } else {
        _filteredEmployees = _allEmployees;
      }
    });
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Get admin profile
      final adminResponse = await supabase
          .from('users')
          .select('company_id, full_name, email, profile_image')
          .eq('id', userId)
          .maybeSingle();

      final companyId = adminResponse?['company_id'];
      if (companyId == null) return;

      setState(() {
        _companyId = companyId;
        _adminName = adminResponse?['full_name'];
        _adminEmail = adminResponse?['email'];
        _adminProfileImage = adminResponse?['profile_image'];
      });

      // Get company info and subscription details
      final companyResponse = await supabase
          .from('companies')
          .select(
              'company_name, logo_url, kelish_vaqti, ketish_vaqti, hisobsiz_vaqt, employee_limit')
          .eq('id', companyId)
          .maybeSingle();

      if (companyResponse != null) {
        setState(() {
          _companyName = companyResponse['company_name'];
          _companyLogo = companyResponse['logo_url'];
          _employeeLimit = companyResponse['employee_limit'];

          // Parse time settings
          if (companyResponse['kelish_vaqti'] != null) {
            final arrivalParts = companyResponse['kelish_vaqti'].split(':');
            _arrivalTime = TimeOfDay(
              hour: int.parse(arrivalParts[0]),
              minute: int.parse(arrivalParts[1]),
            );
          }

          if (companyResponse['ketish_vaqti'] != null) {
            final departureParts = companyResponse['ketish_vaqti'].split(':');
            _departureTime = TimeOfDay(
              hour: int.parse(departureParts[0]),
              minute: int.parse(departureParts[1]),
            );
          }

          _graceMinutes = companyResponse['hisobsiz_vaqt'] ?? 15;
        });
      }

      // Get employees
      final employeesResponse = await supabase
          .from('users')
          .select(
              'id, full_name, name, email, position, profile_image, is_active')
          .eq('company_id', companyId)
          .neq('is_super_admin', true);

      setState(() {
        _employees = List<Map<String, dynamic>>.from(employeesResponse);
        _allEmployees = _employees;
        _filteredEmployees = _employees;
        _employeeCount = _employees.length;
      });

      // Load notifications
      await _loadNotifications();

      // Load attendance for selected date
      await _loadAttendanceData();
    } catch (e) {
      print('Error loading admin data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadNotifications() async {
    try {
      if (_companyId == null) return;

      final notificationsResponse = await supabase
          .from('notifications')
          .select('*')
          .or('type.eq.public,and(type.eq.private,company_id.eq.$_companyId)')
          .order('created_at', ascending: false)
          .limit(50);

      setState(() {
        _notifications = List<Map<String, dynamic>>.from(notificationsResponse);
      });
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }

  Future<void> _loadAttendanceData() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final userResponse = await supabase
          .from('users')
          .select('company_id')
          .eq('id', userId)
          .maybeSingle();

      final companyId = userResponse?['company_id'];
      if (companyId == null) return;

      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      final attendanceResponse = await supabase.from('davomat').select('''
            xodim_id,
            kelish_vaqti,
            ketish_vaqti,
            status,
            kechikish_minut,
            users!davomat_xodim_id_fkey(full_name, name)
          ''').eq('company_id', companyId).eq('kelish_sana', dateStr);

      setState(() {
        _attendanceData = List<Map<String, dynamic>>.from(attendanceResponse);
      });
    } catch (e) {
      print('Error loading attendance data: $e');
    }
  }

  void _showAddEmployeeModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AdminEmployeeAddWidget(
        companyId: _companyId!,
        employeeLimit: _employeeLimit,
        currentEmployeeCount: _employeeCount,
        currentLanguage: _currentLanguage,
        translate: _translate,
        onEmployeeAdded: () {
          _loadAdminData(); // Refresh data
        },
      ),
    );
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: cardColor.withOpacity(0.95),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),
              // Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.bell_fill,
                        color: primaryColor, size: 24),
                    SizedBox(width: 12),
                    Text(
                      _translate('notifications'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              // Notifications list
              Expanded(
                child: _notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.bell_slash,
                                size: 60, color: textSecondary),
                            SizedBox(height: 16),
                            Text(
                              'Bildirishnomalar yo\'q',
                              style:
                                  TextStyle(fontSize: 16, color: textSecondary),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final notification = _notifications[index];
                          return Container(
                            margin: EdgeInsets.only(bottom: 12),
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: notification['type'] == 'public'
                                    ? primaryColor.withOpacity(0.3)
                                    : warningColor.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: notification['type'] == 'public'
                                            ? primaryColor.withOpacity(0.1)
                                            : warningColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        notification['type'] == 'public'
                                            ? 'Umumiy'
                                            : 'Shaxsiy',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              notification['type'] == 'public'
                                                  ? primaryColor
                                                  : warningColor,
                                        ),
                                      ),
                                    ),
                                    Spacer(),
                                    Text(
                                      DateFormat('dd.MM.yyyy HH:mm').format(
                                          DateTime.parse(
                                              notification['created_at'])),
                                      style: TextStyle(
                                          fontSize: 12, color: textSecondary),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                if (notification['image_url'] != null) ...[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      notification['image_url'],
                                      height: 120,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                        height: 120,
                                        color: backgroundColor,
                                        child: Icon(CupertinoIcons.photo,
                                            color: textSecondary),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                ],
                                Text(
                                  notification['message'] ?? '',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: textPrimary,
                                      height: 1.4),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          _translate('logout'),
          style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary),
        ),
        content: Text(
          _translate('logout_confirmation'),
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
              backgroundColor: errorColor,
              foregroundColor: Colors.white,
            ),
            child: Text(_translate('confirm')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await supabase.auth.signOut();
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => MyApp()),
            (route) => false,
          );
        }
      } catch (e) {
        print('Logout error: $e');
        _showSnackBar('Chiqishda xatolik yuz berdi', isSuccess: false);
      }
    }
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
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildModernAppBar(),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                    )
                  : _showSearchResults
                      ? _buildSearchResults()
                      : _buildTabContent(),
            ),
            _buildBottomNavBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAppBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 10, 20, 16),
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top row with profile and notifications
          Row(
            children: [
              // Profile avatar
              GestureDetector(
                onTap: () {
                  showCupertinoModalPopup(
                    context: context,
                    builder: (context) => CupertinoActionSheet(
                      actions: [
                        CupertinoActionSheetAction(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SettingsPage()),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.settings,
                                  color: primaryColor),
                              SizedBox(width: 8),
                              Text(_translate('settings')),
                            ],
                          ),
                        ),
                        CupertinoActionSheetAction(
                          onPressed: () {
                            Navigator.pop(context);
                            _logout();
                          },
                          isDestructiveAction: true,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.square_arrow_right),
                              SizedBox(width: 8),
                              Text(_translate('logout')),
                            ],
                          ),
                        ),
                      ],
                      cancelButton: CupertinoActionSheetAction(
                        onPressed: () => Navigator.pop(context),
                        child: Text(_translate('cancel')),
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, secondaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _adminProfileImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _adminProfileImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                                CupertinoIcons.person_fill,
                                color: Colors.white,
                                size: 20),
                          ),
                        )
                      : Icon(CupertinoIcons.person_fill,
                          color: Colors.white, size: 20),
                ),
              ),
              SizedBox(width: 12),
              // Search box
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(fontSize: 14, color: textPrimary),
                    decoration: InputDecoration(
                      hintText: _translate('search_employees'),
                      hintStyle: TextStyle(color: textSecondary, fontSize: 14),
                      prefixIcon: Icon(CupertinoIcons.search,
                          color: primaryColor, size: 18),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(CupertinoIcons.clear,
                                  color: textSecondary, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _showSearchResults = false);
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              // Notifications
              GestureDetector(
                onTap: _showNotifications,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(CupertinoIcons.bell,
                            color: textSecondary, size: 18),
                      ),
                      if (_notifications.isNotEmpty)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: errorColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_filteredEmployees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.person_3, size: 60, color: textSecondary),
            SizedBox(height: 16),
            Text(
              _translate('no_employees'),
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: textSecondary),
            ),
            SizedBox(height: 8),
            Text(
              'Boshqa kalit so\'z bilan qidiring',
              style: TextStyle(fontSize: 14, color: textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(20),
      itemCount: _filteredEmployees.length,
      itemBuilder: (context, index) {
        final employee = _filteredEmployees[index];
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: EdgeInsets.all(16),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: employee['profile_image'] != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        employee['profile_image'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                            CupertinoIcons.person_fill,
                            color: Colors.white,
                            size: 24),
                      ),
                    )
                  : Icon(CupertinoIcons.person_fill,
                      color: Colors.white, size: 24),
            ),
            title: Text(
              employee['full_name'] ?? 'Unknown',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: textPrimary),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (employee['position'] != null) ...[
                  SizedBox(height: 4),
                  Text(
                    employee['position'],
                    style: TextStyle(
                        color: primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                  ),
                ],
                if (employee['email'] != null) ...[
                  SizedBox(height: 2),
                  Text(
                    employee['email'],
                    style: TextStyle(color: textSecondary, fontSize: 13),
                  ),
                ],
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: employee['is_active'] == true
                        ? successColor.withOpacity(0.1)
                        : errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    employee['is_active'] == true ? 'Faol' : 'Faol emas',
                    style: TextStyle(
                      color: employee['is_active'] == true
                          ? successColor
                          : errorColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            trailing: Icon(CupertinoIcons.chevron_right,
                color: textSecondary, size: 16),
            onTap: () => _showEmployeeDetails(employee),
          ),
        );
      },
    );
  }

  void _showEmployeeDetails(Map<String, dynamic> employee) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            // Employee info
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: employee['profile_image'] != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        employee['profile_image'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                            CupertinoIcons.person_fill,
                            color: Colors.white,
                            size: 40),
                      ),
                    )
                  : Icon(CupertinoIcons.person_fill,
                      color: Colors.white, size: 40),
            ),
            SizedBox(height: 16),
            Text(
              employee['full_name'] ?? 'Unknown',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textPrimary),
            ),
            if (employee['position'] != null) ...[
              SizedBox(height: 8),
              Text(
                employee['position'],
                style: TextStyle(
                    fontSize: 16,
                    color: primaryColor,
                    fontWeight: FontWeight.w500),
              ),
            ],
            if (employee['email'] != null) ...[
              SizedBox(height: 8),
              Text(
                employee['email'],
                style: TextStyle(fontSize: 14, color: textSecondary),
              ),
            ],
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: employee['is_active'] == true
                    ? successColor.withOpacity(0.1)
                    : errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                employee['is_active'] == true ? 'Faol Xodim' : 'Faol Emas',
                style: TextStyle(
                  color:
                      employee['is_active'] == true ? successColor : errorColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: 32),
            // Action buttons
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // Show attendance history for this employee
                      },
                      icon: Icon(CupertinoIcons.calendar),
                      label: Text('Davomat tarixi'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: BorderSide(color: primaryColor),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // Edit employee
                      },
                      icon: Icon(CupertinoIcons.pencil),
                      label: Text('Tahrirlash'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        border:
            Border(top: BorderSide(color: Colors.grey.shade200, width: 1.0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(
                icon: CupertinoIcons.chart_bar_square,
                label: _translate('dashboard'),
                index: 0,
                isSelected: _currentTab == 0,
              ),
              _buildBottomNavItem(
                icon: CupertinoIcons.group,
                label: _translate('employees'),
                index: 1,
                isSelected: _currentTab == 1,
              ),
              _buildBottomNavItem(
                icon: CupertinoIcons.calendar,
                label: _translate('attendance'),
                index: 2,
                isSelected: _currentTab == 2,
              ),
              _buildBottomNavItem(
                icon: CupertinoIcons.settings,
                label: _translate('settings'),
                index: 3,
                isSelected: _currentTab == 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() => _currentTab = index);
        _animationController.forward().then((_) {
          _animationController.reverse();
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? primaryColor : textSecondary,
              size: 22,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? primaryColor : textSecondary,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_currentTab) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildEmployees();
      case 2:
        return _buildAttendance();
      case 3:
        return _buildSettings();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          // Stats cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: _translate('employee_count'),
                  value: _employeeCount.toString(),
                  subtitle:
                      _employeeLimit != null ? '/ $_employeeLimit' : '/ ∞',
                  icon: CupertinoIcons.group,
                  color: primaryColor,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Bugungi davomat',
                  value: _attendanceData.length.toString(),
                  subtitle: 'xodim kelgan',
                  icon: CupertinoIcons.calendar_today,
                  color: successColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          // Quick actions
          _buildQuickActions(),
          SizedBox(height: 24),
          // Today's attendance overview
          _buildTodayAttendanceCard(),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
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
          Text(
            'Tezkor amallar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  icon: CupertinoIcons.person_add,
                  label: _translate('add_employee'),
                  color: primaryColor,
                  onTap: _showAddEmployeeModal,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  icon: CupertinoIcons.globe,
                  label: 'Web Panel',
                  color: warningColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InAppWebViewPage(
                          url: 'https://davomat.modderboy.uz/dashboard',
                          title: 'Admin Dashboard',
                          currentLanguage: _currentLanguage,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayAttendanceCard() {
    final presentCount = _attendanceData
        .where((a) => a['status'] == 'kelgan' || a['status'] == 'kechikkan')
        .length;
    final lateCount =
        _attendanceData.where((a) => a['status'] == 'kechikkan').length;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withOpacity(0.1),
            secondaryColor.withOpacity(0.05)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.calendar_today, color: primaryColor),
              SizedBox(width: 8),
              Text(
                'Bugungi davomat',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMiniStatCard(
                  title: _translate('present'),
                  value: presentCount.toString(),
                  color: successColor,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildMiniStatCard(
                  title: _translate('late'),
                  value: lateCount.toString(),
                  color: warningColor,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildMiniStatCard(
                  title: _translate('absent'),
                  value: (_employeeCount - presentCount).toString(),
                  color: errorColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployees() {
    if (_employees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.person_3, size: 80, color: textSecondary),
            SizedBox(height: 24),
            Text(
              _translate('no_employees'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _translate('add_first_employee'),
              style: TextStyle(
                fontSize: 16,
                color: textSecondary,
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showAddEmployeeModal,
              icon: Icon(CupertinoIcons.person_add),
              label: Text(_translate('add_employee')),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Add employee button
        Container(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${_translate('employees')} ($_employeeCount)',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddEmployeeModal,
                icon: Icon(CupertinoIcons.add, size: 18),
                label: Text(_translate('add_employee')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Employees list
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 20),
            itemCount: _employees.length,
            itemBuilder: (context, index) {
              final employee = _employees[index];
              return AnimatedContainer(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeOut,
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cardColor, primaryColor.withOpacity(0.02)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryColor.withOpacity(0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, secondaryColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: employee['profile_image'] != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                employee['profile_image'],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(CupertinoIcons.person_fill,
                                        color: Colors.white, size: 24),
                              ),
                            )
                          : Icon(CupertinoIcons.person_fill,
                              color: Colors.white, size: 24),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            employee['full_name'] ??
                                employee['name'] ??
                                'Unknown',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          if (employee['position'] != null) ...[
                            SizedBox(height: 4),
                            Text(
                              employee['position'],
                              style: TextStyle(
                                fontSize: 14,
                                color: primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          if (employee['email'] != null) ...[
                            SizedBox(height: 4),
                            Text(
                              employee['email'],
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                              ),
                            ),
                          ],
                          SizedBox(height: 4),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: employee['is_active'] == true
                                  ? successColor.withOpacity(0.1)
                                  : errorColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              employee['is_active'] == true
                                  ? 'Faol'
                                  : 'Faol emas',
                              style: TextStyle(
                                color: employee['is_active'] == true
                                    ? successColor
                                    : errorColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(CupertinoIcons.chevron_right,
                        color: textSecondary, size: 16),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAttendance() {
    return Column(
      children: [
        // Date selector and filter
        Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now().subtract(Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _selectedDate = date;
                      });
                      await _loadAttendanceData();
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryColor.withOpacity(0.1),
                          primaryColor.withOpacity(0.05)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.calendar, color: primaryColor),
                        SizedBox(width: 8),
                        Text(
                          DateFormat('dd.MM.yyyy').format(_selectedDate),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      secondaryColor.withOpacity(0.1),
                      secondaryColor.withOpacity(0.05)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: secondaryColor.withOpacity(0.3)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _attendanceFilter,
                    items: ['Barchasi', 'Kelgan', 'Kelmagan', 'Kechikkan']
                        .map((filter) => DropdownMenuItem(
                              value: filter,
                              child: Text(filter),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _attendanceFilter = value!;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        // Attendance list
        Expanded(
          child: _attendanceData.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.calendar_badge_minus,
                          size: 60, color: textSecondary),
                      SizedBox(height: 16),
                      Text(
                        _translate('no_data'),
                        style: TextStyle(color: textSecondary),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _attendanceData.length,
                  itemBuilder: (context, index) {
                    final attendance = _attendanceData[index];
                    final user = attendance['users'];

                    // Apply filter
                    if (_attendanceFilter != 'Barchasi') {
                      final status = attendance['status'] ?? 'kelmagan';
                      if (_attendanceFilter == 'Kelgan' && status != 'kelgan')
                        return SizedBox.shrink();
                      if (_attendanceFilter == 'Kechikkan' &&
                          status != 'kechikkan') return SizedBox.shrink();
                      if (_attendanceFilter == 'Kelmagan' &&
                          status != 'kelmagan') return SizedBox.shrink();
                    }

                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            cardColor,
                            _getStatusColor(attendance['status'])
                                .withOpacity(0.02)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _getStatusColor(attendance['status'])
                              .withOpacity(0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _getStatusColor(attendance['status'])
                                .withOpacity(0.1),
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
                              Expanded(
                                child: Text(
                                  user?['full_name'] ??
                                      user?['name'] ??
                                      'Unknown',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                              _buildStatusChip(attendance['status']),
                            ],
                          ),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTimeInfo(
                                  _translate('check_in'),
                                  attendance['kelish_vaqti'],
                                  CupertinoIcons.arrow_down_circle,
                                  successColor,
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: _buildTimeInfo(
                                  _translate('check_out'),
                                  attendance['ketish_vaqti'],
                                  CupertinoIcons.arrow_up_circle,
                                  warningColor,
                                ),
                              ),
                            ],
                          ),
                          if (attendance['kechikish_minut'] != null &&
                              attendance['kechikish_minut'] > 0) ...[
                            SizedBox(height: 8),
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: errorColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: errorColor.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(CupertinoIcons.clock,
                                      color: errorColor, size: 16),
                                  SizedBox(width: 8),
                                  Text(
                                    '${_translate('late_minutes')}: ${attendance['kechikish_minut']}',
                                    style: TextStyle(
                                      color: errorColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'kelgan':
        return successColor;
      case 'kechikkan':
        return warningColor;
      default:
        return errorColor;
    }
  }

  Widget _buildStatusChip(String? status) {
    Color color = _getStatusColor(status);
    String text;

    switch (status) {
      case 'kelgan':
        text = _translate('present');
        break;
      case 'kechikkan':
        text = _translate('late');
        break;
      default:
        text = _translate('absent');
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTimeInfo(
      String label, String? time, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            time != null
                ? DateFormat('HH:mm').format(DateTime.parse(time))
                : '--:--',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettings() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          // Company logo section
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryColor.withOpacity(0.1),
                  secondaryColor.withOpacity(0.05)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primaryColor.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _translate('company_info'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                SizedBox(height: 16),
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: _companyLogo == null
                              ? LinearGradient(
                                  colors: [primaryColor, secondaryColor],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                        ),
                        child: _companyLogo != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  _companyLogo!,
                                  fit: BoxFit.cover,
                                  width: 100,
                                  height: 100,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(CupertinoIcons.building_2_fill,
                                          color: Colors.white, size: 40),
                                ),
                              )
                            : Icon(CupertinoIcons.building_2_fill,
                                color: Colors.white, size: 40),
                      ),
                      SizedBox(height: 16),
                      Text(
                        _companyName ?? 'Company',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _isUploadingLogo ? null : _uploadLogo,
                        icon: _isUploadingLogo
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Icon(_companyLogo == null
                                ? CupertinoIcons.cloud_upload
                                : CupertinoIcons.pencil),
                        label: Text(_companyLogo == null
                            ? _translate('upload_logo')
                            : _translate('change_logo')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          // Time settings
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  secondaryColor.withOpacity(0.1),
                  primaryColor.withOpacity(0.05)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: secondaryColor.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: secondaryColor.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ish vaqti sozlamalari',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                SizedBox(height: 16),
                _buildTimeSetting(
                  _translate('arrival_time'),
                  _arrivalTime,
                  (time) => setState(() => _arrivalTime = time),
                ),
                SizedBox(height: 16),
                _buildTimeSetting(
                  _translate('departure_time'),
                  _departureTime,
                  (time) => setState(() => _departureTime = time),
                ),
                SizedBox(height: 16),
                _buildGracePeriodSetting(),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveCompanySettings,
                    child: Text(_translate('save_settings')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSetting(
      String label, TimeOfDay time, Function(TimeOfDay) onChanged) {
    return GestureDetector(
      onTap: () async {
        final newTime = await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (newTime != null) {
          onChanged(newTime);
        }
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primaryColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(CupertinoIcons.clock, color: primaryColor),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                    ),
                  ),
                  Text(
                    time.format(context),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_right, color: textSecondary, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildGracePeriodSetting() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _translate('grace_period'),
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _graceMinutes.toDouble(),
                  min: 0,
                  max: 60,
                  divisions: 12,
                  activeColor: primaryColor,
                  onChanged: (value) {
                    setState(() {
                      _graceMinutes = value.round();
                    });
                  },
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: primaryColor.withOpacity(0.3)),
                ),
                child: Text(
                  '$_graceMinutes min',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _uploadLogo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() => _isUploadingLogo = true);

        final file = result.files.first;
        final fileName =
            'company_logo/${DateTime.now().millisecondsSinceEpoch}_${file.name}';

        Uint8List? fileBytes;
        if (kIsWeb) {
          fileBytes = file.bytes;
        } else {
          fileBytes = await File(file.path!).readAsBytes();
        }

        if (fileBytes != null) {
          // Upload to Supabase Storage
          await supabase.storage
              .from('photos')
              .uploadBinary(fileName, fileBytes);

          // Get public URL
          final logoUrl =
              supabase.storage.from('photos').getPublicUrl(fileName);

          // Update company record
          final userId = supabase.auth.currentUser?.id;
          final userResponse = await supabase
              .from('users')
              .select('company_id')
              .eq('id', userId!)
              .maybeSingle();

          final companyId = userResponse?['company_id'];
          if (companyId != null) {
            await supabase
                .from('companies')
                .update({'logo_url': logoUrl}).eq('id', companyId);

            setState(() {
              _companyLogo = logoUrl;
            });

            _showSnackBar(_translate('logo_uploaded'), isSuccess: true);
          }
        }
      }
    } catch (e) {
      print('Error uploading logo: $e');
      _showSnackBar(_translate('error'), isSuccess: false);
    } finally {
      setState(() => _isUploadingLogo = false);
    }
  }

  Future<void> _saveCompanySettings() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      final userResponse = await supabase
          .from('users')
          .select('company_id')
          .eq('id', userId!)
          .maybeSingle();

      final companyId = userResponse?['company_id'];
      if (companyId != null) {
        await supabase.from('companies').update({
          'kelish_vaqti':
              '${_arrivalTime.hour.toString().padLeft(2, '0')}:${_arrivalTime.minute.toString().padLeft(2, '0')}:00',
          'ketish_vaqti':
              '${_departureTime.hour.toString().padLeft(2, '0')}:${_departureTime.minute.toString().padLeft(2, '0')}:00',
          'hisobsiz_vaqt': _graceMinutes,
        }).eq('id', companyId);

        _showSnackBar(_translate('settings_saved'), isSuccess: true);
      }
    } catch (e) {
      print('Error saving settings: $e');
      _showSnackBar(_translate('error'), isSuccess: false);
    }
  }
}
