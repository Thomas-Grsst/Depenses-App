import 'package:flutter/material.dart';

import 'format.dart';
import 'icons.dart';
import 'models.dart';
import 'screens/add_expense.dart';
import 'store.dart';
import 'theme.dart';
import 'ui.dart';

/// Ligne d'une dépense passée.
class ExpenseRow extends StatelessWidget {
  final Expense e;
  final String? meta;
  final double iconSize;
  final bool chips;
  const ExpenseRow(this.e, {super.key, this.meta, this.iconSize = 40, this.chips = false});

  @override
  Widget build(BuildContext context) {
    final t = TkScope.of(context);
    final cat = catOf(e.cat).name;
    final showChips = chips && !t.graphite && e.labels.isNotEmpty;
    return ItemRow(
      leading: CatIcon(cat: e.cat, name: e.name, size: t.graphite ? 38 : iconSize),
      title: e.name,
      titleSuffix: e.isRec ? const RecMark() : null,
      subtitle: meta ?? (chips && !t.graphite ? cat : [cat, if (e.labels.isNotEmpty) e.labels.join(', ')].join(' · ')),
      below: showChips
          ? Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(spacing: 4, runSpacing: 4, children: [
                for (final l in e.labels)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: t.chip, borderRadius: BorderRadius.circular(999)),
                    child: Text(l, style: t.ts(11, FontWeight.w700, t.muted)),
                  ),
              ]),
            )
          : null,
      trailing: e.roundUp > 0 ? null : eur(e.amount),
      trailingWidget: e.roundUp > 0
          ? Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(eur(e.amount), style: t.ts(15, t.graphite ? FontWeight.w400 : FontWeight.w700)),
                Text('+${eur(e.roundUp)} arrondi', style: t.ts(11, t.wSemi, t.mint)),
              ]),
            )
          : null,
      onTap: () => go(context, AddExpenseScreen(expense: e)),
    );
  }
}

/// Ligne d'une échéance à venir.
class OccRow extends StatelessWidget {
  final Occ o;
  final String style; // 'home' | 'list' | 'plain'
  const OccRow(this.o, {super.key, this.style = 'home'});

  @override
  Widget build(BuildContext context) {
    final t = TkScope.of(context);
    final store = StoreScope.of(context);
    void open() => go(context, AddExpenseScreen(rec: o.rec));
    if (t.graphite) {
      if (style == 'list') {
        return ItemRow(
          leading: SizedBox(
              width: 48,
              child: Text('${o.date.day.toString().padLeft(2, '0')}.${o.date.month.toString().padLeft(2, '0')}',
                  style: t.mono(12, t.muted))),
          title: o.rec.name,
          trailing: eur(o.rec.amount),
          onTap: open,
        );
      }
      return ItemRow(
        leading: CatIcon(cat: o.rec.cat, name: o.rec.name, size: 38),
        title: o.rec.name,
        subtitle: relDayLong(o.date, store.today),
        trailing: eur(o.rec.amount),
        onTap: open,
      );
    }
    if (style == 'list') {
      return ItemRow(
        leading: Row(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(width: 52, child: Text(shortDate(o.date), style: t.ts(13, FontWeight.w700, t.muted))),
          CatIcon(cat: o.rec.cat, name: o.rec.name, size: 32),
        ]),
        title: o.rec.name,
        trailing: eur(o.rec.amount),
        onTap: open,
      );
    }
    return ItemRow(
      leading: Row(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          width: 40,
          child: Column(children: [
            Text('${o.date.day}', style: t.ts(16, FontWeight.w700)),
            Text(monthsShort[o.date.month - 1], style: t.ts(11, FontWeight.w700, t.muted)),
          ]),
        ),
        const SizedBox(width: 12),
        CatIcon(cat: o.rec.cat, name: o.rec.name, size: 36),
      ]),
      title: o.rec.name,
      trailing: eur(o.rec.amount),
      onTap: open,
    );
  }
}

String relDayLong(DateTime d, DateTime today) {
  if (sameDay(d, today.add(const Duration(days: 1)))) return 'Demain';
  if (d.difference(today).inDays < 7) return '${cap(daysFr[d.weekday - 1])} ${d.day}';
  return '${d.day == 1 ? '1er' : d.day} ${monthsFr[d.month - 1]}';
}

String ruleText(Recurrence r) => switch (r.freq) {
      'week' => 'Chaque semaine · ${daysFr[r.start.weekday - 1]}',
      'year' => 'Chaque année · ${r.start.day == 1 ? '1er' : r.start.day} ${monthsFr[r.start.month - 1]}',
      _ => 'Tous les mois · le ${r.start.day}',
    };

/// Mouvements par catégorie (mois courant à date vs mois précédent à la même date).
class Move {
  final Cat cat;
  final double now, before;
  Move(this.cat, this.now, this.before);
  double get delta => now - before;
  double? get ratio => before > 0 ? now / before - 1 : null;
}

List<Move> moves(MonthStats s) => [
      for (final c in cats)
        if (s.perCat[c.key]!.spent > 0 || s.perCat[c.key]!.prevSame > 0)
          Move(c, s.perCat[c.key]!.spent, s.perCat[c.key]!.prevSame),
    ];

/// Ligne de réglage (lien, interrupteur, valeur).
class SettingRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool chevron;
  final Color? color;
  const SettingRow(this.label, {super.key, this.value, this.trailing, this.onTap, this.chevron = false, this.color});

  @override
  Widget build(BuildContext context) {
    final t = TkScope.of(context);
    return Pressable(
      onTap: onTap,
      child: SizedBox(
        height: t.graphite ? 56 : 52,
        child: Row(children: [
          Expanded(child: Text(label, style: t.ts(15, t.graphite ? FontWeight.w400 : FontWeight.w700, color))),
          if (value != null)
            Padding(
              padding: EdgeInsets.only(right: chevron ? 10 : 0),
              child: Text(value!, style: t.graphite ? t.mono(11, t.muted) : t.ts(15, FontWeight.w600, t.muted)),
            ),
          ?trailing,
          if (chevron) Ico('chevR', size: 18, color: t.muted),
        ]),
      ),
    );
  }
}

/// Groupe de réglages : carte avec séparateurs (Menthe) ou filets (Graphite).
class SettingGroup extends StatelessWidget {
  final List<Widget> rows;
  const SettingGroup(this.rows, {super.key});

  @override
  Widget build(BuildContext context) {
    final t = TkScope.of(context);
    final side = BorderSide(color: t.line);
    if (t.graphite) {
      return Column(children: [
        for (var i = 0; i < rows.length; i++)
          Container(
            decoration: BoxDecoration(border: Border(top: side, bottom: i == rows.length - 1 ? side : BorderSide.none)),
            child: rows[i],
          ),
      ]);
    }
    return Panel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(children: [
        for (var i = 0; i < rows.length; i++)
          Container(
            decoration: BoxDecoration(border: Border(bottom: i < rows.length - 1 ? side : BorderSide.none)),
            child: rows[i],
          ),
      ]),
    );
  }
}
