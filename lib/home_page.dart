import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobility/EditProfilePage.dart';
import 'package:mobility/edit_password.dart';
import 'package:mobility/reauthenticateUser.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../widgets/menu_overlay.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'frame28_widget.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'user_repository.dart';

class MapWithBottomSheetPage extends StatefulWidget {
  const MapWithBottomSheetPage({super.key});

  @override
  State<MapWithBottomSheetPage> createState() => _MapWithBottomSheetPageState();
}

class _MapWithBottomSheetPageState extends State<MapWithBottomSheetPage>
    with SingleTickerProviderStateMixin {
  late final WebViewController _controller;
  bool _showMenuOverlay = false;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  String? _userName;
  final UserRepository _userRepository = UserRepository();
  bool _isLoading = false; // 로딩 상태 추가
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _initWebView();
    _initAnimation();
    _loadUserName(); // 앱 시작 시 사용자 이름 로드
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'MapChannel',
        onMessageReceived: (message) => debugPrint('받은 메시지: ${message.message}'),
      )
      ..loadRequest(Uri.parse('https://mobility-1997a.web.app/map.html'));
  }

  void _initAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  // 로그아웃 함수 구현
  Future<void> _logoutUser() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login'); // 로그인 화면으로 이동
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그아웃 실패: ${e.toString()}'))
        );
      }
    }
  }
  

  Future<void> _loadUserName() async {
  if (_isLoading) return;
  
  setState(() => _isLoading = true);
  
  try {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    debugPrint('현재 사용자 UID: $userId');
    
    if (userId == null) {
      debugPrint('로그인되지 않음');
      return;
    }

    final userInfo = await _userRepository.getUserAdditionalInfo(userId);
    debugPrint('조회된 데이터: $userInfo');
    
    if (userInfo == null) {
      debugPrint('사용자 정보 없음');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사용자 정보가 없습니다')));
      }
      return;
    }

    if (mounted) {
      setState(() {
        _userName = userInfo['name']?.toString(); // null 안전성 추가
        debugPrint('설정된 사용자 이름: $_userName');
      });
    }
  } catch (e, stackTrace) {
    debugPrint('사용자 정보 로드 오류: $e');
    debugPrint('스택 트레이스: $stackTrace');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사용자 정보 조회 중 오류 발생')));
    }
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

  void _openMenu() {
    if (_isLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사용자 정보 로드 중...')));
      return;
    }
    
    if (_userName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사용자 정보가 없습니다')));
      _loadUserName(); // 재시도
      return;
    }
    
    setState(() => _showMenuOverlay = true);
    _animationController.forward();
  }

  void _closeMenu() {
    _animationController.reverse().then((_) {
      if (mounted) setState(() => _showMenuOverlay = false);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          
          Positioned.fill(
            child: DraggableScrollableSheet(
              initialChildSize: 0.35,
              minChildSize: 0.1,
              maxChildSize: 0.50,
              builder: (context, scrollController) => Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Frame28Widget(),
                  ),
                ),
              ),
            ),
          ),
          
          Positioned(
            top: 50.h,
            left: 20.w,
            child: GestureDetector(
              onTap: _openMenu,
              child: Container(
                width: 50.w,
                height: 50.h,
                decoration: const BoxDecoration(color: Colors.transparent),
                child: Stack(
                  children: [
                    Positioned(top: 10.h, left: 3.w, child: SvgPicture.asset('assets/images/menu2.svg')),
                    Positioned(top: 20.h, left: 3.w, child: SvgPicture.asset('assets/images/menu3.svg')),
                    Positioned(top: 30.h, left: 3.w, child: SvgPicture.asset('assets/images/menu1.svg')),
                  ],
                ),
              ),
            ),
          ),
          
          if (_showMenuOverlay) ...[
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeMenu,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                  child: Container(color: const Color.fromRGBO(0, 0, 0, 0.4)),
                ),
              ),
            ),
            SlideTransition(
              position: _slideAnimation,
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  if (details.delta.dx < -10) _closeMenu();
                },
                child: MenuOverlay(
                  onClose: _closeMenu,
                  onLogout: _logoutUser,
                  userName: _userName ?? '이름 없음',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}