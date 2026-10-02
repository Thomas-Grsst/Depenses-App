import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'format.dart';
import 'icons.dart';
import 'theme.dart';

Tk tk(BuildContext c) => TkScope.of(c);

List<Widget> spaced(Iterable<Widget> ws, double gap) {
  final out = <Widget>[];
  for (final w in ws) {
    if (out.isNotEmpty) out.add(SizedBox(height: gap, width: gap));
    out.add(w);
  }
  return out;
}

Future<T?> go<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => page));

/// Zone cliquable avec un léger retour visuel.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? semantics;
  const Pressable({super.key, required this.child, this.onTap, this.onLongPress, this.semantics});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null && widget.onLongPress == null) return widget.child;
    return Semantics(
      button: true,
      label: widget.semantics,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                widget.onTap!();
              },
        onLongPress: widget.onLongPress,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 90),
          opacity: _down ? 0.6 : 1,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Page défilante avec les marges du style courant.
class PageList extends StatelessWidget {
  final List<Widget> children;
  final double? gap;
  final double bottom;
  const PageList({super.key, required this.children, this.gap, this.bottom = 32});

  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(t.pad, t.graphite ? 14 : 12, t.pad, bottom),
        children: spaced(children, gap ?? (t.graphite ? 28 : 14)),
      ),
    );
  }
}

/// Carte (Menthe) ou bloc nu (Graphite).
class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;
  final double radius;
  final bool forceCard;
  const Panel({super.key, required this.child, this.padding, this.color, this.radius = 20, this.forceCard = false});

  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    if (t.graphite && !forceCard) return child;
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color ?? t.card, borderRadius: BorderRadius.circular(radius)),
      child: child,
    );
  }
}

/// Filet supérieur (Graphite uniquement).
class Ruled extends StatelessWidget {
  final Widget child;
  final bool bottom;
  final double padV;
  const Ruled({super.key, required this.child, this.bottom = false, this.padV = 14});

  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    if (!t.graphite) return Padding(padding: EdgeInsets.symmetric(vertical: padV * 0.55), child: child);
    final side = BorderSide(color: t.line);
    return Container(
      padding: EdgeInsets.symmetric(vertical: padV),
      decoration: BoxDecoration(border: Border(top: side, bottom: bottom ? side : BorderSide.none)),
      child: child,
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionLabel(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(children: [
        Expanded(child: Text(t.graphite ? text.toUpperCase() : text, style: t.label())),
        ?trailing,
      ]),
    );
  }
}

/// Lien texte discret ("Tout voir", "+ Nouveau"…)
class TextLink extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const TextLink(this.text, {super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(text,
            style: t.graphite ? t.ts(13, FontWeight.w400, t.muted) : t.ts(13, FontWeight.w700, t.mint)),
      ),
    );
  }
}

/// Liste titrée : carte avec titre (Menthe) ou étiquette + filets (Graphite).
class ListSection extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final List<Widget> children;
  final String? empty;
  final bool closed;
  const ListSection(
      {super.key, required this.title, this.action, this.onAction, required this.children, this.empty, this.closed = false});

  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    final rows = children.isEmpty && empty != null
        ? [EmptyRow(empty!)]
        : children;
    final head = Row(children: [
      Expanded(
          child: t.graphite
              ? Text(title.toUpperCase(), style: t.label())
              : Text(title, style: t.ts(15, FontWeight.w800))),
      if (action != null && onAction != null) TextLink(action!, onTap: onAction!),
    ]);
    if (t.graphite) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(padding: const EdgeInsets.only(bottom: 6), child: head),
        for (var i = 0; i < rows.length; i++) Ruled(bottom: closed && i == rows.length - 1, child: rows[i]),
      ]);
    }
    return Panel(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(padding: const EdgeInsets.only(bottom: 4), child: head),
        for (final r in rows) Ruled(child: r),
      ]),
    );
  }
}

class EmptyRow extends StatelessWidget {
  final String text;
  const EmptyRow(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(text, style: t.ts(14, t.wBody, t.muted)),
    );
  }
}

