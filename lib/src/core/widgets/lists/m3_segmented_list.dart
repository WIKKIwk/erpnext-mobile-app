import 'package:flutter/material.dart';

/// Vertikal **segmentlangan ro‘yxat** guruhi uchun pozitsiya: tepa / o‘rta / past.
///
/// Shakl: tepa segmentda faqat **yuqori** yumaloqlar, o‘rtada **to‘rt tomon**,
/// pastda faqat **pastki** yumaloqlar. Ketma-ket segmentlar orasida **gap** qoladi
/// (birlashtirib yubormaydi).
enum M3SegmentVerticalSlot {
  top,
  middle,
  bottom,
}

/// MD3 **contained list** — bo‘shliq va to‘ldirilgan elementlar guruhani aniqlaydi.
///
/// «Use gaps for contained lists» / «Use segmented gaps and filled list items».
/// Manba: [m3.material.io/components/lists/guidelines](https://m3.material.io/components/lists/guidelines)
///
/// Bu `M3SegmentFilledSurface` va qo‘lda qurilgan `Column` + gap bilan
/// bir xil vizual tilni boshqa ekranlarda qayta ishlatish uchun **geometriya SDK** sifatida
/// ajratilgan.
abstract final class M3SegmentedListGeometry {
  M3SegmentedListGeometry._();

  /// Ketma-ket segmentlar orasidagi vertikal bo‘shliq (px).
  static const double gap = 2;

  /// Tashqi (yuqori/pastki) segmentlar uchun asosiy radius.
  static const double cornerLarge = 18;

  /// O‘rta segmentlar uchun ixcham radius.
  static const double cornerMiddle = 6;

  /// Tashqi radius bilan **mos** qo‘shiluvchi mikro‑yumaloqlik: tepa segmentning
  /// pastki va keyingi segmentning yuqori burchaklari shu radius bilan «yumshoq» tutashadi.
  static const Radius joinMicro = Radius.circular(6);

  /// [cornerRadius] — segment slotiga mos [BorderRadius] (asosan [cornerLarge] yoki [cornerMiddle]).
  static BorderRadius borderRadius(
    M3SegmentVerticalSlot slot,
    double cornerRadius,
  ) {
    final Radius r = Radius.circular(cornerRadius);
    switch (slot) {
      case M3SegmentVerticalSlot.top:
        return BorderRadius.only(
          topLeft: r,
          topRight: r,
          bottomLeft: joinMicro,
          bottomRight: joinMicro,
        );
      case M3SegmentVerticalSlot.middle:
        return BorderRadius.all(r);
      case M3SegmentVerticalSlot.bottom:
        return BorderRadius.only(
          topLeft: joinMicro,
          topRight: joinMicro,
          bottomLeft: r,
          bottomRight: r,
        );
    }
  }

  /// [slot] bo‘yicha qaysi nominal radius ishlatilishini qaytaradi.
  static double cornerRadiusForSlot(
    M3SegmentVerticalSlot slot, {
    double large = cornerLarge,
    double middle = cornerMiddle,
  }) {
    switch (slot) {
      case M3SegmentVerticalSlot.middle:
        return middle;
      case M3SegmentVerticalSlot.top:
      case M3SegmentVerticalSlot.bottom:
        return large;
    }
  }

  /// Sarlavha ([M3SegmentVerticalSlot.top]) dan keyin keladigan **tana** qatorlari
  /// uchun slot: bitta qator bo‘lsa faqat [bottom]; aks holda birinchi [middle], oxirgi [bottom].
  static M3SegmentVerticalSlot bodySlotForIndex(int index, int bodyCount) {
    assert(bodyCount >= 1);
    if (bodyCount == 1) {
      return M3SegmentVerticalSlot.bottom;
    }
    if (index == 0) {
      return M3SegmentVerticalSlot.middle;
    }
    if (index == bodyCount - 1) {
      return M3SegmentVerticalSlot.bottom;
    }
    return M3SegmentVerticalSlot.middle;
  }

  /// AppBar ostidagi **to‘liq** segmentlangan ro‘yxat (yuqorida alohida [top] titul **yo‘q**).
  ///
  /// Bitta qator: [top] (yuqori katta radius); bir nechta: birinchi [top], o‘rtalar [middle], oxirgi [bottom].
  static M3SegmentVerticalSlot standaloneListSlotForIndex(
      int index, int count) {
    assert(count >= 1);
    if (count == 1) {
      return M3SegmentVerticalSlot.top;
    }
    if (index == 0) {
      return M3SegmentVerticalSlot.top;
    }
    if (index == count - 1) {
      return M3SegmentVerticalSlot.bottom;
    }
    return M3SegmentVerticalSlot.middle;
  }
}

/// MD3 contained list elementi: faqat **to‘ldirilgan fon** (chegara chizig‘i yo‘q), ixtiyoriy bosilish.
///
/// **Qorong‘i temada** kontent odatda asosiy [ColorScheme.surface]ga yaqin — shuning uchun
/// [surfaceContainerLow] (yuqori zinapoyadan pastroq). **Yorug‘ temada** konteynerlar
/// odatda [surface]dan to‘qroq — [surfaceContainerHighest] ishlatiladi.
class M3SegmentFilledSurface extends StatelessWidget {
  const M3SegmentFilledSurface({
    super.key,
    required this.slot,
    required this.cornerRadius,
    required this.child,
    this.onTap,
    this.backgroundColor,
    this.borderRadiusOverride,
  });

  final M3SegmentVerticalSlot slot;
  final double cornerRadius;
  final Widget child;
  final VoidCallback? onTap;

  /// `null` — standart [surfaceContainerLow] / [surfaceContainerHighest].
  final Color? backgroundColor;
  final BorderRadius? borderRadiusOverride;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final BorderRadius radius = borderRadiusOverride ??
        M3SegmentedListGeometry.borderRadius(slot, cornerRadius);
    final Color bg = backgroundColor ??
        switch (brightness) {
          Brightness.dark => scheme.surfaceContainerLow,
          Brightness.light => scheme.surfaceContainerHighest,
        };

    final Widget ink = Ink(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
      ),
      child: child,
    );

    return Material(
      color: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: radius),
      clipBehavior: Clip.antiAlias,
      child: onTap != null
          ? InkWell(onTap: onTap, borderRadius: radius, child: ink)
          : ink,
    );
  }
}

/// Bir nechta [children] orasiga [M3SegmentedListGeometry.gap] qo‘yilgan [Column].
///
/// Faqat **vizual spacing**; har bir child o‘z slot shaklini o‘zi beradi.
class M3SegmentSpacedColumn extends StatelessWidget {
  const M3SegmentSpacedColumn({
    super.key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.padding,
  });

  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }
    final spaced = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        spaced.add(const SizedBox(height: M3SegmentedListGeometry.gap));
      }
      spaced.add(children[i]);
    }
    final column = Column(
      crossAxisAlignment: crossAxisAlignment,
      children: spaced,
    );
    if (padding != null) {
      return Padding(padding: padding!, child: column);
    }
    return column;
  }
}
