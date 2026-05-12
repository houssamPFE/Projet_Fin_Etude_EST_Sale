import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/dio_client.dart';
import '../router/app_router.dart';

// Background message handler — must be top-level
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background: ${message.messageId}');
}

// ── FCMService ──────────────────────────────────────────────────────────────

class FCMService {
  final Dio _dio;
  FCMService(this._dio);

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] Permission: ${settings.authorizationStatus}');
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // iOS foreground options
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) await _registerToken(token);
    FirebaseMessaging.instance.onTokenRefresh.listen(_registerToken);

    // Foreground — show in-app banner
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('[FCM] Foreground: ${message.notification?.title}');
      _showInAppBanner(message);
    });

    // Background tap — deep link to conversation
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('[FCM] Tapped (background): ${message.data}');
      _navigate(message.data);
    });

    // Cold start — app was killed, user tapped notification
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      debugPrint('[FCM] Cold start: ${initial.data}');
      Future.delayed(const Duration(milliseconds: 600), () => _navigate(initial.data));
    }
  }

  // ── Deep link navigation ─────────────────────────────────────────────────

  void _navigate(Map<String, dynamic> data) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final conversationId = int.tryParse(data['conversation_id']?.toString() ?? '');

    if (conversationId != null) {
      // Go to messages list first, then push the chat screen
      context.go(AppRoutes.messages);
      Future.delayed(const Duration(milliseconds: 300), () {
        navigatorKey.currentContext?.push(AppRoutes.chat, extra: {
          'name':           data['expert_name']  ?? 'Expert',
          'initials':       ((data['expert_name'] as String?) ?? 'E').isNotEmpty
                                ? ((data['expert_name'] as String))[0].toUpperCase()
                                : 'E',
          'color':          const Color(0xFF8B5CF6),
          'subtitle':       data['specialty']    ?? 'Expert',
          'online':         true,
          'isAi':           false,
          'conversationId': conversationId,
        });
      });
    } else {
      context.go(AppRoutes.messages);
    }
  }

  // ── In-app foreground banner ─────────────────────────────────────────────

  void _showInAppBanner(RemoteMessage message) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final notification = message.notification;
    if (notification == null) return;

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _InAppBanner(
        title: notification.title ?? 'Nexora',
        body:  notification.body  ?? '',
        onTap: () {
          entry.remove();
          _navigate(message.data);
        },
        onDismiss: entry.remove,
      ),
    );

    overlay.insert(entry);
    // Auto-dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (entry.mounted) entry.remove();
    });
  }

  // ── Token registration ────────────────────────────────────────────────────

  Future<void> _registerToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString('fcm_token') == token) return;
      await _dio.put('/users/fcm-token', data: {'fcm_token': token});
      await prefs.setString('fcm_token', token);
      debugPrint('[FCM] Token registered');
    } catch (e) {
      debugPrint('[FCM] Token registration failed: $e');
    }
  }
}

// ── In-app notification banner widget ────────────────────────────────────────

class _InAppBanner extends StatefulWidget {
  final String title;
  final String body;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _InAppBanner({
    required this.title,
    required this.body,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_InAppBanner> createState() => _InAppBannerState();
}

class _InAppBannerState extends State<_InAppBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutQuart));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F35),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF8B5CF6).withAlpha(80)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(100),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                      ),
                    ),
                    child: const Icon(Icons.notifications_rounded,
                        size: 18, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.body,
                          style: TextStyle(
                            color: Colors.white.withAlpha(170),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onDismiss,
                    child: Icon(Icons.close_rounded,
                        size: 18, color: Colors.white.withAlpha(120)),
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

final fcmServiceProvider = Provider<FCMService>((ref) {
  return FCMService(ref.read(dioProvider));
});
