import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_shell.dart';
import 'package:flutter/material.dart';

class PinEntryScaffold extends StatelessWidget {
  const PinEntryScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.length,
    required this.onDigit,
    required this.onBackspace,
    this.errorText,
  });

  final String title;
  final String subtitle;
  final int length;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      leading: AppShellIconAction(
        icon: Icons.arrow_back_rounded,
        onTap: () => Navigator.of(context).maybePop(),
      ),
      title: title,
      subtitle: subtitle,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(
                  4,
                  (index) => Container(
                    width: 18,
                    height: 18,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index < length
                          ? Theme.of(context).colorScheme.onSurface
                          : Colors.transparent,
                      border: Border.all(color: AppTheme.cardBorder(context)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (errorText != null && errorText!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Text(
                    errorText!,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              _PinPad(
                onDigit: onDigit,
                onBackspace: onBackspace,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinPad extends StatelessWidget {
  const _PinPad({
    required this.onDigit,
    required this.onBackspace,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    const rows = <List<String>>[
      <String>['1', '2', '3'],
      <String>['4', '5', '6'],
      <String>['7', '8', '9'],
    ];

    return Column(
      children: [
        for (final row in rows) ...[
          Row(
            children: row
                .map(
                  (value) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: _PinButton(
                        label: value,
                        onTap: () => onDigit(value),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
        Row(
          children: [
            const Expanded(child: SizedBox(height: 72)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: _PinButton(
                  label: '0',
                  onTap: () => onDigit('0'),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: _PinButton(
                  icon: Icons.backspace_outlined,
                  onTap: onBackspace,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PinButton extends StatelessWidget {
  const _PinButton({
    this.label,
    this.icon,
    required this.onTap,
  });

  final String? label;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: AppTheme.actionSurface(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.cardBorder(context)),
        ),
        alignment: Alignment.center,
        child: icon != null
            ? Icon(icon, color: Theme.of(context).colorScheme.onSurface)
            : Text(
                label ?? '',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
      ),
    );
  }
}
