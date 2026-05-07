import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'files_screen.dart';
import '../utils/app_config.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  bool _authenticated = false;
  double _dragProgress = 0.0;
  bool _transitionStarted = false;

  @override
  void initState() {
    super.initState();
    
    // Пульсирующая анимация для иконки свайпа
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Проверяем авторизацию в фоне
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final token = await AuthService.getToken();
    if (mounted) {
      setState(() {
        _authenticated = token != null;
      });
    }
  }

  void _handleSwipe(DragUpdateDetails details) {
    if (_transitionStarted) return;
    
    final screenHeight = MediaQuery.of(context).size.height;
    final progress = (details.primaryDelta ?? 0).abs() / (screenHeight * 0.4);
    setState(() {
      _dragProgress = progress.clamp(0.0, 1.0);
    });
  }

  void _handleSwipeEnd(DragEndDetails details) {
    if (_transitionStarted) return;
    
    if (_dragProgress > 0.3 || details.primaryVelocity! < -300) {
      _startTransition();
    } else {
      setState(() {
        _dragProgress = 0.0;
      });
    }
  }

  void _startTransition() {
    if (_transitionStarted) return;
    _transitionStarted = true;
    
    _pulseController.stop();
    
    // Используем обычный Navigator.pushReplacement с MaterialPageRoute
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => _authenticated ? FilesScreen() : LoginScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final logoWidth = size.width;
    final logoHeight = logoWidth * 0.5 > 280 ? 280.0 : logoWidth * 0.5;

    return Scaffold(
      body: GestureDetector(
        onVerticalDragUpdate: _handleSwipe,
        onVerticalDragEnd: _handleSwipeEnd,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()
            ..translate(0.0, -_dragProgress * size.height * 0.4),
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Colors.white,
                  Colors.white.withOpacity(0.9),
                  Colors.grey.shade100,
                ],
                stops: [0.6, 0.9, 1.0],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                
                Lottie.asset(
                  'assets/animations/adidas.json',
                  width: logoWidth,
                  height: logoHeight,
                  repeat: true,
                  animate: true,
                ),
                
                const SizedBox(height: 20),
                
                Text(
                  AppConfig.appName,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    letterSpacing: 4,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  AppConfig.subtitle,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                
                const Spacer(flex: 2),
                
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: 1.0 - _dragProgress,
                      child: Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Column(
                          children: [
                            const Icon(
                              Icons.keyboard_arrow_up,
                              size: 36,
                              color: Colors.black45,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Свайпните вверх',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black38,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}