import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:DavomatYettilik/main.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Modern colors
  static const Color primaryColor = Color(0xFF6e38c9);
  static const Color secondaryColor = Color(0xFF9c6bff);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color successColor = Color(0xFF10B981);
  static const Color errorColor = Color(0xFFEF4444);

  String _currentLanguage = 'uz';
  bool _isAdmin = false;
  bool _isLoading = true;

  // User-specific settings
  bool _enableAttendanceMessage = false;
  String _attendanceMessage = '';
  bool _showTodayCard = true;
  bool _showCalendar = true;
  bool _compactView = false;

  // Admin-specific settings
  String? _companyName;
  String? _companyLogo;
  String? _companyId;
  bool _isUploadingLogo = false;

  final TextEditingController _companyNameController = TextEditingController();

  final Map<String, Map<String, String>> _localizedStrings = {
    'en': {
      'settings': 'Settings',
      'general': 'General',
      'language': 'Language',
      'attendance_settings': 'Attendance Settings',
      'enable_message': 'Enable Attendance Message',
      'attendance_message': 'Attendance Message',
      'message_placeholder': 'Enter your attendance message...',
      'home_customization': 'Home Page Customization',
      'show_today_card': 'Show Today\'s Attendance Card',
      'show_calendar': 'Show Attendance Calendar',
      'compact_view': 'Compact View',
      'company_settings': 'Company Settings',
      'company_name': 'Company Name',
      'company_logo': 'Company Logo',
      'change_logo': 'Change Logo',
      'upload_logo': 'Upload Logo',
      'save_company_name': 'Save Company Name',
      'about': 'About',
      'version': 'Version',
      'app_info': 'App Information',
      'save': 'Save',
      'saved': 'Settings saved successfully',
      'company_name_saved': 'Company name saved successfully',
      'logo_uploaded': 'Logo uploaded successfully',
      'uzbek': 'O\'zbekcha',
      'english': 'English',
      'russian': 'Русский',
      'company_name_placeholder': 'Enter company name...',
    },
    'uz': {
      'settings': 'Sozlamalar',
      'general': 'Umumiy',
      'language': 'Til',
      'attendance_settings': 'Davomat sozlamalari',
      'enable_message': 'Davomat xabarini yoqish',
      'attendance_message': 'Davomat xabari',
      'message_placeholder': 'Davomat xabaringizni kiriting...',
      'home_customization': 'Bosh sahifa sozlamalari',
      'show_today_card': 'Bugungi davomat kartasini ko\'rsatish',
      'show_calendar': 'Davomat kalendarini ko\'rsatish',
      'compact_view': 'Ixcham ko\'rinish',
      'company_settings': 'Kompaniya sozlamalari',
      'company_name': 'Kompaniya nomi',
      'company_logo': 'Kompaniya logosi',
      'change_logo': 'Logo o\'zgartirish',
      'upload_logo': 'Logo yuklash',
      'save_company_name': 'Kompaniya nomini saqlash',
      'about': 'Dastur haqida',
      'version': 'Versiya',
      'app_info': 'Dastur ma\'lumotlari',
      'save': 'Saqlash',
      'saved': 'Sozlamalar muvaffaqiyatli saqlandi',
      'company_name_saved': 'Kompaniya nomi muvaffaqiyatli saqlandi',
      'logo_uploaded': 'Logo muvaffaqiyatli yuklandi',
      'uzbek': 'O\'zbekcha',
      'english': 'English',
      'russian': 'Русский',
      'company_name_placeholder': 'Kompaniya nomini kiriting...',
    },
    'ru': {
      'settings': 'Настройки',
      'general': 'Общие',
      'language': 'Язык',
      'attendance_settings': 'Настройки посещаемости',
      'enable_message': 'Включить сообщение посещаемости',
      'attendance_message': 'Сообщение посещаемости',
      'message_placeholder': 'Введите ваше сообщение посещаемости...',
      'home_customization': 'Настройка главной страницы',
      'show_today_card': 'Показать карточку сегодняшней посещаемости',
      'show_calendar': 'Показать календарь посещаемости',
      'compact_view': 'Компактный вид',
      'company_settings': 'Настройки компании',
      'company_name': 'Название компании',
      'company_logo': 'Логотип компании',
      'change_logo': 'Изменить логотип',
      'upload_logo': 'Загрузить логотип',
      'save_company_name': 'Сохранить название компании',
      'about': 'О приложении',
      'version': 'Версия',
      'app_info': 'Информация о приложении',
      'save': 'Сохранить',
      'saved': 'Настройки успешно сохранены',
      'company_name_saved': 'Название компании успешно сохранено',
      'logo_uploaded': 'Логотип успешно загружен',
      'uzbek': 'O\'zbekcha',
      'english': 'English',
      'russian': 'Русский',
      'company_name_placeholder': 'Введите название компании...',
    },
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkUserRole();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    super.dispose();
  }

  Future<void> _checkUserRole() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final userResponse = await Supabase.instance.client
          .from('users')
          .select('is_super_admin, company_id')
          .eq('id', userId)
          .maybeSingle();

      if (userResponse != null) {
        setState(() {
          _isAdmin = userResponse['is_super_admin'] == true;

          _companyId = userResponse['company_id'];
        });

        if (_isAdmin && _companyId != null) {
          await _loadCompanyInfo();
        }
      }
    } catch (e) {
      print('Error checking user role: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCompanyInfo() async {
    try {
      final companyResponse = await Supabase.instance.client
          .from('companies')
          .select('company_name, logo_url')
          .eq('id', _companyId!)
          .maybeSingle();

      if (companyResponse != null) {
        setState(() {
          _companyName = companyResponse['company_name'];
          _companyLogo = companyResponse['logo_url'];
          _companyNameController.text = _companyName ?? '';
        });
      }
    } catch (e) {
      print('Error loading company info: $e');
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentLanguage = prefs.getString('language') ?? 'uz';
      _enableAttendanceMessage =
          prefs.getBool('enableAttendanceMessage') ?? false;
      _attendanceMessage = prefs.getString('attendanceMessage') ?? '';
      _showTodayCard = prefs.getBool('showTodayCard') ?? true;
      _showCalendar = prefs.getBool('showCalendar') ?? true;
      _compactView = prefs.getBool('compactView') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', _currentLanguage);

    // Only save user-specific settings for non-admin users
    if (!_isAdmin) {
      await prefs.setBool('enableAttendanceMessage', _enableAttendanceMessage);
      await prefs.setString('attendanceMessage', _attendanceMessage);
      await prefs.setBool('showTodayCard', _showTodayCard);
      await prefs.setBool('showCalendar', _showCalendar);
      await prefs.setBool('compactView', _compactView);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_translate('saved')),
          backgroundColor: successColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _saveCompanyName() async {
    if (_companyId == null || _companyNameController.text.trim().isEmpty)
      return;

    try {
      await Supabase.instance.client
          .from('companies')
          .update({'company_name': _companyNameController.text.trim()}).eq(
              'id', _companyId!);

      setState(() {
        _companyName = _companyNameController.text.trim();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_translate('company_name_saved')),
            backgroundColor: successColor,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      print('Error saving company name: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xatolik yuz berdi'),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
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

        if (fileBytes != null && _companyId != null) {
          // Upload to Supabase Storage
          await Supabase.instance.client.storage
              .from('photos')
              .uploadBinary(fileName, fileBytes);

          // Get public URL
          final logoUrl = Supabase.instance.client.storage
              .from('photos')
              .getPublicUrl(fileName);

          // Update company record
          await Supabase.instance.client
              .from('companies')
              .update({'logo_url': logoUrl}).eq('id', _companyId!);

          setState(() {
            _companyLogo = logoUrl;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_translate('logo_uploaded')),
                backgroundColor: successColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error uploading logo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logo yuklashda xatolik'),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      setState(() => _isUploadingLogo = false);
    }
  }

  String _translate(String key) {
    return _localizedStrings[_currentLanguage]?[key] ??
        _localizedStrings['uz']?[key] ??
        key;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _translate('settings'),
          style: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(CupertinoIcons.back, color: primaryColor),
        ),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: Text(
              _translate('save'),
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              _buildGeneralSection(),
              SizedBox(height: 24),
              if (_isAdmin) ...[
                _buildCompanySection(),
                SizedBox(height: 24),
              ] else ...[
                _buildAttendanceSection(),
                SizedBox(height: 24),
                _buildHomeCustomizationSection(),
                SizedBox(height: 24),
              ],
              _buildAboutSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralSection() {
    return _buildSection(
      title: _translate('general'),
      icon: CupertinoIcons.settings,
      children: [
        _buildLanguageSelector(),
      ],
    );
  }

  Widget _buildCompanySection() {
    return _buildSection(
      title: _translate('company_settings'),
      icon: CupertinoIcons.house,
      children: [
        // Company Name
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _translate('company_name'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _companyNameController,
                      decoration: InputDecoration(
                        hintText: _translate('company_name_placeholder'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _saveCompanyName,
                    child: Icon(CupertinoIcons.checkmark),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.all(12),
                      minimumSize: Size(48, 48),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        // Company Logo
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _translate('company_logo'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
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
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              _companyLogo!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(CupertinoIcons.building_2_fill,
                                      color: Colors.white, size: 30),
                            ),
                          )
                        : Icon(CupertinoIcons.building_2_fill,
                            color: Colors.white, size: 30),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isUploadingLogo ? null : _uploadLogo,
                      icon: _isUploadingLogo
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
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
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceSection() {
    return _buildSection(
      title: _translate('attendance_settings'),
      icon: CupertinoIcons.clock,
      children: [
        _buildSwitchTile(
          title: _translate('enable_message'),
          value: _enableAttendanceMessage,
          onChanged: (value) {
            setState(() => _enableAttendanceMessage = value);
          },
        ),
        if (_enableAttendanceMessage) ...[
          SizedBox(height: 16),
          _buildMessageInput(),
        ],
      ],
    );
  }

  Widget _buildHomeCustomizationSection() {
    return _buildSection(
      title: _translate('home_customization'),
      icon: CupertinoIcons.house,
      children: [
        _buildSwitchTile(
          title: _translate('show_today_card'),
          value: _showTodayCard,
          onChanged: (value) {
            setState(() => _showTodayCard = value);
          },
        ),
        SizedBox(height: 12),
        _buildSwitchTile(
          title: _translate('show_calendar'),
          value: _showCalendar,
          onChanged: (value) {
            setState(() => _showCalendar = value);
          },
        ),
        SizedBox(height: 12),
        _buildSwitchTile(
          title: _translate('compact_view'),
          value: _compactView,
          onChanged: (value) {
            setState(() => _compactView = value);
          },
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return _buildSection(
      title: _translate('about'),
      icon: CupertinoIcons.info_circle,
      children: [
        _buildInfoTile(
          title: _translate('version'),
          value: '2.0.0',
          icon: CupertinoIcons.tag,
        ),
        SizedBox(height: 12),
        _buildInfoTile(
          title: _translate('app_info'),
          value: 'Davomat - By ModderBoy',
          icon: CupertinoIcons.device_phone_portrait,
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
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
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: primaryColor, size: 20),
              ),
              SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(CupertinoIcons.globe, color: primaryColor, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              _translate('language'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textPrimary,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: primaryColor.withOpacity(0.3)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _currentLanguage,
                icon: Icon(CupertinoIcons.chevron_down,
                    color: primaryColor, size: 16),
                items: [
                  DropdownMenuItem(
                      value: 'uz', child: Text(_translate('uzbek'))),
                  DropdownMenuItem(
                      value: 'en', child: Text(_translate('english'))),
                  DropdownMenuItem(
                      value: 'ru', child: Text(_translate('russian'))),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _currentLanguage = value);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textPrimary,
              ),
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeColor: primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _translate('attendance_message'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
          ),
          SizedBox(height: 8),
          TextField(
            controller: TextEditingController(text: _attendanceMessage),
            onChanged: (value) => _attendanceMessage = value,
            decoration: InputDecoration(
              hintText: _translate('message_placeholder'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
              contentPadding: EdgeInsets.all(12),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: primaryColor, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