/// Ligne standard : icône, titre / sous-titre, montant.
class ItemRow extends StatelessWidget {
  final Widget? leading;
  final String title;
  final Widget? titleSuffix;
  final String? subtitle;
  final Widget? below;
  final String? trailing;
  final Widget? trailingWidget;
  final VoidCallback? onTap;
  const ItemRow(
      {super.key,
      this.leading,
      required this.title,
      this.titleSuffix,
      this.subtitle,
      this.below,
      this.trailing,
      this.trailingWidget,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    return Pressable(
      onTap: onTap,
      child: Row(children: [
        if (leading != null) ...[leading!, SizedBox(width: t.graphite ? 14 : 12)],
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(
                  child: Text(title,
                      overflow: TextOverflow.ellipsis,
                      style: t.ts(15, t.graphite ? FontWeight.w400 : FontWeight.w600))),
              if (titleSuffix != null) ...[const SizedBox(width: 6), titleSuffix!],
            ]),
            if (subtitle != null && subtitle!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(subtitle!,
                    overflow: TextOverflow.ellipsis, style: t.ts(12, t.wSemi, t.muted)),
              ),
            ?below,
          ]),
        ),
        if (trailing != null)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(trailing!, style: t.ts(15, t.graphite ? FontWeight.w400 : FontWeight.w700)),
          ),
        ?trailingWidget,
      ]),
    );
  }
}

/// Grand montant : "1 308,12 €" (Menthe) ou "1 308,12" + "€" grisé (Graphite).
class BigAmount extends StatelessWidget {
  final double value;
  final double size;
  final bool decimals;
  final Color? color;
  final String? suffix;
  const BigAmount(this.value, {super.key, this.size = 40, this.decimals = true, this.color, this.suffix});

  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    final n = decimals ? num2(value) : num0(value);
    final c = color ?? t.ink;
    if (t.graphite) {
      return Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(n,
                style: t.ts(size, FontWeight.w300, c).copyWith(letterSpacing: -size * 0.04, height: 1)),
          ),
        ),
        const SizedBox(width: 8),
        Text(suffix ?? '€', style: t.ts(size * 0.36, FontWeight.w300, t.muted)),
      ]);
    }
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text.rich(
        TextSpan(children: [
          TextSpan(text: '$n$nbsp€'),
          if (suffix != null) TextSpan(text: ' $suffix', style: t.ts(size * 0.45, FontWeight.w700, t.heroMuted)),
        ]),
        style: t.ts(size, FontWeight.w800, c).copyWith(letterSpacing: -size * 0.02, height: 1.1),
      ),
    );
  }
}

/// Sélecteur segmenté (pilule en Menthe, onglets soulignés en rouge en Graphite).
class Segmented<T> extends StatelessWidget {
  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;
  final bool center;
  const Segmented({super.key, required this.options, required this.value, required this.onChanged, this.center = false});

  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    if (t.graphite) {
      return Row(
        mainAxisAlignment: center ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: spaced([
          for (final o in options)
            Pressable(
              onTap: () => onChanged(o.$1),
              child: Container(
                constraints: const BoxConstraints(minHeight: 40),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: o.$1 == value ? t.accent : Colors.transparent))),
                child: Text(o.$2, style: t.ts(14, FontWeight.w400, o.$1 == value ? t.ink : t.muted)),
              ),
            ),
        ], center ? 28 : 22),
      );
    }
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: t.chip, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        for (final o in options)
          Expanded(
            child: Pressable(
              onTap: () => onChanged(o.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: o.$1 == value ? t.card : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: o.$1 == value
                      ? [BoxShadow(color: const Color(0x1F0D2B24), blurRadius: 3, offset: const Offset(0, 1))]
                      : null,
                ),
                child: Text(o.$2,
                    style: t.ts(14, o.$1 == value ? FontWeight.w800 : FontWeight.w600, o.$1 == value ? t.ink : t.muted)),
              ),
            ),
          ),
      ]),
    );
  }
}

/// Pastille sélectionnable (libellés, fréquences…)
class PillChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool dashed;
  final bool expand;
  final double height;
  const PillChip(this.label,
      {super.key, this.selected = false, this.onTap, this.dashed = false, this.expand = false, this.height = 36});

  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    final Color bg, fg, border;
    if (t.graphite) {
      bg = selected ? t.fab : Colors.transparent;
      fg = selected ? t.fabInk : (dashed ? t.muted : t.ink);
      border = selected ? t.fab : t.lineStrong;
    } else {
      bg = dashed ? Colors.transparent : (selected ? t.mintSoft : t.card);
      fg = selected ? t.mint : t.muted;
      border = dashed ? t.muted : Colors.transparent;
    }
    final w = Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: expand ? Alignment.center : null,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(t.graphite ? height / 2 : 999),
        border: Border.all(color: border, width: dashed && !t.graphite ? 1.5 : 1),
      ),
      child: Align(widthFactor: expand ? null : 1, child: Text(!t.graphite && selected && !dashed ? '✓ $label' : label,
          style: t.ts(13, t.graphite ? FontWeight.w400 : FontWeight.w700, fg))),
    );
    return Pressable(onTap: onTap, child: w);
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final String? icon;
  const PrimaryButton(this.label, {super.key, this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    final enabled = onTap != null;
    return Pressable(
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration:
              BoxDecoration(color: t.fab, borderRadius: BorderRadius.circular(t.graphite ? 28 : 18)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Ico(icon!, size: 18, color: t.fabInk, stroke: 2), const SizedBox(width: 8)],
            Text(label, style: t.ts(t.graphite ? 15 : 16, t.graphite ? FontWeight.w500 : FontWeight.w800, t.fabInk)),
          ]),
        ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  const SecondaryButton(this.label, {super.key, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: t.graphite ? Colors.transparent : t.card,
          borderRadius: BorderRadius.circular(t.graphite ? 28 : 18),
          border: t.graphite ? Border.all(color: t.lineStrong) : null,
        ),
        child: Text(label, style: t.ts(15, t.graphite ? FontWeight.w400 : FontWeight.w700, color ?? t.ink)),
      ),
    );
  }
}

