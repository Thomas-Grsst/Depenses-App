import 'package:flutter/material.dart';

import '../format.dart';
import '../icons.dart';
import '../store.dart';
import '../theme.dart';
import '../ui.dart';
import '../widgets.dart';
import 'add_expense.dart';

class RecurrencesScreen extends StatefulWidget {
  const RecurrencesScreen({super.key});
  @override
  State<RecurrencesScreen> createState() => _RecurrencesScreenState();
}

class _RecurrencesScreenState extends State<RecurrencesScreen> {
  String _view = 'list';
  late DateTime _month;
  late DateTime _sel;

  @override
  void initState() {
    super.initState();
    final now = dOnly(DateTime.now());
    _month = DateTime(now.year, now.month);
    _sel = now;
  }

  @override
  Widget build(BuildContext context) {
    final t = TkScope.of(context);
    final g = t.graphite;
    final store = StoreScope.of(context);
    final views = Segmented<String>(
      options: const [('list', 'Liste'), ('cal', 'Calendrier')],
      value: _view,
      onChanged: (v) => setState(() => _view = v),
    );
    final head = g
        ? Row(children: [Expanded(child: Text('Récurrences', style: t.ts(15, FontWeight.w500))), views])
        : Text('Récurrences', style: t.ts(28, FontWeight.w800).copyWith(letterSpacing: -0.5));
    final body = _view == 'list' ? _list(context, store, t) : _calendar(context, store, t);
    return PageList(gap: g ? 28 : 14, children: [head, if (!g) views, ...body]);
  }

