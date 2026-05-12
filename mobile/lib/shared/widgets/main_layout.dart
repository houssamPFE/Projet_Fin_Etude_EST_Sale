import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/dio_client.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/experts/screens/experts_screen.dart';
import '../../features/chat/screens/conversations_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import 'nexora_logo.dart';

class MainLayout extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  const MainLayout({super.key, required this.navigationShell});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout>
    with WidgetsBindingObserver {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _heartbeatTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentPage = widget.navigationShell.currentIndex;
    _pageController = PageController(initialPage: _currentPage);

    // Start heartbeat — first beat immediately, then every 30 seconds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendHeartbeat();
      _startTimer();
    });
  }

  void _startTimer() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _sendHeartbeat(),
    );
  }

  void _stopTimer() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<void> _sendHeartbeat() async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/users/heartbeat');
    } catch (_) {
      // Non-critical — silently ignore
    }
  }

  Future<void> _sendOffline() async {
    // Best-effort — tell the server we're offline so others see the dot
    // go grey immediately instead of waiting for the Redis TTL to expire.
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/users/offline');
    } catch (_) {}
  }

  /// React to app lifecycle changes (foreground ↔ background)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // App came back to foreground — heartbeat immediately + restart timer
        _sendHeartbeat();
        _startTimer();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // App going to background / being killed — stop timer + signal offline
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
    super.dispose();
  }

  void _onTabTap(int page) {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Scaffold(
            backgroundColor: AppColors.background,
            extendBody: true,
            body: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              physics: const ClampingScrollPhysics(),
              children: const [
                _KeepAlive(child: HomeScreen()),
                _KeepAlive(child: ExpertsScreen()),
                _KeepAlive(child: ConversationsScreen()),
                _KeepAlive(child: ProfileScreen()),
              ],
            ),
            bottomNavigationBar: PremiumBottomNavBar(
              currentPage: _currentPage,
              onTap: _onTabTap,
              onAiTap: () => context.push(AppRoutes.aiTriage),
            ),
          ),
        ),
      ),
    );
  }
}

// Keeps PageView pages alive when swiped away
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

class PremiumBottomNavBar extends StatelessWidget {
  final int currentPage;
  final ValueChanged<int> onTap;
  final VoidCallback onAiTap;

  const PremiumBottomNavBar({
    super.key,
    required this.currentPage,
    required this.onTap,
    required this.onAiTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A0E1F).withAlpha(230),
            border: const Border(
              top: BorderSide(color: Color(0x15FFFFFF), width: 0.5),
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
                  CenterLogoButton(onTap: onAiTap),
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
  const CenterLogoButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withAlpha(40),
                  blurRadius: 12,
                  spreadRadius: -2,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Center(child: NexoraImageIcon(size: 26)),
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
    final color = isSelected ? const Color(0xFF818CF8) : const Color(0xFF64748B);

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