/// Bouton en pointillés "+ Ajouter…"
class DashedButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const DashedButton(this.label, {super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    if (t.graphite) {
      return Pressable(
        onTap: onTap,
        child: SizedBox(
            height: 48,
            child: Align(alignment: Alignment.centerLeft, child: Text(label, style: t.ts(14, FontWeight.w400, t.muted)))),
      );
    }
    return Pressable(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedRRect(t.muted, 16),
        child: Container(
            height: 48, alignment: Alignment.center, child: Text(label, style: t.ts(14, FontWeight.w700))),
      ),
    );
  }
}

class _DashedRRect extends CustomPainter {
  final Color color;
  final double radius;
  _DashedRRect(this.color, this.radius);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)).deflate(0.75));
    for (final m in path.computeMetrics()) {
      for (double d = 0; d < m.length; d += 9) {
        canvas.drawPath(m.extractPath(d, d + 5), p);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRect old) => old.color != color;
}

class Toggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const Toggle({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    final g = t.graphite;
    final w = g ? 48.0 : 52.0, h = g ? 28.0 : 32.0, k = g ? 20.0 : 26.0;
    final Color bg = g ? (value ? t.fab : Colors.transparent) : (value ? t.mintFill : t.off);
    final Color knob = g ? (value ? Colors.white : t.faint) : Colors.white;
    return Semantics(
      toggled: value,
      child: Pressable(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: w,
          height: h,
          padding: const EdgeInsets.all(3),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(h / 2),
            border: g ? Border.all(color: value ? t.fab : t.lineStrong) : null,
          ),
          child: Container(
            width: k,
            height: k,
            decoration: BoxDecoration(
              color: knob,
              shape: BoxShape.circle,
              boxShadow: g ? null : const [BoxShadow(color: Color(0x40000000), blurRadius: 3, offset: Offset(0, 1))],
            ),
          ),
        ),
      ),
    );
  }
}

/// Barre de progression (avec repère optionnel, ex. projection fin de mois).
class Bar extends StatelessWidget {
  final double value; // 0..1
  final double? marker; // 0..1
  final Color? fill, track, markerColor;
  final double height;
  final bool dot;
  const Bar(this.value,
      {super.key, this.marker, this.fill, this.track, this.markerColor, this.height = 8, this.dot = false});

  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    final h = t.graphite ? 1.0 : height;
    final v = value.clamp(0.0, 1.0);
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      return SizedBox(
        height: t.graphite ? 9 : height + 6,
        child: Stack(clipBehavior: Clip.none, alignment: Alignment.centerLeft, children: [
          Container(
              height: h,
              decoration:
                  BoxDecoration(color: track ?? t.track, borderRadius: BorderRadius.circular(h / 2))),
          AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              width: w * v,
              height: h,
              decoration: BoxDecoration(
                  color: fill ?? (t.graphite ? t.ink : t.mintFill), borderRadius: BorderRadius.circular(h / 2))),
          if (marker != null)
            Positioned(
              left: (w * marker!.clamp(0.0, 0.99)) - 1,
              child: Container(
                  width: t.graphite ? 1 : 2,
                  height: t.graphite ? 9 : height + 6,
                  decoration: BoxDecoration(
                      color: markerColor ?? (t.graphite ? t.muted : t.ink), borderRadius: BorderRadius.circular(1))),
            ),
          if (dot && t.graphite)
            Positioned(
              left: w * v - 3.5,
              child: Container(
                  width: 7, height: 7, decoration: BoxDecoration(color: t.accent, shape: BoxShape.circle)),
            ),
        ]),
      );
    });
  }
}

