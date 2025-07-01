import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import 'dart:ui';
import 'package:url_launcher/url_launcher.dart'; // url_launcher importini qo'shing

class AdminEmployeeAddWidget extends StatefulWidget {
  final String companyId;
  final int? employeeLimit;
  final int currentEmployeeCount;
  final String currentLanguage;
  final String Function(String) translate;
  final VoidCallback onEmployeeAdded;

  const AdminEmployeeAddWidget({
    Key? key,
    required this.companyId,
    this.employeeLimit,
    required this.currentEmployeeCount,
    required this.currentLanguage,
    required this.translate,
    required this.onEmployeeAdded,
  }) : super(key: key);

  @override
  State<AdminEmployeeAddWidget> createState() => _AdminEmployeeAddWidgetState();
}

class _AdminEmployeeAddWidgetState extends State<AdminEmployeeAddWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // Form controllers (ularni endi ishlatmaymiz, lekin Dispose qilish uchun qoldiramiz)
  final _fullNameController = TextEditingController();
  final _positionController = TextEditingController();
  final _passwordController =
      TextEditingController(text: 'Employee123!'); // Default strong password
  final _countController = TextEditingController(text: '1');

  bool _isLoading = false;
  bool _isManualMode = true; // true = manual, false = automatic
  int _selectedCount = 1;

  // Modern colors
  static const Color primaryColor = Color(0xFF8c03e6);
  static const Color secondaryColor = Color(0xFFa855f7);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color successColor = Color(0xFF10B981);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color warningColor = Color(0xFFF59E0B);

  final Map<String, Map<String, String>> _localizedStrings = {
    'en': {
      'add_employee': 'Add Employee',
      'manual_entry': 'Manual Entry',
      'automatic_entry': 'Automatic Entry',
      'full_name': 'Full Name',
      'position': 'Position',
      'password': 'Password (min 6 characters)',
      'employee_count': 'Employee Count',
      'create_employee': 'Create Employee',
      'create_employees': 'Create Employees',
      'employee_limit_reached': 'Employee limit reached',
      'employees_created_successfully': 'Employees created successfully',
      'error_creating_employees': 'Error creating employees',
      'enter_full_name': 'Enter full name',
      'enter_position': 'Enter position',
      'enter_password': 'Enter password (min 6 chars)',
      'select_count': 'Select count',
      'cancel': 'Cancel',
      'create': 'Create',
      'loading': 'Loading...',
      'max_employees': 'Maximum {count} employees',
      'fill_all_fields': 'Please fill all fields',
      'email_already_exists': 'Email already exists',
      'weak_password': 'Password must be at least 6 characters',
      'invalid_email': 'Invalid email format',
      'password_too_short': 'Password must be at least 6 characters',
      'database_error': 'Database error occurred',
      'auth_error': 'Authentication error',
      'network_error': 'Network connection error',
      'unknown_error': 'Unknown error occurred',
      'password_requirements': 'Password must contain at least 6 characters',
      'generate_password': 'Generate Password',
      'function_error': 'Database function error',
      'user_creation_failed': 'User creation failed',
      'visit_web_to_add':
          'Visit our web platform to add employees', // Yangi matn
    },
    'uz': {
      'add_employee': 'Xodim Qo\'shish',
      'manual_entry': 'Qo\'lda Kiritish',
      'automatic_entry': 'Avtomatik Kiritish',
      'full_name': 'Ism Familiya',
      'position': 'Lavozim',
      'password': 'Parol (kamida 6 ta belgi)',
      'employee_count': 'Xodimlar Soni',
      'create_employee': 'Xodim Yaratish',
      'create_employees': 'Xodimlar Yaratish',
      'employee_limit_reached': 'Xodimlar limiti tugadi',
      'employees_created_successfully': 'Xodimlar muvaffaqiyatli yaratildi',
      'error_creating_employees': 'Xodimlar yaratishda xatolik',
      'enter_full_name': 'Ism familiyani kiriting',
      'enter_position': 'Lavozimni kiriting',
      'enter_password': 'Parolni kiriting (kamida 6 ta)',
      'select_count': 'Sonini tanlang',
      'cancel': 'Bekor qilish',
      'create': 'Yaratish',
      'loading': 'Yuklanmoqda...',
      'max_employees': 'Maksimal {count} ta xodim',
      'fill_all_fields': 'Barcha maydonlarni to\'ldiring',
      'email_already_exists': 'Email allaqachon mavjud',
      'weak_password': 'Parol kamida 6 ta belgidan iborat bo\'lishi kerak',
      'invalid_email': 'Email formati noto\'g\'ri',
      'password_too_short': 'Parol kamida 6 ta belgidan iborat bo\'lishi kerak',
      'database_error': 'Ma\'lumotlar bazasi xatoligi',
      'auth_error': 'Autentifikatsiya xatoligi',
      'network_error': 'Tarmoq ulanish xatoligi',
      'unknown_error': 'Noma\'lum xatolik yuz berdi',
      'password_requirements':
          'Parol kamida 6 ta belgidan iborat bo\'lishi kerak',
      'generate_password': 'Parol Yaratish',
      'function_error': 'Ma\'lumotlar bazasi funksiya xatoligi',
      'user_creation_failed': 'Foydalanuvchi yaratish muvaffaqiyatsiz',
      'visit_web_to_add':
          'Xodim qo\'shish uchun veb-platformamizga tashrif buyuring', // Yangi matn
    },
    'ru': {
      'add_employee': 'Добавить Сотрудника',
      'manual_entry': 'Ручной Ввод',
      'automatic_entry': 'Автоматический Ввод',
      'full_name': 'Полное Имя',
      'position': 'Должность',
      'password': 'Пароль (мин 6 символов)',
      'employee_count': 'Количество Сотрудников',
      'create_employee': 'Создать Сотрудника',
      'create_employees': 'Создать Сотрудников',
      'employee_limit_reached': 'Достигнут лимит сотрудников',
      'employees_created_successfully': 'Сотрудники успешно созданы',
      'error_creating_employees': 'Ошибка создания сотрудников',
      'enter_full_name': 'Введите полное имя',
      'enter_position': 'Введите должность',
      'enter_password': 'Введите пароль (мин 6 симв)',
      'select_count': 'Выберите количество',
      'cancel': 'Отмена',
      'create': 'Создать',
      'loading': 'Загрузка...',
      'max_employees': 'Максимум {count} сотрудников',
      'fill_all_fields': 'Заполните все поля',
      'email_already_exists': 'Email уже существует',
      'weak_password': 'Пароль должен содержать минимум 6 символов',
      'invalid_email': 'Неверный формат email',
      'password_too_short': 'Пароль должен содержать минимум 6 символов',
      'database_error': 'Ошибка базы данных',
      'auth_error': 'Ошибка аутентификации',
      'network_error': 'Ошибка сетевого подключения',
      'unknown_error': 'Произошла неизвестная ошибка',
      'password_requirements': 'Пароль должен содержать минимум 6 символов',
      'generate_password': 'Генерировать Пароль',
      'function_error': 'Ошибка функции базы данных',
      'user_creation_failed': 'Не удалось создать пользователя',
      'visit_web_to_add':
          'Посетите нашу веб-платформу для добавления сотрудников', // Yangi matn
    },
  };

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_fadeController);

    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _fullNameController.dispose();
    _positionController.dispose();
    _passwordController.dispose();
    _countController.dispose();
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

  int get _maxAllowedEmployees {
    if (widget.employeeLimit == null) return 100; // Unlimited
    return widget.employeeLimit! - widget.currentEmployeeCount;
  }

  // Quyidagi funksiyalar va `_createEmployees` endi ishlatilmaydi,
  // lekin agar kelajakda yana foydalanmoqchi bo'lsangiz, qoldirilgan.
  // Hozircha ularni ishlatmasak ham bo'ladi.
  String _generateEmail(String fullName, String position, int index) {
    String cleanName = fullName
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
    String cleanPosition = position
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
    String uniqueNumber = Random().nextInt(9999).toString().padLeft(4, '0');

    if (_isManualMode) {
      return '$cleanName$cleanPosition${widget.companyId.substring(0, 8)}$uniqueNumber@modderboy.uz';
    } else {
      return '$cleanPosition$index${widget.companyId.substring(0, 8)}$uniqueNumber@modderboy.uz';
    }
  }

  String _generateStrongPassword() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*';
    final random = Random();
    return List.generate(8, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  bool _isPasswordValid(String password) {
    return password.length >= 6;
  }

  String _getErrorMessage(dynamic error) {
    String errorString = error.toString().toLowerCase();

    if (errorString.contains('password') && errorString.contains('6')) {
      return _translate('password_too_short');
    } else if (errorString.contains('email_address_invalid')) {
      return _translate('invalid_email');
    } else if (errorString.contains('email_address_not_authorized') ||
        errorString.contains('user already registered') ||
        errorString.contains('already registered') ||
        errorString.contains('duplicate key')) {
      return _translate('email_already_exists');
    } else if (errorString.contains('weak_password') ||
        errorString.contains('password')) {
      return _translate('weak_password');
    } else if (errorString.contains('database error') ||
        errorString.contains('saving new user') ||
        errorString.contains('function')) {
      return _translate('function_error');
    } else if (errorString.contains('network') ||
        errorString.contains('connection')) {
      return _translate('network_error');
    } else if (errorString.contains('auth')) {
      return _translate('auth_error');
    } else {
      return _translate('unknown_error');
    }
  }

  // Quyidagi funksiyalar endi ishlamaydi, shuning uchun ularni umumiy holatda olib tashlasak ham bo'ladi
  // yoki kommentga olib qo'ysak ham bo'ladi, agar kelajakda kerak bo'lib qolsa.
  /*
  Future<void> _createEmployees() async {
    // ... eski kod ...
  }

  void _showSnackBar(String message, {required bool isSuccess}) {
    // ... eski kod ...
  }
  */

  // Veb-saytga yo'naltirish uchun funksiya
  Future<void> _launchWebUrl() async {
    final Uri url = Uri.parse('https://davomat.modderboy.uz/');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // Agar brauzerni ochib bo'lmasa
      _showSnackBar(
          'Veb-sahifani ochib bo\'lmadi. Iltimos, URLni qo\'lda oching.',
          isSuccess: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: SlideTransition(
            position: _slideAnimation,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Material(
                type: MaterialType.card,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                elevation: 8,
                child: Container(
                  height: MediaQuery.of(context).size.height *
                      0.4, // Balandlikni kamaytiramiz
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // Minimal hajmni oladi
                    children: [
                      _buildHeader(),
                      // _buildModeSelector(), // Rejim tanlashni olib tashlaymiz
                      // Expanded(child: SingleChildScrollView(padding: EdgeInsets.all(20), child: _buildForm())), // Formani olib tashlaymiz
                      // _buildActionButtons(), // Tugmalarni ham o'zgartiramiz

                      // Yangi tarkib: veb-sahifaga yo'naltirish haqida xabar
                      Expanded(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.info_circle,
                                  size: 50,
                                  color: primaryColor,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  _translate('visit_web_to_add'), // Yangi matn
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                ),
                                SizedBox(height: 24),
                                _buildRedirectButton(), // Yo'naltirish tugmasi
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(CupertinoIcons.person_add,
                    color: Colors.white, size: 20),
              ),
              SizedBox(width: 12),
              Text(
                _translate('add_employee'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              Spacer(),
              // Ushbu qismni olib tashlash yoki o'zgartirish mumkin, chunki biz endi xodim qo'shmaymiz.
              // Agar limit haqida ma'lumot berish kerak bo'lsa, qoldirish mumkin.
              // widget.employeeLimit != null && _maxAllowedEmployees <= 0
              // ? Container(...) : SizedBox.shrink(),
              // Hoziroqcha qoldiramiz, lekin ma'nosi kamayadi
              if (widget.employeeLimit != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _translate('max_employees',
                        {'count': _maxAllowedEmployees.toString()}),
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Yo'naltirish tugmasi
  Widget _buildRedirectButton() {
    return ElevatedButton(
      onPressed: _isLoading
          ? null
          : _launchWebUrl, // _isLoading ni ham tekshiramiz, garchi endi ishlamasa ham
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.globe, size: 18),
          SizedBox(width: 8),
          Text(
            'Veb-saytga O\'tish', // Yoki har bir til uchun tarjimasi
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // SnackBar ko'rsatish funksiyasi (agar kerak bo'lsa, masalan, URL ochilmaganda)
  void _showSnackBar(String message, {required bool isSuccess}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isSuccess ? successColor : errorColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: Duration(seconds: isSuccess ? 3 : 5),
        ),
      );
    }
  }
}
