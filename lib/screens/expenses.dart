import 'package:flutter/material.dart';

import '../format.dart';
import '../icons.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../ui.dart';
import '../widgets.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});
  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  (int, int)? _month;
  String _filter = 'all';
  String? _cat;
  final _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _pickMonth(AppStore store) async {
    final months = store.monthsWithData();
    final r = await showSheet<(int, int)>(context,
        title: 'Choisir le mois',
        builder: (ctx) {
          final t = TkScope.of(ctx);
          return Column(children: [
            for (final m in months)
              Ruled(
                child: Pressable(
                  onTap: () => Navigator.pop(ctx, m),
                  child: SizedBox(
                    height: 40,
                    child: Row(children: [
                      Expanded(child: Text(monthYear(m.$1, m.$2), style: t.ts(16, t.wItem))),
                      Text(eur(store.inMonth(m.$1, m.$2).fold(0.0, (a, e) => a + e.amount)),
                          style: t.ts(14, t.wSemi, t.muted)),
                    ]),
                  ),
                ),
              ),
          ]);
        });
    if (r != null) setState(() => _month = r);
  }

  String _groupTitle(DateTime d, DateTime today, Tk t) {
    if (!t.graphite) return dayHeader(d, today);
    if (sameDay(d, today)) return 'AUJOURD’HUI';
    final base = '${d.day == 1 ? '1ER' : d.day} ${monthsShort[d.month - 1]}'.toUpperCase();
    if (sameDay(d, today.subtract(const Duration(days: 1)))) return 'HIER · $base';
    return '${daysShort[d.weekday - 1]} $base'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final t = TkScope.of(context);
    final store = StoreScope.of(context);
    final g = t.graphite;
    final month = _month ?? (store.today.year, store.today.month);
    final q = norm(_q.text);

    final all = store.inMonth(month.$1, month.$2);
    final list = all.where((e) {
      if (_filter == 'rec' && !e.isRec) return false;
      if (_filter == 'occ' && e.isRec) return false;
      if (_cat != null && e.cat != _cat) return false;
      if (q.isEmpty) return true;
      final hay = norm('${e.name} ${e.labels.join(' ')} ${catOf(e.cat).name} ${num2(e.amount)} ${e.amount}');
      return hay.contains(q);
    }).toList()
      ..sort((a, b) {
        final c = b.date.compareTo(a.date);
        return c != 0 ? c : b.id.compareTo(a.id);
      });
    final total = list.fold(0.0, (a, e) => a + e.amount);
    final n = list.length;
    final countWord = switch (_filter) {
      'rec' => n > 1 ? 'récurrentes' : 'récurrente',
      'occ' => n > 1 ? 'occasionnelles' : 'occasionnelle',
      _ => n > 1 ? 'dépenses' : 'dépense',
    };
    final countText = '$n $countWord';

    final groups = <DateTime, List<Expense>>{};
    for (final e in list) {
      groups.putIfAbsent(e.date, () => []).add(e);
    }

    final monthBtn = Pressable(
      onTap: () => _pickMonth(store),
      child: Container(
        height: g ? 44 : 40,
        padding: g ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 14),
        decoration: g ? null : BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(month.$1 == store.today.year && g ? cap(monthsFr[month.$2 - 1]) : monthYear(month.$1, month.$2),
              style: t.ts(g ? 15 : 14, g ? FontWeight.w400 : FontWeight.w700)),
          const SizedBox(width: 6),
          Ico('chevD', size: g ? 14 : 16, color: t.ink, stroke: g ? 1.6 : 2),
        ]),
      ),
    );

    final search = Container(
      height: g ? 44 : 48,
      padding: g ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 14),
      decoration: g
          ? BoxDecoration(border: Border(bottom: BorderSide(color: t.lineStrong)))
          : BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Ico('search', size: 18, color: t.muted),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _q,
            onChanged: (_) => setState(() {}),
            style: t.ts(15, t.wBody),
            decoration: InputDecoration.collapsed(
                hintText: g ? 'Rechercher un libellé, un montant…' : 'Libellé, montant, catégorie…',
                hintStyle: t.ts(15, t.wBody, t.faint)),
          ),
        ),
        if (_q.text.isNotEmpty)
          Pressable(
              onTap: () => setState(() => _q.clear()),
              child: Padding(padding: const EdgeInsets.all(6), child: Ico('close', size: 16, color: t.muted))),
      ]),
    );

    final tabs = Segmented<String>(
      options: const [('all', 'Toutes'), ('rec', 'Récurrentes'), ('occ', 'Occasionnelles')],
      value: _filter,
      onChanged: (v) => setState(() => _filter = v),
    );

    final catChips = SizedBox(
      height: g ? 40 : 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        children: spaced([
          for (final c in cats)
            Pressable(
              onTap: () => setState(() => _cat = _cat == c.key ? null : c.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.fromLTRB(5, 4, 12, 4),
                decoration: BoxDecoration(
                  color: g ? (_cat == c.key ? t.fab : Colors.transparent) : t.card,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                      color: g ? (_cat == c.key ? t.fab : t.lineStrong) : (_cat == c.key ? t.ink : Colors.transparent),
                      width: g ? 1 : 1.5),
                ),
                child: Row(children: [
                  g
                      ? Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Ico(c.kind, size: 16, color: _cat == c.key ? t.fabInk : t.ink))
                      : CatIcon(cat: c.key, size: 26),
                  const SizedBox(width: 8),
                  Text(c.name,
                      style: t.ts(13, g ? FontWeight.w400 : FontWeight.w600, g && _cat == c.key ? t.fabInk : t.ink)),
                ]),
              ),
            ),
        ], 8),
      ),
    );

    final totalBlock = g
        ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            BigAmount(total, size: 52),
            const SizedBox(height: 8),
            Text(countText.toUpperCase(), style: t.label()),
          ])
        : Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Expanded(child: Text(eur(total), style: t.ts(26, FontWeight.w800).copyWith(letterSpacing: -0.5))),
            Text(countText, style: t.ts(13, FontWeight.w600, t.muted)),
          ]);

    final groupWidgets = [
      for (final entry in groups.entries)
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 6),
            child: Text(_groupTitle(entry.key, store.today, t),
                style: g ? t.label() : t.ts(13, FontWeight.w700, t.muted)),
          ),
          Panel(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(children: [
              for (final e in entry.value) Ruled(padV: g ? 13 : 20, child: ExpenseRow(e, chips: true, iconSize: 42)),
            ]),
          ),
        ]),
    ];

    final empty = Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Text(
        all.isEmpty
            ? 'Aucune dépense en ${monthsFr[month.$2 - 1]}. Appuie sur + pour en ajouter une.'
            : 'Aucun résultat pour ces filtres.',
        textAlign: TextAlign.center,
        style: t.ts(14, t.wBody, t.muted),
      ),
    );

    if (g) {
      return PageList(gap: 26, children: [
        Row(children: [
          Expanded(child: Text('Dépenses', style: t.ts(15, FontWeight.w500))),
          monthBtn,
        ]),
        totalBlock,
        search,
        tabs,
        catChips,
        if (groupWidgets.isEmpty) empty,
        ...groupWidgets,
      ]);
    }
    return PageList(children: [
      Row(children: [
        Expanded(child: Text('Dépenses', style: t.ts(28, FontWeight.w800).copyWith(letterSpacing: -0.5))),
        monthBtn,
      ]),
      search,
      tabs,
      catChips,
      totalBlock,
      if (groupWidgets.isEmpty) empty,
      ...groupWidgets,
    ]);
  }
}
