import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/dio_client.dart' show dioProvider;
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_provider.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/experts/screens/experts_screen.dart';
import '../../features/chat/screens/conversations_screen.dart';
import '../../features/chat/providers/chat_provider.dart' show aiChatProvider;
import '../../features/chat/providers/conversations_provider.dart';
import '../../features/profile/screens/profile_screen.dart';
import 'nexora_logo.dart';

class MainLayout extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  const MainLayout({super.key, required this.navigationShell});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _heartbeatTimer;

  // ── AI menu overlay ────────────────────────────────────────────────────────
  bool _menuOpen = false;
  late final AnimationController _menuCtrl;
  late final Animation<double> _backdropAnim;
  late final Animation<double> _btn1Anim;
  late final Animation<double> _btn2Anim;
  late final Animation<double> _rotateAnim;
  DateTime? _lastPressed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentPage = widget.navigationShell.currentIndex;
    _pageController = PageController(initialPage: _currentPage);

    // Animation setup
    _menuCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _backdropAnim = CurvedAnimation(parent: _menuCtrl, curve: Curves.easeOut);
    _btn1Anim = CurvedAnimation(
      parent: _menuCtrl,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
    );
    _btn2Anim = CurvedAnimation(
      parent: _menuCtrl,
      curve: const Interval(0.15, 0.85, curve: Curves.easeOutBack),
    );
    _rotateAnim = CurvedAnimation(parent: _menuCtrl, curve: Curves.easeInOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendHeartbeat();
      _startTimer();
    });
  }

  void _startTimer() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) => _sendHeartbeat());
  }

  void _stopTimer() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<void> _sendHeartbeat() async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/users/heartbeat');
    } catch (_) {}
  }

  Future<void> _sendOffline() async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/users/offline');
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _sendHeartbeat();
        _startTimer();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _stopTimer();
        _sendOffline();
        break;
      default:
        break;
    }
  }

  @override
  void didUpdateWidget(MainLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shellIndex = widget.navigationShell.currentIndex;
    if (shellIndex != _currentPage) {
      setState(() => _currentPage = shellIndex);
      _pageController.jumpToPage(shellIndex);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTimer();
    _pageController.dispose();
    _menuCtrl.dispose();
    super.dispose();
  }

  void _onTabTap(int page) {
    if (_menuOpen) _closeMenu();
    if (page == _currentPage) return;
    widget.navigationShell.goBranch(page);
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    widget.navigationShell.goBranch(page);
  }

  void _toggleMenu() {
    HapticFeedback.lightImpact();
    if (_menuOpen) {
      _closeMenu();
    } else {
      setState(() => _menuOpen = true);
      _menuCtrl.forward();
    }
  }

  void _closeMenu() {
    _menuCtrl.reverse().then((_) {
      if (mounted) setState(() => _menuOpen = false);
    });
  }

  Future<void> _onNewConversation() async {
    _closeMenu();
    // Reset so we always open a fresh conversation, not the previous one.
    ref.read(aiChatProvider.notifier).reset();
    await Future.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;
    context.push(AppRoutes.chat, extra: {
      'name': 'Assistant IA Nexora',
      'initials': 'N',
      'color': const Color(0xFF6366F1),
      'subtitle': 'Intelligence Artificielle',
      'online': true,
      'isAi': true,
    });
  }

  void _onMyConversations() {
    _closeMenu();
    // Switch to Messages tab and activate the IA filter
    ref.read(aiFilterRequestedProvider.notifier).state = true;
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        widget.navigationShell.goBranch(2);
        _pageController.animateToPage(
          2,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
        setState(() => _currentPage = 2);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // ── Watch theme so the entire shell rebuilds on every theme switch ──
    final themePreset = ref.watch(themeProvider);
    final isDark = themePreset.brightness == Brightness.dark;

    // Update system UI chrome immediately (status bar + nav bar colours)
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: themePreset.background,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));

    final navBar = PremiumBottomNavBar(
      currentPage: _currentPage,
      onTap: _onTabTap,
      menuOpen: _menuOpen,
      rotateAnim: _rotateAnim,
      onAiTap: _toggleMenu,
    );

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;

        // If overlay menu is open, close it first
        if (_menuOpen) {
          _closeMenu();
          return;
        }

        // If not on Home tab (index 0), switch back to Home tab first
        if (_currentPage != 0) {
          _onTabTap(0);
          return;
        }

        // Double tap within 2 seconds to exit the app
        final now = DateTime.now();
        if (_lastPressed == null ||
            now.difference(_lastPressed!) > const Duration(seconds: 2)) {
          _lastPressed = now;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Appuyez à nouveau pour quitter',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 90), // Sits perfectly above bottom nav
            ),
          );
        } else {
          await SystemNavigator.pop();
          // Fallback exit if SystemNavigator.pop() doesn't close the app immediately
          Future.delayed(const Duration(milliseconds: 200), () {
            exit(0);
          });
        }
      },
      child: Container(
        color: isDark ? Colors.black : themePreset.background,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Stack(
              children: [
                Scaffold(
                backgroundColor: AppColors.background,
                extendBody: true,
                body: PageView(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  physics: const ClampingScrollPhysics(),
                  // Not const — must receive new instances on theme change
                  children: [
                    _KeepAlive(child: HomeScreen()),
                    _KeepAlive(child: ExpertsScreen()),
                    _KeepAlive(child: ConversationsScreen()),
                    _KeepAlive(child: ProfileScreen()),
                  ],
                ),
                bottomNavigationBar: navBar,
              ),

              // ── Backdrop + floating buttons overlay ──────────────────────
              if (_menuOpen)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _closeMenu,
                    child: FadeTransition(
                      opacity: _backdropAnim,
                      child: Container(color: Colors.black54),
                    ),
                  ),
                ),

              if (_menuOpen)
                Positioned(
                  bottom: _fabBottomOffset(context),
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Button 1 — New conversation (edit icon)
                        _FabButton(
                          animation: _btn1Anim,
                          icon: Icons.edit_rounded,
                          onTap: _onNewConversation,
                        ),
                        const SizedBox(width: 28),
                        // Button 2 — My conversations (chat bubble icon)
                        _FabButton(
                          animation: _btn2Anim,
                          icon: Icons.chat_bubble_rounded,
                          onTap: _onMyConversations,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

  double _fabBottomOffset(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    // Position above the bottom nav bar (approx 70px tall) + some spacing
    return bottomPadding + 70 + 24;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Floating action button with scale + slide-up animation
// ─────────────────────────────────────────────────────────────────────────────

class _FabButton extends StatelessWidget {
  final Animation<double> animation;
  final IconData icon;
  final VoidCallback onTap;

  const _FabButton({
    required this.animation,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, 30 * (1 - animation.value)),
        child: Transform.scale(
          scale: animation.value.clamp(0.0, 1.0),
          child: Opacity(
            opacity: animation.value.clamp(0.0, 1.0),
            child: child,
          ),
        ),
      ),
      child: Builder(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final gradientColors = isDark
              ? const [Color(0xFF6366F1), Color(0xFF8B5CF6)]
              : [AppColors.primary, AppColors.secondary];
          final shadowColor = isDark
              ? const Color(0xFF6366F1)
              : AppColors.primary;
          return GestureDetector(
            onTap: onTap,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor.withAlpha(80),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
          );
        }
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Keep pages alive
// ─────────────────────────────────────────────────────────────────────────────

class _KeepAlive extends StatefulWidget {
  final Widget child;
  const _KeepAlive({required this.child});

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom nav bar
// ─────────────────────────────────────────────────────────────────────────────

class PremiumBottomNavBar extends StatelessWidget {
  final int currentPage;
  final ValueChanged<int> onTap;
  final VoidCallback onAiTap;
  final bool menuOpen;
  final Animation<double> rotateAnim;

  const PremiumBottomNavBar({
    super.key,
    required this.currentPage,
    required this.onTap,
    required this.onAiTap,
    required this.menuOpen,
    required this.rotateAnim,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barBg = isDark ? const Color(0xFF0A0E1F).withAlpha(230) : AppColors.surface.withAlpha(240);
    final borderSide = BorderSide(color: isDark ? const Color(0x15FFFFFF) : AppColors.border, width: 0.5);

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: barBg,
            border: Border(
              top: borderSide,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  NavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: 'Accueil',
                    isSelected: currentPage == 0,
                    onTap: () => onTap(0),
                  ),
                  NavItem(
                    icon: Icons.people_outline_rounded,
                    activeIcon: Icons.people_rounded,
                    label: 'Experts',
                    isSelected: currentPage == 1,
                    onTap: () => onTap(1),
                  ),
                  CenterLogoButton(
                    onTap: onAiTap,
                    menuOpen: menuOpen,
                    rotateAnim: rotateAnim,
                  ),
                  NavItem(
                    icon: Icons.chat_bubble_outline_rounded,
                    activeIcon: Icons.chat_bubble_rounded,
                    label: 'Messages',
                    isSelected: currentPage == 2,
                    onTap: () => onTap(2),
                  ),
                  NavItem(
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: 'Profil',
                    isSelected: currentPage == 3,
                    onTap: () => onTap(3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CenterLogoButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool menuOpen;
  final Animation<double> rotateAnim;

  const CenterLogoButton({
    super.key,
    required this.onTap,
    required this.menuOpen,
    required this.rotateAnim,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark
        ? (menuOpen
            ? const [Color(0xFF8B5CF6), Color(0xFFA78BFA)]
            : const [Color(0xFF6366F1), Color(0xFF8B5CF6)])
        : (menuOpen
            ? [AppColors.secondary, AppColors.secondaryLight]
            : [AppColors.primary, AppColors.secondary]);
    final shadowColor = isDark ? const Color(0xFF6366F1) : AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: rotateAnim,
            builder: (context, _) {
              final val = rotateAnim.value;
              return Transform.rotate(
                angle: val * 3.14159265, // Spin 180 degrees
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: colors,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor.withAlpha(menuOpen ? 80 : 40),
                        blurRadius: menuOpen ? 20 : 12,
                        spreadRadius: -2,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Opacity(
                          opacity: (1 - val).clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: (1 - val).clamp(0.0, 1.0),
                            child: const NexoraImageIcon(size: 26),
                          ),
                        ),
                        Opacity(
                          opacity: val.clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: val.clamp(0.0, 1.0),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const NavItem({
    super.key,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isSelected
        ? (isDark ? const Color(0xFF818CF8) : AppColors.primary)
        : (isDark ? const Color(0xFF64748B) : AppColors.textSecondary);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? activeIcon : icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