/// Encadré d'alerte ou de conseil.
class Callout extends StatelessWidget {
  final String icon; // 'alert' | 'bulb'
  final List<(String, bool)> parts;
  final bool warn;
  final Widget? footer;
  const Callout({super.key, required this.parts, this.icon = 'bulb', this.warn = false, this.footer});

  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    final rich = Text.rich(TextSpan(children: [
      for (final p in parts)
        TextSpan(
            text: p.$1,
            style: p.$2
                ? TextStyle(
                    fontWeight: t.graphite ? FontWeight.w400 : FontWeight.w800,
                    color: t.graphite ? t.ink : null)
                : null),
    ]), style: t.ts(t.graphite ? 15 : 14, t.wBody, t.graphite ? t.body : t.ink).copyWith(height: 1.45));
    if (t.graphite) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, right: 12),
            child: Container(
                width: 6, height: 6, decoration: BoxDecoration(color: warn ? t.accent : t.mint, shape: BoxShape.circle)),
          ),
          Expanded(child: rich),
        ]),
        if (footer != null) Padding(padding: const EdgeInsets.only(left: 18, top: 10), child: footer),
      ]);
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(color: warn ? t.warnSoft : t.mintSoft, borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
              padding: const EdgeInsets.only(top: 1, right: 12),
              child: Ico(icon, size: 20, color: warn ? t.warn : t.mint)),
          Expanded(child: rich),
        ]),
        if (footer != null) Padding(padding: const EdgeInsets.only(left: 32, top: 10), child: footer),
      ]),
    );
  }
}

/// Bouton rond (retour, fermer…)
class RoundButton extends StatelessWidget {
  final String icon;
  final VoidCallback onTap;
  final String? semantics;
  final bool filled;
  const RoundButton(this.icon, {super.key, required this.onTap, this.semantics, this.filled = false});

  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    return Pressable(
      onTap: onTap,
      semantics: semantics,
      child: Container(
        width: 44,
        height: 44,
        alignment: t.graphite && !filled ? Alignment.centerLeft : Alignment.center,
        decoration: t.graphite && !filled
            ? null
            : BoxDecoration(color: filled ? t.fab : t.card, shape: BoxShape.circle),
        child: Ico(icon, size: t.graphite ? 22 : 20, color: filled ? t.fabInk : t.ink, stroke: t.graphite ? 1.4 : 2),
      ),
    );
  }
}

/// En-tête d'une page secondaire (retour + titre).
class BackHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final String icon;
  const BackHeader(this.title, {super.key, this.subtitle, this.trailing, this.icon = 'chevL'});

  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    final back = RoundButton(icon, semantics: 'Retour', onTap: () => Navigator.of(context).maybePop());
    if (t.graphite) {
      return Row(children: [
        back,
        Expanded(
          child: Column(children: [
            Text(title, textAlign: TextAlign.center, style: t.ts(15, FontWeight.w500)),
            if (subtitle != null) Text(subtitle!.toUpperCase(), style: t.mono(10, t.muted)),
          ]),
        ),
        SizedBox(width: 44, child: Align(alignment: Alignment.centerRight, child: trailing)),
      ]);
    }
    return Row(children: [
      back,
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: t.ts(24, FontWeight.w800).copyWith(letterSpacing: -0.5)),
          if (subtitle != null) Text(subtitle!, style: t.ts(12, FontWeight.w600, t.muted)),
        ]),
      ),
      ?trailing,
    ]);
  }
}

/// Petit bouton texte arrondi (Menthe) ou texte gris (Graphite).
class SmallButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool primary;
  const SmallButton(this.label, {super.key, required this.onTap, this.primary = false});

  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    final Color bg = t.graphite
        ? (primary ? t.fab : Colors.transparent)
        : (primary ? t.mint : t.card);
    final Color fg = t.graphite ? (primary ? t.fabInk : t.ink) : (primary ? t.onMint : t.ink);
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            border: t.graphite && !primary ? Border.all(color: t.lineStrong) : null),
        child: Text(label, style: t.ts(13, t.graphite ? FontWeight.w500 : FontWeight.w800, fg)),
      ),
    );
  }
}

