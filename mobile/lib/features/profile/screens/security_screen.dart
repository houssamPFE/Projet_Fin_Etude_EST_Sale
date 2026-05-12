import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/token_storage.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/providers/current_user_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SecurityScreen
// ─────────────────────────────────────────────────────────────────────────────

class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _SecurityBackground(size: size),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: userAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                    error: (e, s) => _ErrorRetry(
                      onRetry: () => ref.invalidate(currentUserProvider),
                    ),
                    data: (user) => SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionLabel(label: 'Authentification')
                              .animate()
                              .fadeIn(delay: 60.ms),
                          const SizedBox(height: 10),
                          _TwoFactorCard(
                            enabled: user.twoFactorEnabled,
                            onChanged: () => ref.invalidate(currentUserProvider),
                          )
                              .animate()
                              .fadeIn(delay: 100.ms, duration: 500.ms)
                              .slideY(begin: 0.06, end: 0, curve: Curves.easeOut),
                          const SizedBox(height: 24),
                          _SectionLabel(label: 'Mot de passe')
                              .animate()
                              .fadeIn(delay: 160.ms),
                          const SizedBox(height: 10),
                          const _ChangePasswordCard()
                              .animate()
                              .fadeIn(delay: 200.ms, duration: 500.ms)
                              .slideY(begin: 0.06, end: 0, curve: Curves.easeOut),
                          const SizedBox(height: 28),
                          _SectionLabel(
                            label: 'Zone de danger',
                            color: AppColors.error,
                          ).animate().fadeIn(delay: 270.ms),
                          const SizedBox(height: 10),
                          const _DeleteAccountCard()
                              .animate()
                              .fadeIn(delay: 310.ms, duration: 500.ms)
                              .slideY(begin: 0.06, end: 0, curve: Curves.easeOut),
                        ],
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 20, 12),
      child: Row(
        children: [
          const NexoraBackButton(),
          const SizedBox(width: 10),
          Text('Confidentialité & sécurité', style: AppTextStyles.headlineSmall),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Background
// ─────────────────────────────────────────────────────────────────────────────

class _SecurityBackground extends StatelessWidget {
  final Size size;
  const _SecurityBackground({required this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -size.height * 0.05,
          right: -size.width * 0.20,
          child: BlurOrb(
            width: size.width * 0.70,
            height: size.height * 0.30,
            color: const Color(0x226366F1),
          ),
        ),
        Positioned(
          bottom: -size.height * 0.04,
          left: -size.width * 0.20,
          child: BlurOrb(
            width: size.width * 0.55,
            height: size.height * 0.18,
            color: const Color(0x158B5CF6),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section label
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color? color;
  const _SectionLabel({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AppTextStyles.overline.copyWith(
        color: color ?? AppColors.textTertiary,
        letterSpacing: 1.8,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2FA Card
// ─────────────────────────────────────────────────────────────────────────────

class _TwoFactorCard extends ConsumerStatefulWidget {
  final bool enabled;
  final VoidCallback onChanged;

  const _TwoFactorCard({required this.enabled, required this.onChanged});

  @override
  ConsumerState<_TwoFactorCard> createState() => _TwoFactorCardState();
}

class _TwoFactorCardState extends ConsumerState<_TwoFactorCard> {
  bool _loading = false;
  String? _error;

  // Enable flow state
  String? _qrUrl;
  String? _secret;
  final _codeController = TextEditingController();
  bool _confirmLoading = false;
  String? _confirmError;

  // Disable flow state
  bool _showDisable = false;
  final _disablePassController = TextEditingController();
  bool _disableLoading = false;
  String? _disableError;

  @override
  void dispose() {
    _codeController.dispose();
    _disablePassController.dispose();
    super.dispose();
  }

  Future<void> _startEnable() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post<Map<String, dynamic>>('/auth/2fa/enable');
      final data = res.data!['data'] as Map<String, dynamic>;
      setState(() {
        _qrUrl = data['qr_code_url'] as String;
        _secret = data['secret'] as String;
        _loading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _error = _parseError(e);
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Une erreur est survenue.';
        _loading = false;
      });
    }
  }

  Future<void> _confirmEnable() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _confirmError = 'Entrez un code à 6 chiffres.');
      return;
    }
    setState(() {
      _confirmLoading = true;
      _confirmError = null;
    });
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/auth/2fa/confirm', data: {'code': code});
      setState(() {
        _qrUrl = null;
        _secret = null;
        _codeController.clear();
        _confirmLoading = false;
      });
      widget.onChanged();
      if (mounted) _showSuccess(context, '2FA activée avec succès !');
    } on DioException catch (e) {
      setState(() {
        _confirmError = _parseError(e);
        _confirmLoading = false;
        _codeController.clear();
      });
    } catch (_) {
      setState(() {
        _confirmError = 'Code invalide. Réessayez.';
        _confirmLoading = false;
        _codeController.clear();
      });
    }
  }

  Future<void> _disableConfirm() async {
    final code = _disablePassController.text.trim();
    if (code.length != 6) {
      setState(() => _disableError = 'Entrez le code à 6 chiffres de votre authenticateur.');
      return;
    }
    setState(() {
      _disableLoading = true;
      _disableError = null;
    });
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/auth/2fa/disable', data: {'code': code});
      setState(() {
        _showDisable = false;
        _disablePassController.clear();
        _disableLoading = false;
      });
      widget.onChanged();
      if (mounted) _showSuccess(context, '2FA désactivée.');
    } on DioException catch (e) {
      setState(() {
        _disableError = _parseError(e);
        _disableLoading = false;
        _disablePassController.clear();
      });
    } catch (_) {
      setState(() {
        _disableError = 'Une erreur est survenue.';
        _disableLoading = false;
        _disablePassController.clear();
      });
    }
  }

  String _parseError(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final msg = data['message'];
      if (msg is String && msg.isNotEmpty) return msg;
    }
    return 'Une erreur est survenue.';
  }

  void _showSuccess(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.enabled
                      ? AppColors.success.withAlpha(20)
                      : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.enabled
                        ? AppColors.success.withAlpha(60)
                        : AppColors.border,
                  ),
                ),
                child: Icon(
                  widget.enabled
                      ? Icons.verified_user_rounded
                      : Icons.shield_outlined,
                  size: 20,
                  color: widget.enabled
                      ? AppColors.success
                      : AppColors.primaryLight,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Authentification à deux facteurs',
                      style: AppTextStyles.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.enabled ? 'Activée' : 'Désactivée',
                      style: AppTextStyles.caption.copyWith(
                        color: widget.enabled
                            ? AppColors.success
                            : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.enabled)
                _SmallButton(
                  label: 'Désactiver',
                  color: AppColors.error,
                  onTap: () => setState(() {
                    _showDisable = !_showDisable;
                    _disableError = null;
                    _disablePassController.clear();
                  }),
                )
              else if (_qrUrl == null)
                _SmallButton(
                  label: _loading ? '...' : 'Activer',
                  color: AppColors.primary,
                  onTap: _loading ? null : _startEnable,
                ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            _ErrorBanner(message: _error!),
          ],
          // ── Enable flow: QR + code ────────────────────────────────────────
          if (_qrUrl != null) ...[
            const SizedBox(height: 20),
            Container(
              height: 1,
              color: AppColors.divider,
            ),
            const SizedBox(height: 20),
            Text(
              'Scannez ce QR code avec Google Authenticator ou Authy, puis entrez le code affiché.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: _qrUrl!,
                  version: QrVersions.auto,
                  size: 180,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            if (_secret != null) ...[
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: _secret!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Clé secrète copiée'),
                      backgroundColor: AppColors.surfaceElevated,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _secret!,
                        style: AppTextStyles.caption.copyWith(
                          fontFamily: 'monospace',
                          color: AppColors.primaryLight,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.copy_rounded,
                        size: 14,
                        color: AppColors.textTertiary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            GlassTextField(
              controller: _codeController,
              label: 'Code de vérification',
              hint: '123456',
              prefixIcon: Icons.pin_outlined,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              maxLength: 6,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              onChanged: (v) {
                if (v.length == 6 && !_confirmLoading) _confirmEnable();
              },
            ),
            if (_confirmError != null) ...[
              const SizedBox(height: 8),
              _ErrorBanner(message: _confirmError!),
            ],
            const SizedBox(height: 14),
            _PrimaryButton(
              label: 'Confirmer l\'activation',
              loading: _confirmLoading,
              onTap: _confirmEnable,
            ),
            const SizedBox(height: 4),
            Center(
              child: TextButton(
                onPressed: () => setState(() {
                  _qrUrl = null;
                  _secret = null;
                  _codeController.clear();
                  _confirmError = null;
                }),
                child: Text(
                  'Annuler',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.textSecondary),
                ),
              ),
            ),
          ],
          // ── Disable flow: TOTP code ───────────────────────────────────────
          if (_showDisable) ...[
            const SizedBox(height: 20),
            Container(height: 1, color: AppColors.divider),
            const SizedBox(height: 20),
            Text(
              'Entrez le code affiché sur votre authenticateur pour désactiver la 2FA.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            GlassTextField(
              controller: _disablePassController,
              label: 'Code authenticateur',
              hint: '123456',
              prefixIcon: Icons.pin_outlined,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              onChanged: (v) {
                if (v.length == 6 && !_disableLoading) _disableConfirm();
              },
            ),
            if (_disableError != null) ...[
              const SizedBox(height: 8),
              _ErrorBanner(message: _disableError!),
            ],
            const SizedBox(height: 14),
            _DangerButton(
              label: 'Désactiver la 2FA',
              loading: _disableLoading,
              onTap: _disableConfirm,
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Change Password Card
// ─────────────────────────────────────────────────────────────────────────────

class _ChangePasswordCard extends ConsumerStatefulWidget {
  const _ChangePasswordCard();

  @override
  ConsumerState<_ChangePasswordCard> createState() =>
      _ChangePasswordCardState();
}

class _ChangePasswordCardState extends ConsumerState<_ChangePasswordCard> {
  bool _expanded = false;
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_currentCtrl.text.isEmpty ||
        _newCtrl.text.isEmpty ||
        _confirmCtrl.text.isEmpty) {
      setState(() => _error = 'Veuillez remplir tous les champs.');
      return;
    }
    if (_newCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'Les nouveaux mots de passe ne correspondent pas.');
      return;
    }
    if (_newCtrl.text.length < 8) {
      setState(() => _error = 'Le nouveau mot de passe doit contenir au moins 8 caractères.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dio = ref.read(dioProvider);
      await dio.put('/users/password', data: {
        'current_password': _currentCtrl.text,
        'password': _newCtrl.text,
        'password_confirmation': _confirmCtrl.text,
      });
      _currentCtrl.clear();
      _newCtrl.clear();
      _confirmCtrl.clear();
      setState(() {
        _loading = false;
        _expanded = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Mot de passe modifié avec succès !'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } on DioException catch (e) {
      setState(() {
        _error = _parseError(e);
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Une erreur est survenue.';
        _loading = false;
      });
    }
  }

  String _parseError(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final errors = data['errors'];
      if (errors is Map<String, dynamic> && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
      }
      final msg = data['message'];
      if (msg is String && msg.isNotEmpty) return msg;
    }
    return 'Une erreur est survenue.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() {
              _expanded = !_expanded;
              _error = null;
            }),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    size: 20,
                    color: AppColors.primaryLight,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Changer le mot de passe',
                        style: AppTextStyles.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Dernière mise à jour inconnue',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textTertiary,
                  size: 22,
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 20),
            Container(height: 1, color: AppColors.divider),
            const SizedBox(height: 20),
            GlassTextField(
              controller: _currentCtrl,
              label: 'Mot de passe actuel',
              hint: '••••••••',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: true,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            GlassTextField(
              controller: _newCtrl,
              label: 'Nouveau mot de passe',
              hint: '8 caractères minimum',
              prefixIcon: Icons.lock_reset_rounded,
              obscureText: true,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            GlassTextField(
              controller: _confirmCtrl,
              label: 'Confirmer le nouveau mot de passe',
              hint: '••••••••',
              prefixIcon: Icons.check_circle_outline_rounded,
              obscureText: true,
              textInputAction: TextInputAction.done,
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              _ErrorBanner(message: _error!),
            ],
            const SizedBox(height: 16),
            _PrimaryButton(
              label: 'Mettre à jour le mot de passe',
              loading: _loading,
              onTap: _submit,
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Delete Account Card
// ─────────────────────────────────────────────────────────────────────────────

class _DeleteAccountCard extends ConsumerStatefulWidget {
  const _DeleteAccountCard();

  @override
  ConsumerState<_DeleteAccountCard> createState() => _DeleteAccountCardState();
}

class _DeleteAccountCardState extends ConsumerState<_DeleteAccountCard> {
  bool _expanded = false;
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _passCtrl.dispose();
    super.dispose();
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: AppColors.overlay,
      builder: (_) => _ConfirmDeleteDialog(
        onConfirm: _doDelete,
      ),
    );
  }

  Future<void> _doDelete() async {
    if (_passCtrl.text.isEmpty) {
      setState(() => _error = 'Entrez votre mot de passe.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dio = ref.read(dioProvider);
      await dio.delete('/users/account',
          data: {'password': _passCtrl.text});
      await ref.read(tokenStorageProvider).deleteAll();
      notifyAuthChanged();
      if (mounted) context.go(AppRoutes.login);
    } on DioException catch (e) {
      final data = e.response?.data;
      String msg = 'Une erreur est survenue.';
      if (data is Map<String, dynamic>) {
        final m = data['message'];
        if (m is String && m.isNotEmpty) msg = m;
      }
      setState(() {
        _error = msg;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Une erreur est survenue.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.error.withAlpha(60)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() {
              _expanded = !_expanded;
              _error = null;
              _passCtrl.clear();
            }),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.error.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.error.withAlpha(50),
                    ),
                  ),
                  child: const Icon(
                    Icons.delete_forever_rounded,
                    size: 20,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Supprimer le compte',
                        style: AppTextStyles.titleSmall
                            .copyWith(color: AppColors.error),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Action irréversible',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.error.withAlpha(160)),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.error.withAlpha(180),
                  size: 22,
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 20),
            Container(height: 1, color: AppColors.error.withAlpha(40)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withAlpha(40)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.warning,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Toutes vos données seront définitivement supprimées. Cette action est irréversible.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassTextField(
              controller: _passCtrl,
              label: 'Confirmez avec votre mot de passe',
              hint: '••••••••',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: true,
              textInputAction: TextInputAction.done,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              _ErrorBanner(message: _error!),
            ],
            const SizedBox(height: 16),
            _DangerButton(
              label: 'Supprimer définitivement mon compte',
              loading: _loading,
              onTap: () => _confirmDelete(context),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Confirm delete dialog
// ─────────────────────────────────────────────────────────────────────────────

class _ConfirmDeleteDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  const _ConfirmDeleteDialog({required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.error.withAlpha(60)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(80),
              blurRadius: 40,
              spreadRadius: -8,
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
                color: AppColors.errorBg,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.error.withAlpha(60)),
              ),
              child: const Icon(
                Icons.delete_forever_rounded,
                color: AppColors.error,
                size: 28,
              ),
            ),
            const SizedBox(height: 20),
            Text('Supprimer le compte ?', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 10),
            Text(
              'Cette action est irréversible. Toutes vos données seront supprimées.',
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
                          color: AppColors.error.withAlpha(80),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Supprimer',
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
// Reusable small widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SmallButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _SmallButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          gradient: loading ? null : AppGradients.button,
          color: loading ? AppColors.surfaceElevated : null,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: AppTextStyles.buttonMedium
                      .copyWith(color: Colors.white),
                ),
        ),
      ),
    );
  }
}

class _DangerButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;

  const _DangerButton({
    required this.label,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.errorBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.error.withAlpha(loading ? 30 : 80),
          ),
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.error,
                  ),
                )
              : Text(
                  label,
                  style: AppTextStyles.buttonMedium
                      .copyWith(color: AppColors.error),
                ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(10),
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

class _ErrorRetry extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorRetry({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 36),
          const SizedBox(height: 12),
          Text(
            'Impossible de charger les données.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
    );
  }
}
