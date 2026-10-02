import 'dart:math';

import 'package:flutter/material.dart';

import '../format.dart';
import '../icons.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../ui.dart';
import 'simulation.dart';

class SimulationsScreen extends StatefulWidget {
  const SimulationsScreen({super.key});
  @override
  State<SimulationsScreen> createState() => _SimulationsScreenState();
}

class _Col {
  final String letter, title;
  final double delta;
  _Col(this.letter, this.title, this.delta);
}

class _SimulationsScreenState extends State<SimulationsScreen> {
  final List<String> _sel = [];
  bool _init = false;

  String _letter(int i) => i < 26 ? String.fromCharCode(65 + i) : '${i + 1}';

  Future<void> _options(Scenario sim) async {
    final store = StoreScope.read(context);
    final r = await showSheet<String>(context,
        title: sim.title,
        builder: (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              PrimaryButton('Ouvrir dans le bac à sable', onTap: () => Navigator.pop(ctx, 'open')),
              const SizedBox(height: 10),
              SecondaryButton('Supprimer', color: TkScope.of(ctx).warn, onTap: () => Navigator.pop(ctx, 'delete')),
            ]));
    if (!mounted) return;
    if (r == 'open') {
      go(context, SimulationScreen(from: sim));
    } else if (r == 'delete' && await confirm(context, 'Supprimer « ${sim.title} » ?', 'Cette simulation sera effacée.')) {
      _sel.remove(sim.id);
      store.sims.remove(sim);
      store.commit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = TkScope.of(context);
    final g = t.graphite;
    final store = StoreScope.of(context);
    final sims = store.sims;
    if (!_init) {
      _init = true;
      _sel.addAll(sims.reversed.take(2).map((s) => s.id).toList().reversed);
    }
    _sel.removeWhere((id) => !sims.any((s) => s.id == id));

    final income = store.settings.income;
    final fix = store.fixedMonthly;
    final goal = store.goals.isEmpty ? null : store.goals.first;

    void toggle(String id) => setState(() {
          if (_sel.contains(id)) {
            _sel.remove(id);
          } else {
            _sel.add(id);
            if (_sel.length > 2) _sel.removeAt(0);
          }
        });

    final header = g
        ? Row(children: [
            RoundButton('chevL', semantics: 'Retour', onTap: () => Navigator.pop(context)),
            Expanded(child: Text('Mes simulations', textAlign: TextAlign.center, style: t.ts(15, FontWeight.w500))),
            Pressable(
              onTap: () => go(context, const SimulationScreen()),
              semantics: 'Nouvelle simulation',
              child: SizedBox(width: 44, height: 44, child: Align(alignment: Alignment.centerRight, child: Ico('plus', size: 22))),
            ),
          ])
        : BackHeader('Mes simulations',
            subtitle: 'Choisis-en jusqu’à 2 à comparer',
            trailing: RoundButton('plus', filled: true, semantics: 'Nouvelle simulation', onTap: () => go(context, const SimulationScreen())));

    Widget simItem(int i, Scenario sim) {
      final on = _sel.contains(sim.id);
      final d = sim.delta;
      final worse = d > 0.004;
      final impact = '${signed(d, eur)} / mois';
      final meta = 'Enregistrée le ${shortDate(sim.createdAt)}';
      final check = Container(
        width: g ? 22 : 26,
        height: g ? 22 : 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: on ? t.fab : Colors.transparent,
          border: Border.all(color: on ? t.fab : (g ? t.lineStrong : t.off), width: g ? 1 : 2),
        ),
        child: on ? Ico('check', size: 14, color: t.fabInk, stroke: 2.4) : null,
      );
      final mainHyp = sim.hyps.isEmpty ? null : sim.hyps.first;
      if (g) {
        return Ruled(
          padV: 16,
          child: Pressable(
            onTap: () => toggle(sim.id),
            onLongPress: () => _options(sim),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(padding: const EdgeInsets.only(top: 1), child: check),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                    Expanded(child: Text('${_letter(i)} · ${sim.title}', style: t.ts(15, FontWeight.w400))),
                    const SizedBox(width: 10),
                    Text(signed(d, eur), style: t.ts(14, FontWeight.w400, worse ? t.warn : t.mint)),
                  ]),
                  if (sim.desc.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(sim.desc, style: t.ts(13, FontWeight.w400, t.muted).copyWith(height: 1.45)),
                  ],
                  const SizedBox(height: 6),
                  Text('${sim.hyps.map(hypSummary).join(' · ')} · $meta'.toUpperCase(), style: t.mono(10, t.faint)),
                ]),
              ),
            ]),
          ),
        );
      }
      return Pressable(
        onTap: () => toggle(sim.id),
        onLongPress: () => _options(sim),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: on ? t.ink : Colors.transparent, width: 2),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CatIcon(cat: mainHyp?.cat ?? 'aut', name: mainHyp?.name, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${_letter(i)} · ${sim.title}', style: t.ts(15, FontWeight.w800)),
                  Text(meta, style: t.ts(12, FontWeight.w600, t.muted)),
                ]),
              ),
              check,
            ]),
            if (sim.desc.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(sim.desc, style: t.ts(13, FontWeight.w500, t.muted).copyWith(height: 1.45)),
            ],
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final h in sim.hyps)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(color: t.chip, borderRadius: BorderRadius.circular(999)),
                  child: Text(hypSummary(h), style: t.ts(12, FontWeight.w700)),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: worse ? t.warnSoft : t.mintSoft, borderRadius: BorderRadius.circular(999)),
                child: Text(impact, style: t.ts(12, FontWeight.w800, worse ? t.warn : t.mint)),
              ),
            ]),
          ]),
        ),
      );
    }

    final cols = [
      _Col('Actuel', 'Situation réelle', 0),
      for (var i = 0; i < sims.length; i++)
        if (_sel.contains(sims[i].id)) _Col(_letter(i), sims[i].title, sims[i].delta),
    ];

    (String, List<(String, bool)>) metric(String label, double Function(_Col) get, String Function(double) fmt, bool low) {
      final vals = cols.map(get).toList();
      final best = low ? vals.reduce(min) : vals.reduce(max);
      final distinct = vals.toSet().length > 1;
      return (label, [for (final v in vals) (fmt(v), distinct && v == best)]);
    }

    final rows = [
      metric('Impact par mois', (c) => c.delta, (v) => v.abs() < 0.005 ? '—' : signed(v, eur), true),
      metric('Sur un an', (c) => c.delta * 12, (v) => v.abs() < 0.005 ? '—' : signed(v, eur0), true),
      metric('Charges fixes / mois', (c) => fix + c.delta, eur, true),
      if (income > 0) metric('Reste à vivre / mois', (c) => income - fix - c.delta, eur, false),
      if (goal != null)
        metric('${goal.name} atteint en', (c) => (goal.monthsWith(max(0, goal.monthly - c.delta)) ?? 9999).toDouble(),
            (v) => v >= 9999 ? 'jamais' : (v == 0 ? 'atteint' : monthAfter(v.round())), true),
    ];

    final picked = [for (var i = 0; i < sims.length; i++) if (_sel.contains(sims[i].id)) (_letter(i), sims[i])];
    var insight = 'Sélectionne une simulation pour la comparer à ta situation réelle.';
    if (picked.length == 1) {
      insight = '${picked[0].$1} change ton reste à vivre de ${signed(-picked[0].$2.delta, eur0)} par mois.';
    } else if (picked.length == 2) {
      final (la, a) = picked[0];
      final (lb, b) = picked[1];
      final diff = (a.delta - b.delta).abs();
      final cheaper = a.delta <= b.delta ? la : lb;
      final other = cheaper == la ? lb : la;
      insight = diff < 0.005
          ? '$la et $lb ont le même impact sur ton budget.'
          : '$cheaper coûte ${eur(diff)} de moins par mois que $other, soit ${eur0(diff * 12)} sur un an.';
    }

    final table = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (!g) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('Comparaison', style: t.ts(15, FontWeight.w800))),
      Container(
        padding: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: g ? t.lineStrong : t.line))),
        child: Row(children: spaced([
          for (final c in cols)
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.letter, style: t.ts(g ? 15 : 13, g ? FontWeight.w400 : FontWeight.w800)),
                Text(c.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.ts(11, t.wSemi, t.muted)),
              ]),
            ),
        ], 8)),
      ),
      for (final r in rows)
        Container(
          padding: EdgeInsets.symmetric(vertical: g ? 12 : 10),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: t.line))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(g ? r.$1.toUpperCase() : r.$1, style: g ? t.mono(10, t.faint) : t.ts(12, FontWeight.w700, t.muted)),
            const SizedBox(height: 6),
            Row(children: spaced([
              for (final c in r.$2)
                Expanded(
                  child: Text(c.$1,
                      style: t.ts(14, c.$2 ? (g ? FontWeight.w500 : FontWeight.w800) : (g ? FontWeight.w400 : FontWeight.w600),
                          c.$2 ? t.mint : t.ink)),
                ),
            ], 8)),
          ]),
        ),
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: g
            ? Text(insight, style: t.ts(16, FontWeight.w300, t.body).copyWith(height: 1.5))
            : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Ico('bulb', size: 18, color: t.mint),
                const SizedBox(width: 10),
                Expanded(child: Text(insight, style: t.ts(13, FontWeight.w500).copyWith(height: 1.45))),
              ]),
      ),
    ]);

    return Scaffold(
      backgroundColor: t.bg,
      body: PageList(children: [
        header,
        if (sims.isEmpty)
          Panel(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('Aucune simulation enregistrée', style: t.ts(17, t.wStrong)),
              const SizedBox(height: 6),
              Text('Teste un changement (loyer, abonnement, nouvelle charge) puis enregistre-le pour le comparer à d’autres.',
                  style: t.ts(14, t.wBody, t.muted).copyWith(height: 1.45)),
              const SizedBox(height: 16),
              PrimaryButton('Nouvelle simulation', onTap: () => go(context, const SimulationScreen())),
            ]),
          )
        else ...[
          if (g)
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('CHOISIS-EN 2 À COMPARER', style: t.label())),
              for (var i = 0; i < sims.length; i++) simItem(i, sims[i]),
            ])
          else
            ...[for (var i = 0; i < sims.length; i++) simItem(i, sims[i])],
          Panel(radius: 22, child: table),
          Text('Appui long sur une simulation pour l’ouvrir ou la supprimer.\nLes simulations ne modifient jamais ton budget.',
              textAlign: TextAlign.center, style: t.ts(12, t.wSemi, g ? t.faint : t.muted).copyWith(height: 1.5)),
        ],
      ]),
    );
  }
}
