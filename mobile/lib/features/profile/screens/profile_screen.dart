import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/network/dio_client.dart' show dioProvider, fixStorageUrl;
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/models/auth_response.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/current_user_provider.dart';

const _kAvatarColor = Color(0xFF6366F1);

// ─────────────────────────────────────────────────────────────────────────────
// ProfileScreen
// ─────────────────────────────────────────────────────────────────────────────

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _notifPush = true;
  bool _notifEmail = false;
  bool _controllersHydrated = false;
  String? _saveError;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _hydrateControllers(AuthUser user) {
    if (_controllersHydrated) return;
    _nameController.text = user.name;
    _phoneController.text = user.phone ?? '';
    _controllersHydrated = true;
  }

  Future<void> _toggleEdit() async {
    if (!_isEditing) {
      setState(() {
        _isEditing = true;
        _saveError = null;
      });
      return;
    }

    // Save
    setState(() {
      _isSaving = true;
      _saveError = null;
    });
    try {
      final dio = ref.read(dioProvider);
      await dio.put('/users/profile', data: {
        'name': _nameController.text.trim(),
        if (_phoneController.text.trim().isNotEmpty)
          'phone': _phoneController.text.trim(),
      });
      ref.invalidate(currentUserProvider);
      _controllersHydrated = false;
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isEditing = false;
        });
        _showToast('Profil mis à jour', success: true);
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      String msg = 'Erreur lors de la sauvegarde.';
      if (data is Map<String, dynamic>) {
        final errors = data['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) msg = first.first.toString();
        } else {
          final m = data['message'];
          if (m is String && m.isNotEmpty) msg = m;
        }
      }
      if (mounted) {
        setState(() {
          _saveError = msg;
          _isSaving = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saveError = 'Erreur inattendue.';
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _onAvatarTap() async {
    final picker = ImagePicker();
    final choice = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.primaryLight),
              title: Text('Galerie photo', style: AppTextStyles.titleSmall),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: AppColors.primaryLight),
              title: Text('Prendre une photo', style: AppTextStyles.titleSmall),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (choice == null) return;

    final file = await picker.pickImage(
      source: choice,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (file == null) return;

    // Show local preview immediately — survives navigation via provider
    ref.read(localAvatarPathProvider.notifier).state = file.path;
    setState(() => _isUploadingAvatar = true);
    try {
      final dio = ref.read(dioProvider);
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(
          file.path,
          filename: 'avatar.jpg',
        ),
      });
      await dio.post('/users/avatar', data: formData);
      ref.invalidate(currentUserProvider);
      _controllersHydrated = false;
      if (mounted) {
        _showToast('Photo de profil mise à jour !', success: true);
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String? ??
          'Erreur lors de l\'upload.';
      if (mounted) {
        ref.read(localAvatarPathProvider.notifier).state = null;
        _showToast(msg, success: false);
      }
    } catch (_) {
      if (mounted) {
        ref.read(localAvatarPathProvider.notifier).state = null;
        _showToast('Erreur lors de l\'upload.', success: false);
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  void _showToast(String message, {required bool success}) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (ctx) => _ToastNotification(message: message, success: success),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), entry.remove);
  }

  void _onLogout() {
    showDialog(
      context: context,
      barrierColor: AppColors.overlay,
      builder: (_) => _LogoutDialog(
        onConfirm: () async {
          await ref.read(authProvider.notifier).logout();
          ref.invalidate(currentUserProvider);
          ref.read(localAvatarPathProvider.notifier).state = null;
          if (mounted) context.go(AppRoutes.login);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _ProfileBackground(size: size),
          SafeArea(
            child: userAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, s) => _ErrorState(
                message: 'Impossible de charger votre profil.',
                onRetry: () => ref.invalidate(currentUserProvider),
              ),
              data: (user) {
                _hydrateControllers(user);
                return _ProfileContent(
                  user: user,
                  isEditing: _isEditing,
                  isSaving: _isSaving,
                  isUploadingAvatar: _isUploadingAvatar,
                  localAvatarPath: ref.watch(localAvatarPathProvider),
                  nameController: _nameController,
                  phoneController: _phoneController,
                  notifPush: _notifPush,
                  notifEmail: _notifEmail,
                  saveError: _saveError,
                  onToggleEdit: _toggleEdit,
                  onAvatarTap: _isEditing ? _onAvatarTap : null,
                  onPushChanged: (v) => setState(() => _notifPush = v),
                  onEmailChanged: (v) => setState(() => _notifEmail = v),
                  onLogout: _onLogout,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ProfileContent
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileContent extends StatelessWidget {
  final AuthUser user;
  final bool isEditing;
  final bool isSaving;
  final bool isUploadingAvatar;
  final String? localAvatarPath;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final bool notifPush;
  final bool notifEmail;
  final String? saveError;
  final VoidCallback onToggleEdit;
  final VoidCallback? onAvatarTap;
  final ValueChanged<bool> onPushChanged;
  final ValueChanged<bool> onEmailChanged;
  final VoidCallback onLogout;

  const _ProfileContent({
    required this.user,
    required this.isEditing,
    required this.isSaving,
    required this.isUploadingAvatar,
    required this.localAvatarPath,
    required this.nameController,
    required this.phoneController,
    required this.notifPush,
    required this.notifEmail,
    required this.saveError,
    required this.onToggleEdit,
    required this.onAvatarTap,
    required this.onPushChanged,
    required this.onEmailChanged,
    required this.onLogout,
  });

  String get _memberSince {
    final dt = user.createdAt;
    if (dt == null) return '';
    final formatted = DateFormat('MMM y', 'fr_FR').format(dt);
    return 'Membre depuis $formatted';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 20, 0),
          child: _ProfileHeader(
            isEditing: isEditing,
            isSaving: isSaving,
            onToggleEdit: onToggleEdit,
          ),
        ).animate().fadeIn(duration: 400.ms),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 28),
                Center(
                  child: _AvatarSection(
                    isEditing: isEditing,
                    isUploading: isUploadingAvatar,
                    name: user.name,
                    initials: user.initials,
                    avatarUrl: user.avatarUrl,
                    localAvatarPath: localAvatarPath,
                    memberSince: _memberSince,
                    onAvatarTap: onAvatarTap,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 80.ms, duration: 500.ms)
                    .scale(
                      begin: const Offset(0.92, 0.92),
                      end: const Offset(1, 1),
                      curve: Curves.easeOut,
                    ),
                const SizedBox(height: 28),
                _InfoCard(
                  nameController: nameController,
                  phoneController: phoneController,
                  isEditing: isEditing,
                  email: user.email,
                  phone: user.phone,
                )
                    .animate()
                    .fadeIn(delay: 160.ms, duration: 500.ms)
                    .slideY(begin: 0.08, end: 0, curve: Curves.easeOut),
                if (saveError != null) ...[
                  const SizedBox(height: 10),
                  _ErrorBanner(message: saveError!)
                      .animate()
                      .fadeIn(duration: 300.ms),
                ],
                const SizedBox(height: 26),
                _SectionLabel(label: 'Paramètres')
                    .animate()
                    .fadeIn(delay: 230.ms),
                const SizedBox(height: 10),
                _SettingsCard(
                  notifPush: notifPush,
                  notifEmail: notifEmail,
                  onPushChanged: onPushChanged,
                  onEmailChanged: onEmailChanged,
                )
                    .animate()
                    .fadeIn(delay: 270.ms, duration: 500.ms)
                    .slideY(begin: 0.06, end: 0, curve: Curves.easeOut),
                const SizedBox(height: 20),
                _SectionLabel(label: 'Compte')
                    .animate()
                    .fadeIn(delay: 330.ms),
                const SizedBox(height: 10),
                _AccountCard()
                    .animate()
                    .fadeIn(delay: 370.ms, duration: 500.ms)
                    .slideY(begin: 0.06, end: 0, curve: Curves.easeOut),
                const SizedBox(height: 28),
                _LogoutButton(onTap: onLogout)
                    .animate()
                    .fadeIn(delay: 430.ms, duration: 500.ms)
                    .slideY(begin: 0.06, end: 0, curve: Curves.easeOut),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    'Nexora v1.0.0',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textTertiary),
                  ),
                ).animate().fadeIn(delay: 490.ms),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Background
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileBackground extends StatelessWidget {
  final Size size;
  const _ProfileBackground({required this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -size.height * 0.05,
          right: -size.width * 0.20,
          child: BlurOrb(
            width: size.width * 0.75,
            height: size.height * 0.35,
            color: const Color(0x2A6366F1),
          ),
        ),
        Positioned(
          top: size.height * 0.30,
          left: -size.width * 0.25,
          child: BlurOrb(
            width: size.width * 0.60,
            height: size.width * 0.60,
            color: const Color(0x1A8B5CF6),
          ),
        ),
        Positioned(
          bottom: -size.height * 0.04,
          right: size.width * 0.10,
          child: BlurOrb(
            width: size.width * 0.55,
            height: size.height * 0.18,
            color: const Color(0x123B82F6),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final bool isEditing;
  final bool isSaving;
  final VoidCallback onToggleEdit;

  const _ProfileHeader({
    required this.isEditing,
    required this.isSaving,
    required this.onToggleEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const NexoraBackButton(),
        const SizedBox(width: 10),
        Text('Mon Profil', style: AppTextStyles.headlineSmall),
        const Spacer(),
        GestureDetector(
          onTap: isSaving ? null : onToggleEdit,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: isEditing ? AppGradients.button : null,
              color: isEditing ? null : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: isEditing ? null : Border.all(color: AppColors.border),
            ),
            child: isSaving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isEditing
                            ? Icons.check_rounded
                            : Icons.edit_outlined,
                        size: 14,
                        color: isEditing
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isEditing ? 'Enregistrer' : 'Modifier',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: isEditing
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Avatar section
// ─────────────────────────────────────────────────────────────────────────────

class _AvatarSection extends StatelessWidget {
  final bool isEditing;
  final bool isUploading;
  final String name;
  final String initials;
  final String? avatarUrl;
  final String? localAvatarPath;
  final String memberSince;
  final VoidCallback? onAvatarTap;

  const _AvatarSection({
    required this.isEditing,
    required this.isUploading,
    required this.name,
    required this.initials,
    required this.avatarUrl,
    required this.localAvatarPath,
    required this.memberSince,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kAvatarColor.withAlpha(16),
              ),
            ),
            Container(
              width: 136,
              height: 136,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.primary,
              ),
              padding: const EdgeInsets.all(2.5),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.card,
                ),
                padding: const EdgeInsets.all(3),
                child: _buildAvatarInner(),
              ),
            ),
            if (isEditing)
              Positioned(
                bottom: 10,
                right: 10,
                child: GestureDetector(
                  onTap: onAvatarTap,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppGradients.button,
                      border: Border.all(
                        color: AppColors.background,
                        width: 2.5,
                      ),
                    ),
                    child: isUploading
                        ? const Padding(
                            padding: EdgeInsets.all(9),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 17,
                          ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(name, style: AppTextStyles.headlineMedium),
        if (memberSince.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            memberSince,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
        if (isEditing) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onAvatarTap,
            child: Text(
              'Changer la photo de profil',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primaryLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAvatarInner() {
    // Local file takes priority — always visible, never blocked by network issues
    if (localAvatarPath != null) {
      return ClipOval(
        child: Image.file(
          File(localAvatarPath!),
          fit: BoxFit.cover,
        ),
      );
    }
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: fixStorageUrl(avatarUrl!),
          fit: BoxFit.cover,
          placeholder: (ctx, url) => _initialsContainer(),
          errorWidget: (ctx, url, err) => _initialsContainer(),
        ),
      );
    }
    return _initialsContainer();
  }

  Widget _initialsContainer() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _kAvatarColor.withAlpha(220),
            _kAvatarColor.withAlpha(150),
          ],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 38,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info card
// ─────────────────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final bool isEditing;
  final String email;
  final String? phone;

  const _InfoCard({
    required this.nameController,
    required this.phoneController,
    required this.isEditing,
    required this.email,
    required this.phone,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhone = phone != null && phone!.trim().isNotEmpty;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isEditing
              ? AppColors.primary.withAlpha(80)
              : AppColors.border,
        ),
        boxShadow: isEditing
            ? [
                BoxShadow(
                  color: AppColors.primary.withAlpha(20),
                  blurRadius: 24,
                  spreadRadius: -4,
                ),
              ]
            : [],
      ),
      child: isEditing
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informations personnelles',
                  style: AppTextStyles.titleSmall
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                GlassTextField(
                  controller: nameController,
                  label: 'Nom complet',
                  hint: 'Votre nom',
                  prefixIcon: Icons.person_outline_rounded,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                GlassTextField(
                  controller: phoneController,
                  label: 'Numéro de téléphone',
                  hint: '+212 6 00 00 00 00',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 13,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'L\'adresse e-mail ne peut pas être modifiée.',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ],
            )
          : Column(
              children: [
                _InfoRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Nom',
                  value: nameController.text,
                ),
                _RowDivider(),
                _InfoRow(
                  icon: Icons.email_outlined,
                  label: 'E-mail',
                  value: email,
                ),
                _RowDivider(),
                _InfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Téléphone',
                  value: hasPhone ? phone! : 'Non renseigné',
                  valueColor:
                      hasPhone ? null : AppColors.textTertiary,
                ),
              ],
            ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, size: 17, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.titleSmall.copyWith(
                  color: valueColor ?? AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: AppColors.divider);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error banner
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withAlpha(50)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 16, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.caption.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section label
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AppTextStyles.overline.copyWith(
        color: AppColors.textTertiary,
        letterSpacing: 1.8,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Settings card
// ─────────────────────────────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final bool notifPush;
  final bool notifEmail;
  final ValueChanged<bool> onPushChanged;
  final ValueChanged<bool> onEmailChanged;

  const _SettingsCard({
    required this.notifPush,
    required this.notifEmail,
    required this.onPushChanged,
    required this.onEmailChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _ToggleRow(
            icon: Icons.notifications_outlined,
            label: 'Notifications push',
            value: notifPush,
            onChanged: onPushChanged,
          ),
          Container(height: 1, color: AppColors.divider),
          _ToggleRow(
            icon: Icons.email_outlined,
            label: 'Notifications e-mail',
            value: notifEmail,
            onChanged: onEmailChanged,
          ),
          Container(height: 1, color: AppColors.divider),
          _NavRow(
            icon: Icons.language_rounded,
            label: 'Langue',
            isLast: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Français',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textTertiary,
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 10, 4),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: AppColors.primaryLight),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label, style: AppTextStyles.titleSmall),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primary,
            inactiveThumbColor: AppColors.textTertiary,
            inactiveTrackColor: AppColors.surfaceElevated,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final bool isLast;
  final VoidCallback? onTap;

  const _NavRow({
    required this.icon,
    required this.label,
    this.trailing,
    this.isLast = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 14, 16, isLast ? 14 : 10),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 17, color: AppColors.primaryLight),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label, style: AppTextStyles.titleSmall),
            ),
            trailing ??
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textTertiary,
                  size: 18,
                ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Account card
// ─────────────────────────────────────────────────────────────────────────────

class _AccountCard extends StatelessWidget {
  const _AccountCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _NavRow(
            icon: Icons.shield_outlined,
            label: 'Confidentialité & sécurité',
            onTap: () => context.push(AppRoutes.security),
          ),
          Container(height: 1, color: AppColors.divider),
          const _NavRow(
            icon: Icons.help_outline_rounded,
            label: 'Aide & Support',
          ),
          Container(height: 1, color: AppColors.divider),
          const _NavRow(
            icon: Icons.info_outline_rounded,
            label: 'À propos de Nexora',
            isLast: true,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Logout button
// ─────────────────────────────────────────────────────────────────────────────

class _LogoutButton extends StatefulWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});

  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.errorBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.error.withAlpha(60)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.logout_rounded,
                color: AppColors.error,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                'Se déconnecter',
                style: AppTextStyles.buttonMedium
                    .copyWith(color: AppColors.error),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Logout confirmation dialog
// ─────────────────────────────────────────────────────────────────────────────

class _LogoutDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  const _LogoutDialog({required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(60),
              blurRadius: 40,
              spreadRadius: -8,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.errorBg,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.error.withAlpha(50)),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: AppColors.error,
                size: 24,
              ),
            ),
            const SizedBox(height: 20),
            Text('Se déconnecter ?', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 10),
            Text(
              'Vous serez redirigé vers la page de connexion.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Center(
                        child: Text(
                          'Annuler',
                          style: AppTextStyles.buttonMedium
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      onConfirm();
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.errorBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.error.withAlpha(60),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Déconnecter',
                          style: AppTextStyles.buttonMedium
                              .copyWith(color: AppColors.error),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Toast notification (overlay — replaces SnackBar)
// ─────────────────────────────────────────────────────────────────────────────

class _ToastNotification extends StatefulWidget {
  final String message;
  final bool success;
  const _ToastNotification({required this.message, required this.success});

  @override
  State<_ToastNotification> createState() => _ToastNotificationState();
}

class _ToastNotificationState extends State<_ToastNotification>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    _ctrl.forward();

    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted) _ctrl.reverse();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.success ? AppColors.success : AppColors.error;
    final bg = widget.success ? AppColors.successBg : AppColors.errorBg;
    final icon =
        widget.success ? Icons.check_circle_rounded : Icons.error_rounded;

    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 24,
      left: 20,
      right: 20,
      child: FadeTransition(
        opacity: _opacity,
        child: SlideTransition(
          position: _slide,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withAlpha(80)),
                boxShadow: [
                  BoxShadow(
                    color: color.withAlpha(40),
                    blurRadius: 20,
                    spreadRadius: -4,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withAlpha(60),
                    blurRadius: 24,
                    spreadRadius: -6,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Error state
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: 36),
            const SizedBox(height: 12),
            Text(
              message,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  gradient: AppGradients.button,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Réessayer',
                  style:
                      AppTextStyles.labelMedium.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
