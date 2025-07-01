import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class InAppWebViewPage extends StatefulWidget {
  final String url;
  final String title;
  final String currentLanguage;

  const InAppWebViewPage({
    Key? key,
    required this.url,
    required this.title,
    required this.currentLanguage,
  }) : super(key: key);

  @override
  _InAppWebViewPageState createState() => _InAppWebViewPageState();
}

class _InAppWebViewPageState extends State<InAppWebViewPage>
    with TickerProviderStateMixin {
  late final WebViewController _controller;
  bool _isLoadingPage = true;
  bool _hasInternet = true;
  StreamSubscription? _connectivitySubscription;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // Modern colors
  static const Color primaryColor = Color(0xFF6e38c9);
  static const Color secondaryColor = Color(0xFF9c6bff);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color errorColor = Color(0xFFEF4444);

  String _translateWebView(String key) {
    final Map<String, Map<String, String>> localizedStrings = {
      'en': {
        'no_internet_connection': 'No Internet Connection',
        'connection_lost': 'Connection Lost',
        'connection_lost_desc':
            'Please check your internet connection and try again.',
        'loading': 'Loading...',
        'retry': 'Retry',
        'server_error': 'Server Error',
        'server_error_desc': 'Unable to load the page. Please try again later.',
        'page_not_found': 'Page Not Found',
        'page_not_found_desc': 'The requested page could not be found.',
      },
      'uz': {
        'no_internet_connection': 'Internet aloqasi yo\'q',
        'connection_lost': 'Aloqa uzildi',
        'connection_lost_desc':
            'Internet aloqangizni tekshiring va qaytadan urinib ko\'ring.',
        'loading': 'Yuklanmoqda...',
        'retry': 'Qaytadan',
        'server_error': 'Server xatoligi',
        'server_error_desc':
            'Sahifani yuklab bo\'lmadi. Keyinroq qaytadan urinib ko\'ring.',
        'page_not_found': 'Sahifa topilmadi',
        'page_not_found_desc': 'So\'ralgan sahifa topilmadi.',
      },
      'ru': {
        'no_internet_connection': 'Нет подключения к Интернету',
        'connection_lost': 'Соединение потеряно',
        'connection_lost_desc':
            'Проверьте подключение к интернету и попробуйте снова.',
        'loading': 'Загрузка...',
        'retry': 'Повторить',
        'server_error': 'Ошибка сервера',
        'server_error_desc': 'Не удалось загрузить страницу. Попробуйте позже.',
        'page_not_found': 'Страница не найдена',
        'page_not_found_desc': 'Запрашиваемая страница не найдена.',
      },
    };
    return localizedStrings[widget.currentLanguage]?[key] ??
        localizedStrings['uz']![key]!;
  }

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkInitialConnectivity();

    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      _updateConnectionStatus(results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi));
    });

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(backgroundColor)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) {
              setState(() => _isLoadingPage = true);
              _animationController.forward();
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() => _isLoadingPage = false);
              _animationController.reverse();
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              setState(() => _isLoadingPage = false);
              _animationController.reverse();
              print(
                  "WebResourceError: ${error.description}, Code: ${error.errorCode}");
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      );

    if (_hasInternet) {
      _controller.loadRequest(Uri.parse(widget.url));
    }
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  Future<void> _checkInitialConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    _updateConnectionStatus(
        connectivityResult.contains(ConnectivityResult.mobile) ||
            connectivityResult.contains(ConnectivityResult.wifi));
  }

  void _updateConnectionStatus(bool isConnected) {
    if (mounted) {
      final bool hadInternetBefore = _hasInternet;
      setState(() {
        _hasInternet = isConnected;
      });
      if (_hasInternet && !hadInternetBefore) {
        _controller.loadRequest(Uri.parse(widget.url));
      }
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildModernAppBar(),
      body: _hasInternet ? _buildWebView() : _buildErrorState(),
    );
  }

  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      backgroundColor: cardColor,
      foregroundColor: textPrimary,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(CupertinoIcons.back, color: textPrimary),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        widget.title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      actions: [
        if (_isLoadingPage && _hasInternet)
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              ),
            ),
          ),
      ],
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primaryColor.withOpacity(0.05),
              secondaryColor.withOpacity(0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }

  Widget _buildWebView() {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoadingPage) _buildLoadingOverlay(),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            color: backgroundColor.withOpacity(0.9),
            child: Center(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.1),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryColor, secondaryColor],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(cardColor),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        _translateWebView('loading'),
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
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    errorColor.withOpacity(0.1),
                    errorColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(60),
                border: Border.all(color: errorColor.withOpacity(0.2)),
              ),
              child: Icon(
                CupertinoIcons.wifi_slash,
                size: 60,
                color: errorColor,
              ),
            ),
            SizedBox(height: 24),
            Text(
              _translateWebView('connection_lost'),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              _translateWebView('connection_lost_desc'),
              style: TextStyle(
                fontSize: 16,
                color: textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                icon: Icon(CupertinoIcons.refresh, color: Colors.white),
                label: Text(
                  _translateWebView("retry"),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () async {
                  if (mounted) setState(() => _isLoadingPage = true);
                  await _checkInitialConnectivity();
                  if (_hasInternet) {
                    _controller.loadRequest(Uri.parse(widget.url));
                  } else {
                    if (mounted) setState(() => _isLoadingPage = false);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
