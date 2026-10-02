import 'package:flutter/material.dart';

import '../charts.dart';
import '../format.dart';
import '../store.dart';
import '../theme.dart';
import '../ui.dart';

class ForecastScreen extends StatelessWidget {
  const ForecastScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = TkScope.of(context);
    final g = t.graphite;
    final store = StoreScope.of(context);
    final s = store.stats;
    final more = s.forecast - s.spent;
    final prevName = monthsFr[DateTime(s.y, s.m - 1).month - 1];

    // "Sport ×2 · Électricité"
    final counts = <String, int>{};
    for (final o in s.remainingRec) {
      counts[o.rec.name] = (counts[o.rec.name] ?? 0) + 1;
    }
    final recSummary = counts.isEmpty
        ? 'Aucune d’ici la fin du mois'
        : counts.entries.map((e) => e.value > 1 ? '${e.key} ×${e.value}' : e.key).join(' · ');

    final tipParts = <(String, bool)>[
      (g ? 'Au rythme actuel, environ ' : 'En continuant au même rythme, tu devrais dépenser environ ', false),
      (eur0(more), true),
      (' de plus d’ici le ${s.dim}', false),
      if (s.budget > 0) ...[
        (g ? ' — tu finirais ' : ' — et finir ', false),
        (s.forecast <= s.budget
            ? '${eur0(s.budget - s.forecast)} sous ton budget'
            : '${eur0(s.forecast - s.budget)} au-dessus de ton budget', true),
      ],
      ('.', false),
    ];
    final over = s.budget > 0 && s.forecast > s.budget;

    final legend = Wrap(spacing: g ? 18 : 14, runSpacing: 6, children: [
      _Legend('Réel', g ? t.ink : t.mint, solid: true),
      _Legend('Estimé', g ? t.muted : t.mint),
      if (s.prevFull > 0) _Legend(cap(prevName), t.ghost, solid: true),
      if (s.budget > 0 && !g) _Legend('Budget', t.warn),
    ]);

    final chart = Panel(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ForecastChart(s),
        SizedBox(height: g ? 14 : 10),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: legend),
      ]),
    );

    final tip = g
        ? Text.rich(
            TextSpan(children: [
              for (final p in tipParts)
                TextSpan(
                    text: p.$1,
                    style: p.$2
                        ? TextStyle(
                            color: p.$1.contains('sous') ? t.mint : (p.$1.contains('au-dessus') ? t.warn : t.ink),
                            fontWeight: FontWeight.w400)
                        : null),
            ]),
            style: t.ts(17, FontWeight.w300, t.body).copyWith(height: 1.5),
          )
        : Callout(parts: tipParts, warn: over, icon: over ? 'alert' : 'bulb');

    final rest = ListSection(
      title: 'Ce qui reste à venir',
      closed: true,
      children: [
        ItemRow(title: 'Récurrences prévues', subtitle: recSummary, trailing: eur(s.remainingRecTotal)),
        ItemRow(
          title: 'Dépenses courantes estimées',
          subtitle: '≈ ${eur0(s.rate)}${g ? ' / ' : '/'}jour × ${s.remainingDays} jour${s.remainingDays > 1 ? 's' : ''}',
          trailing: eur(s.estOcc),
        ),
        for (final p in store.payDates(store.today.add(const Duration(days: 1)), DateTime(s.y, s.m, s.dim)))
          ItemRow(title: 'Salaire', subtitle: longDate(p), trailing: '+${eur(store.settings.income)}'),
        if (store.hasBalance)
          ItemRow(
            title: 'Solde estimé au ${s.dim}',
            subtitle: 'Aujourd’hui : ${eur(store.balance)}',
            trailing: eur(store.balanceEndOfMonth),
          ),
      ],
    );

    const basis = ['Rythme quotidien', 'Récurrences restantes', 'Historique 3 mois', 'Jour du mois', 'Tendances par catégorie'];
    final basisW = g
        ? Text('CALCUL : ${basis.join(' · ').toUpperCase()}', style: t.mono(10, t.faint).copyWith(height: 1.8))
        : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SectionLabel('Calcul basé sur'),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final b in basis)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(999)),
                  child: Text(b, style: t.ts(12, FontWeight.w700)),
                ),
            ]),
          ]);

    return Scaffold(
      backgroundColor: t.bg,
      body: PageList(children: [
        BackHeader(g ? 'Prévision · ${cap(monthsFr[s.m - 1])}' : 'Prévision · ${monthsFr[s.m - 1]}'),
        TwoUp(
          KeyFigure(g ? 'Au ${s.day}' : 'Dépensé au ${s.day}', s.spent, decimals: false),
          KeyFigure(g ? 'Prévu au ${s.dim}' : 'Prévision au ${s.dim}', s.forecast, hero: true, decimals: false),
        ),
        chart,
        tip,
        rest,
        basisW,
      ]),
    );
  }
}

class _Legend extends StatelessWidget {
  final String label;
  final Color color;
  final bool solid;
  const _Legend(this.label, this.color, {this.solid = false});

  @override
  Widget build(BuildContext context) {
    final t = TkScope.of(context);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        width: 16,
        height: 3,
        child: solid
            ? Container(color: color)
            : Row(children: [
                for (var i = 0; i < 3; i++) ...[
                  Expanded(child: Container(color: color)),
                  if (i < 2) const SizedBox(width: 2),
                ],
              ]),
      ),
      const SizedBox(width: 6),
      Text(t.graphite ? label.toUpperCase() : label,
          style: t.graphite ? t.mono(10, t.muted) : t.ts(12, FontWeight.w600, t.muted)),
    ]);
  }
}