  List<Widget> _list(BuildContext context, AppStore store, Tk t) {
    final g = t.graphite;
    final s = store.stats;
    final sugg = store.suggestions;
    final next = store.nextOccurrences(5);
    final all = [...store.recs]..sort((a, b) => b.monthly.compareTo(a.monthly));

    Widget suggestion(Suggestion sg) {
      final text = [
        (g ? '' : '', false),
        ('${sg.name} · ${eur(sg.amount)}', !g),
        (' revient chaque mois depuis ${sg.months} mois. ${g ? 'En faire une récurrence ?' : 'Créer comme dépense récurrente ?'}', false),
      ];
      final buttons = Row(children: [
        SmallButton('Créer', primary: true, onTap: () {
          store.acceptSuggestion(sg);
          toast(context, 'Récurrence créée');
        }),
        const SizedBox(width: 8),
        SmallButton('Ignorer', onTap: () => store.ignoreSuggestion(sg)),
      ]);
      final icon = CatIcon(cat: sg.cat, name: sg.name, size: g ? 38 : 32, dashed: true);
      final content = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          icon,
          SizedBox(width: g ? 14 : 10),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                for (final p in text)
                  TextSpan(text: p.$1, style: p.$2 ? const TextStyle(fontWeight: FontWeight.w800) : null),
              ]),
              style: t.ts(14, t.wBody, g ? t.body : t.ink).copyWith(height: 1.45),
            ),
          ),
        ]),
        Padding(padding: EdgeInsets.only(left: g ? 52 : 42, top: 10), child: buttons),
      ]);
      if (g) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(border: Border.symmetric(horizontal: BorderSide(color: t.line))),
          child: content,
        );
      }
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(color: t.mintSoft, borderRadius: BorderRadius.circular(18)),
        child: content,
      );
    }

    if (store.recs.isEmpty) {
      return [
        if (sugg.isNotEmpty) suggestion(sugg.first),
        Panel(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Aucune récurrence', style: t.ts(17, t.wStrong)),
            const SizedBox(height: 6),
            Text(
                'Loyer, électricité, abonnements, salle de sport… Ajoute-les une fois : elles seront comptées automatiquement chaque mois et intégrées aux prévisions.',
                style: t.ts(14, t.wBody, t.muted).copyWith(height: 1.45)),
            const SizedBox(height: 16),
            PrimaryButton('Ajouter une récurrence', onTap: () => go(context, const AddExpenseScreen(startRecurring: true))),
          ]),
        ),
      ];
    }

    return [
      TwoUp(
        KeyFigure(g ? 'Fixe / mois' : 'Charges fixes / mois', store.fixedMonthly, hero: true),
        KeyFigure(g ? 'Reste à sortir' : 'Encore à sortir en ${monthsShort[s.m - 1]}', s.remainingRecTotal),
      ),
      if (sugg.isNotEmpty) suggestion(sugg.first),
      ListSection(
        title: 'Prochaines échéances',
        empty: 'Rien de prévu.',
        children: [for (final o in next) OccRow(o, style: 'list')],
      ),
      ListSection(
        title: g ? 'Toutes' : 'Toutes les récurrences',
        action: '+ Ajouter',
        onAction: () => go(context, const AddExpenseScreen(startRecurring: true)),
        children: [
          for (final r in all)
            ItemRow(
              leading: CatIcon(cat: r.cat, name: r.name, size: g ? 38 : 42),
              title: r.name,
              subtitle: ruleText(r),
              trailing: eur(r.amount),
              onTap: () => go(context, AddExpenseScreen(rec: r)),
            ),
        ],
      ),
    ];
  }

  List<Widget> _calendar(BuildContext context, AppStore store, Tk t) {
    final g = t.graphite;
    final today = store.today;
    final y = _month.year, m = _month.month;
    final dim = daysInMonth(y, m);
    final lead = DateTime(y, m, 1).weekday - 1;

    // Dépenses réelles + échéances prévues (après aujourd'hui)
    final byDay = <int, List<(String, String, double, bool)>>{}; // nom, cat, montant, prévu
    for (final e in store.inMonth(y, m)) {
      byDay.putIfAbsent(e.date.day, () => []).add((e.name, e.cat, e.amount, false));
    }
    final monthEnd = DateTime(y, m, dim);
    final from = DateTime(y, m, 1).isAfter(today) ? DateTime(y, m, 1) : today.add(const Duration(days: 1));
    final planned = monthEnd.isBefore(from) ? <Occ>[] : store.upcoming(from, monthEnd);
    for (final o in planned) {
      byDay.putIfAbsent(o.date.day, () => []).add((o.rec.name, o.rec.cat, o.rec.amount, true));
    }
    final plannedTotal = planned.fold(0.0, (a, o) => a + o.rec.amount);

    final selInMonth = _sel.year == y && _sel.month == m;
    final items = selInMonth ? (byDay[_sel.day] ?? []) : <(String, String, double, bool)>[];

    Widget cell(int d) {
      final date = DateTime(y, m, d);
      final on = selInMonth && _sel.day == d;
      final isToday = sameDay(date, today);
      final past = date.isBefore(today);
      final ev = byDay[d] ?? [];
      if (g) {
        return Pressable(
          onTap: () => setState(() => _sel = date),
          child: SizedBox(
            height: 46,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on ? t.fab : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: isToday && !on ? t.fab : Colors.transparent),
                ),
                child: Text('$d', style: t.ts(14, FontWeight.w400, on ? t.fabInk : (past ? t.muted : t.ink))),
              ),
              const SizedBox(height: 4),
              Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                      color: ev.isEmpty ? Colors.transparent : (past ? t.faint : t.ink), shape: BoxShape.circle)),
            ]),
          ),
        );
      }
      return Pressable(
        onTap: () => setState(() => _sel = date),
        child: Container(
          height: 48,
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: on ? t.ink : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isToday && !on ? t.mint : Colors.transparent, width: 2),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('$d',
                style: t.ts(14, on || isToday ? FontWeight.w800 : FontWeight.w600, on ? t.bg : (past ? t.faint : t.ink))),
            const SizedBox(height: 3),
            SizedBox(
              height: 6,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (final e in ev.take(3))
                  Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(color: t.cat(e.$2), shape: BoxShape.circle)),
              ]),
            ),
          ]),
        ),
      );
    }

    final rows = <Widget>[];
    final total = lead + dim;
    for (var r = 0; r < (total / 7).ceil(); r++) {
      rows.add(Row(children: [
        for (var c = 0; c < 7; c++)
          Expanded(
            child: () {
              final idx = r * 7 + c - lead + 1;
              return idx < 1 || idx > dim ? SizedBox(height: g ? 46 : 48) : cell(idx);
            }(),
          ),
      ]));
    }

    void shift(int k) => setState(() => _month = DateTime(y, m + k));
    Widget navBtn(String icon, int k) => Pressable(
          onTap: () => shift(k),
          semantics: k < 0 ? 'Mois précédent' : 'Mois suivant',
          child: Container(
            width: g ? 44 : 40,
            height: g ? 44 : 40,
            alignment: g ? (k < 0 ? Alignment.centerLeft : Alignment.centerRight) : Alignment.center,
            decoration: g ? null : BoxDecoration(color: t.chip, shape: BoxShape.circle),
            child: Ico(icon, size: g ? 20 : 18, color: g ? t.muted : t.ink, stroke: g ? 1.4 : 2),
          ),
        );

    final dayNames = g ? ['LUN', 'MAR', 'MER', 'JEU', 'VEN', 'SAM', 'DIM'] : ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    final calendar = Panel(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      radius: 22,
      child: Column(children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: g ? 0 : 4),
          child: Row(children: [
            navBtn('chevL', -1),
            Expanded(
              child: Text(
                y == today.year ? cap(monthsFr[m - 1]) + (g ? '' : ' $y') : monthYear(y, m),
                textAlign: TextAlign.center,
                style: g ? t.ts(30, FontWeight.w300).copyWith(letterSpacing: -0.6) : t.ts(17, FontWeight.w800),
              ),
            ),
            navBtn('chevR', 1),
          ]),
        ),
        SizedBox(height: g ? 20 : 10),
        Row(children: [
          for (final n in dayNames)
            Expanded(
                child: Text(n,
                    textAlign: TextAlign.center,
                    style: g ? t.mono(10, t.faint) : t.ts(12, FontWeight.w700, t.muted))),
        ]),
        SizedBox(height: g ? 10 : 6),
        ...rows,
      ]),
    );

    final selDate = selInMonth ? _sel : null;
    final tag = selDate == null
        ? ''
        : sameDay(selDate, today)
            ? 'Aujourd’hui'
            : selDate.isBefore(today)
                ? 'Payé'
                : 'Prévu';
    final selTitle = selDate == null
        ? 'Choisis un jour'
        : g
            ? '${daysFr[selDate.weekday - 1]} ${selDate.day}'.toUpperCase()
            : '${cap(daysFr[selDate.weekday - 1])} ${selDate.day} ${monthsFr[selDate.month - 1]}';

    final dayList = g
        ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                Expanded(child: Text(selTitle, style: t.label())),
                Text(tag.toUpperCase(), style: t.label()),
              ]),
            ),
            if (items.isEmpty)
              Ruled(child: Text('Rien ce jour-là.', style: t.ts(14, FontWeight.w400, t.muted))),
            for (final it in items)
              Ruled(
                child: ItemRow(
                  leading: CatIcon(cat: it.$2, name: it.$1, size: 38),
                  title: it.$1,
                  titleSuffix: it.$4 ? const RecMark() : null,
                  trailing: eur(it.$3),
                ),
              ),
          ])
        : Panel(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Expanded(child: Text(selTitle, style: t.ts(15, FontWeight.w800))),
                if (tag.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                        color: tag == 'Payé' ? t.chip : t.mintSoft, borderRadius: BorderRadius.circular(999)),
                    child: Text(tag, style: t.ts(12, FontWeight.w700, tag == 'Payé' ? t.muted : t.mint)),
                  ),
              ]),
              const SizedBox(height: 4),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 10, 0, 12),
                  child: Text('Aucune dépense ce jour-là.', style: t.ts(14, FontWeight.w500, t.muted)),
                ),
              for (final it in items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: ItemRow(
                    leading: CatIcon(cat: it.$2, name: it.$1, size: 36),
                    title: it.$1,
                    titleSuffix: it.$4 ? const RecMark() : null,
                    trailing: eur(it.$3),
                  ),
                ),
            ]),
          );

    final remaining = g
        ? Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(border: Border.symmetric(horizontal: BorderSide(color: t.line))),
            child: Row(children: [
              Expanded(child: Text('Encore à sortir ce mois', style: t.ts(14, FontWeight.w400, t.muted))),
              Text(eur(plannedTotal), style: t.ts(14, FontWeight.w400)),
            ]),
          )
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: t.mintSoft, borderRadius: BorderRadius.circular(18)),
            child: Row(children: [
              Expanded(child: Text('Encore à sortir ce mois', style: t.ts(14, FontWeight.w700))),
              Text(eur(plannedTotal), style: t.ts(14, FontWeight.w700)),
            ]),
          );

    final showRemaining = !monthEnd.isBefore(today);
    return [calendar, dayList, if (showRemaining) remaining];
  }
}