/// Champ de saisie pour les feuilles de dialogue.
class Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool number;
  final int lines;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  const Field(this.label,
      {super.key, required this.controller, this.hint, this.number = false, this.lines = 1, this.autofocus = false, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    final input = TextField(
      controller: controller,
      autofocus: autofocus,
      minLines: lines,
      maxLines: lines,
      onChanged: onChanged,
      textCapitalization: number ? TextCapitalization.none : TextCapitalization.sentences,
      keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      style: t.ts(lines > 1 ? 14 : (t.graphite ? 17 : 15), t.graphite ? FontWeight.w400 : FontWeight.w700,
          lines > 1 && t.graphite ? t.body : t.ink),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: t.ts(15, FontWeight.w400, t.faint),
        filled: !t.graphite,
        fillColor: t.bg,
        contentPadding: t.graphite ? const EdgeInsets.symmetric(vertical: 10) : const EdgeInsets.all(14),
        enabledBorder: t.graphite
            ? UnderlineInputBorder(borderSide: BorderSide(color: t.lineStrong))
            : OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: t.off, width: 1.5)),
        focusedBorder: t.graphite
            ? UnderlineInputBorder(borderSide: BorderSide(color: t.ink))
            : OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: t.mint, width: 1.5)),
      ),
    );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(t.graphite ? label.toUpperCase() : label, style: t.label()),
      SizedBox(height: t.graphite ? 4 : 6),
      input,
    ]);
  }
}

/// Feuille modale du bas, au style courant.
Future<T?> showSheet<T>(BuildContext context, {required String title, required Widget Function(BuildContext) builder}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: tk(context).graphite ? const Color(0xB3000000) : const Color(0x80040C09),
    builder: (ctx) {
      final t = tk(context);
      return TkScope(
        tk: t,
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.88),
            decoration: BoxDecoration(
              color: t.sheet,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: t.graphite ? Border(top: BorderSide(color: t.lineStrong)) : null,
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(t.pad, 12, t.pad, 24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
                  Center(
                    child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(color: t.graphite ? t.lineStrong : t.off, borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: Text(title, style: t.ts(18, t.graphite ? FontWeight.w500 : FontWeight.w800))),
                    Pressable(
                      onTap: () => Navigator.of(ctx).pop(),
                      semantics: 'Fermer',
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: t.graphite ? Alignment.centerRight : Alignment.center,
                        decoration: t.graphite ? null : BoxDecoration(color: t.chip, shape: BoxShape.circle),
                        child: Ico('close', size: 18, color: t.ink),
                      ),
                    ),
                  ]),
                  SizedBox(height: t.graphite ? 18 : 14),
                  builder(ctx),
                ]),
              ),
            ),
          ),
        ),
      );
    },
  );
}

Future<bool> confirm(BuildContext context, String title, String message, {String ok = 'Supprimer'}) async {
  final t = tk(context);
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: t.sheet,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(t.graphite ? 16 : 24)),
      title: Text(title, style: t.ts(18, t.graphite ? FontWeight.w500 : FontWeight.w800)),
      content: Text(message, style: t.ts(14, t.wBody, t.muted)),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false), child: Text('Annuler', style: t.ts(14, FontWeight.w600, t.muted))),
        TextButton(
            onPressed: () => Navigator.pop(ctx, true), child: Text(ok, style: t.ts(14, FontWeight.w700, t.warn))),
      ],
    ),
  );
  return r ?? false;
}

void toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
}

/// Petit indicateur de récurrence (↻)
class RecMark extends StatelessWidget {
  const RecMark({super.key});
  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    return Ico('repeat', size: t.graphite ? 12 : 14, color: t.graphite ? t.muted : t.mint, stroke: 2);
  }
}

/// Chiffre-clé : étiquette + montant (cartes en Menthe, nu en Graphite).
class KeyFigure extends StatelessWidget {
  final String label;
  final double value;
  final bool hero;
  final bool decimals;
  const KeyFigure(this.label, this.value, {super.key, this.hero = false, this.decimals = true});

  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    if (t.graphite) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(), style: t.label()),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(decimals ? num2(value) : num0(value),
              style: t.ts(34, FontWeight.w300).copyWith(letterSpacing: -1.2, height: 1)),
        ),
      ]);
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: hero ? t.hero : t.card, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: t.ts(13, FontWeight.w600, hero ? t.heroMuted : t.muted)),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(decimals ? eur(value) : eur0(value), style: t.ts(22, FontWeight.w800, hero ? t.heroInk : t.ink)),
        ),
      ]),
    );
  }
}

class TwoUp extends StatelessWidget {
  final Widget a, b;
  const TwoUp(this.a, this.b, {super.key});
  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(child: a),
        SizedBox(width: t.graphite ? 16 : 12),
        Expanded(child: b),
      ]),
    );
  }
}
