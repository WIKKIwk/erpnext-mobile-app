import 'dart:ui';

import '../bootstrap/device_permissions_bootstrap.dart';
import '../../localization/app_localizations.dart';
import '../../localization/locale_controller.dart';
import '../../widgets/forms/pin_pad.dart';
import '../state/security_controller.dart';
import 'package:flutter/material.dart';

class AppLockGate extends StatefulWidget {
  const AppLockGate({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DevicePermissionsBootstrap.instance.runOnce();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        SecurityController.instance,
        LocaleController.instance,
      ]),
      builder: (context, _) {
        final locked = SecurityController.instance.locked;
        final privacyShieldVisible =
            SecurityController.instance.privacyShieldVisible && !locked;

        return Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                ignoring: locked,
                child: widget.child,
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !privacyShieldVisible,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  reverseDuration: const Duration(milliseconds: 120),
                  child: privacyShieldVisible
                      ? const KeyedSubtree(
                          key: ValueKey<String>('privacy-shield'),
                          child: _PrivacyShieldOverlay(),
                        )
                      : const SizedBox.shrink(
                          key: ValueKey<String>('privacy-shield-empty'),
                        ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !locked,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 360),
                  reverseDuration: const Duration(milliseconds: 240),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(
                          begin: 0.985,
                          end: 1,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: locked
                      ? const KeyedSubtree(
                          key: ValueKey<String>('lock-overlay'),
                          child: _PinUnlockOverlay(),
                        )
                      : const SizedBox.shrink(
                          key: ValueKey<String>('lock-overlay-empty'),
                        ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PrivacyShieldOverlay extends StatelessWidget {
  const _PrivacyShieldOverlay();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: ColoredBox(
              color: scheme.surface.withValues(alpha: 0.30),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.18),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color:
                        scheme.surfaceContainerHighest.withValues(alpha: 0.30),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 14,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.primary.withValues(alpha: 0.88),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Accord',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: scheme.onPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
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
        ],
      ),
    );
  }
}

class _PinUnlockOverlay extends StatefulWidget {
  const _PinUnlockOverlay();

  @override
  State<_PinUnlockOverlay> createState() => _PinUnlockOverlayState();
}

class _PinUnlockOverlayState extends State<_PinUnlockOverlay> {
  final TextEditingController _pinController = TextEditingController();
  String? _error;
  bool _unlocking = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _resetPinField({String? error}) {
    _pinController.value = const TextEditingValue(
      text: '',
      selection: TextSelection.collapsed(offset: 0),
    );
    setState(() {
      _error = error;
    });
  }

  Future<void> _unlock() async {
    final l10n = context.l10n;
    setState(() {
      _unlocking = true;
      _error = null;
    });
    try {
      final ok = await SecurityController.instance
          .unlockWithPin(_pinController.text.trim());
      if (!ok && mounted) {
        _resetPinField(error: l10n.pinWrong);
      }
      if (ok) {
        _pinController.value = const TextEditingValue(
          text: '',
          selection: TextSelection.collapsed(offset: 0),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _unlocking = false;
        });
      }
    }
  }

  Future<void> _unlockWithBiometric() async {
    final l10n = context.l10n;
    setState(() {
      _unlocking = true;
      _error = null;
    });
    try {
      final ok = await SecurityController.instance.unlockWithBiometric();
      if (!ok && mounted) {
        setState(() {
          _error = l10n.biometricFailed;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _unlocking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surface,
            ),
          ),
          SafeArea(
            child: Align(
              alignment: const Alignment(0, 0.12),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.appLockTitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.appLockSubtitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 22),
                        PinCodeEditor(
                          controller: _pinController,
                          onAction: _unlock,
                          actionLabel: _unlocking ? l10n.checking : l10n.unlock,
                          actionIcon: Icons.arrow_forward_rounded,
                          errorText: _error,
                          busy: _unlocking,
                        ),
                        if (SecurityController
                            .instance.biometricEnabledForCurrentUser) ...[
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed:
                                  _unlocking ? null : _unlockWithBiometric,
                              child: Text(l10n.biometricCta),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
