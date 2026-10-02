import 'dart:math';

import 'package:flutter/material.dart';

import '../format.dart';
import '../icons.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../ui.dart';
import '../widgets.dart';
import 'simulations.dart';

/// "janvier" (ou "janvier 2028" si l'année change), n mois après le mois courant.
String monthAfter(int n) {
  final now = DateTime.now();
  final d = DateTime(now.year, now.month + n);
  return d.year == now.year || n <= 6 ? monthsFr[d.month - 1] : '${monthsFr[d.month - 1]} ${d.year}';
}

String goalWhen(int? months) => months == null
    ? 'jamais à ce rythme'
    : months == 0
        ? 'atteint'
        : 'atteint en ${monthAfter(months)}';

String hypSummary(Hyp h) {
  if (h.isNew) return '+ ${h.name} ${eurAuto(h.newAmount)}';
  if (!h.keep) return 'Sans ${h.name}';
  return '${h.name} ${eurAuto(h.newAmount)}';
}

/// Bac à sable : ne modifie jamais le budget ni les récurrences.
class SimulationScreen extends StatefulWidget {
  final Scenario? from;
  const SimulationScreen({super.key, this.from});
  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  late List<Hyp> _hyps;

  @override
  void initState() {
    super.initState();
    _hyps = [for (final h in widget.from?.hyps ?? <Hyp>[]) h.copy()];
  }

  double get _delta => _hyps.fold(0.0, (a, h) => a + h.delta);

  Future<void> _addHyp() async {
    final store = StoreScope.read(context);
    final used = _hyps.map((h) => h.recId).whereType<String>().toSet();
    final res = await showSheet<Object>(context,
        title: 'Ajouter une hypothèse',
        builder: (ctx) {
          final t = TkScope.of(ctx);
          final recs = store.recs.where((r) => !used.contains(r.id)).toList()
            ..sort((a, b) => b.monthly.compareTo(a.monthly));
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (recs.isNotEmpty) ...[
              SectionLabel('Modifier ou couper une charge'),
              const SizedBox(height: 6),
              for (final r in recs)
                Ruled(
                  child: ItemRow(
                    leading: CatIcon(cat: r.cat, name: r.name, size: 36),
                    title: r.name,
                    subtitle: ruleText(r),
                    trailing: eur(r.amount),
                    onTap: () => Navigator.pop(ctx, r),
                  ),
                ),
              const SizedBox(height: 18),
            ],
            if (recs.isEmpty && store.recs.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text('Ajoute tes charges récurrentes (loyer, abonnements…) pour pouvoir les simuler.',
                    style: t.ts(13, t.wBody, t.muted)),
              ),
            SecondaryButton('+ Nouvelle charge mensuelle', onTap: () => Navigator.pop(ctx, 'new')),
          ]);
        });
    if (!mounted || res == null) return;
    if (res is Recurrence) {
      setState(() => _hyps.add(Hyp(
          recId: res.id, name: res.name, cat: res.cat, freq: res.freq, oldAmount: res.amount, newAmount: res.amount)));
    } else if (res == 'new') {
      final name = TextEditingController();
      final amount = TextEditingController();
      final ok = await showSheet<bool>(context,
          title: 'Nouvelle charge',
          builder: (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Field('Nom', controller: name, hint: 'Ex. Crèche, Crédit auto…', autofocus: true),
                const SizedBox(height: 16),
                Field('Montant par mois', controller: amount, hint: 'Ex. 300', number: true),
                const SizedBox(height: 20),
                PrimaryButton('Ajouter', onTap: () => Navigator.pop(ctx, true)),
              ]));
      final a = parseAmount(amount.text);
      if (ok == true && a != null && a > 0 && mounted) {
        final n = name.text.trim().isEmpty ? 'Nouvelle charge' : name.text.trim();
        setState(() => _hyps.add(Hyp(name: n, cat: guessCat(n) ?? 'aut', freq: 'month', oldAmount: 0, newAmount: a)));
      }
    }
  }

  Future<void> _save() async {
    final store = StoreScope.read(context);
    final title = TextEditingController(text: widget.from?.title ?? _hyps.map(hypSummary).join(', '));
    final desc = TextEditingController(text: widget.from?.desc ?? '');
    final delta = _delta;
    final ok = await showSheet<bool>(context,
        title: 'Enregistrer la simulation',
        builder: (ctx) {
          final t = TkScope.of(ctx);
          final g = t.graphite;
          final tags = [..._hyps.map(hypSummary), 'Impact ${signed(delta, eur)} / mois'];
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Field('Titre', controller: title, autofocus: true),
            SizedBox(height: g ? 22 : 14),
            Field('Description', controller: desc, lines: 3, hint: 'Ce que tu envisages, pourquoi…'),
            SizedBox(height: g ? 22 : 14),
            g
                ? Text(tags.join(' · ').toUpperCase(), style: t.mono(11, t.muted))
                : Wrap(spacing: 6, runSpacing: 6, children: [
                    for (final tg in tags)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: t.chip, borderRadius: BorderRadius.circular(999)),
                        child: Text(tg, style: t.ts(12, FontWeight.w700)),
                      ),
                  ]),
            SizedBox(height: g ? 22 : 14),
            PrimaryButton('Enregistrer et comparer', onTap: () => Navigator.pop(ctx, true)),
            const SizedBox(height: 10),
            Text('Ton budget reste inchangé.', textAlign: TextAlign.center, style: t.ts(12, t.wSemi, g ? t.faint : t.muted)),
          ]);
        });
    if (ok != true || !mounted) return;
    store.sims.add(Scenario(
      id: newId(),
      title: title.text.trim().isEmpty ? 'Simulation ${store.sims.length + 1}' : title.text.trim(),
      desc: desc.text.trim(),
      createdAt: store.today,
      hyps: [for (final h in _hyps) h.copy()],
    ));
    store.commit();
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SimulationsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final t = TkScope.of(context);
    final g = t.graphite;
    final store = StoreScope.of(context);
    final s = store.stats;
    final delta = _delta;
    final income = store.settings.income;
    final fix = store.fixedMonthly;

    final header = g
        ? Row(children: [
            RoundButton('chevL', semantics: 'Retour', onTap: () => Navigator.pop(context)),
            Expanded(
              child: Column(children: [
                Text('Simulation', style: t.ts(15, FontWeight.w500)),
                Text('BAC À SABLE', style: t.mono(10, t.muted)),
              ]),
            ),
            Pressable(
                onTap: () => setState(() => _hyps.clear()),
                child: SizedBox(
                    width: 44,
                    child: Text('Réinit.', textAlign: TextAlign.right, style: t.ts(13, FontWeight.w400, t.muted)))),
          ])
        : BackHeader('Simulation',
            subtitle: 'Bac à sable · ne touche jamais ton budget',
            trailing: SmallButton('Réinitialiser', onTap: () => setState(() => _hyps.clear())));

    Widget hypCard(Hyp h) {
      final step = h.oldAmount >= 200 || h.newAmount >= 200 ? 10.0 : (h.oldAmount >= 20 ? 1.0 : 0.5);
      final maxV = max(max(h.oldAmount * 2, h.oldAmount + 100), h.newAmount);
      final d = h.delta;
      final deltaText = d.abs() < 0.005 ? 'inchangé' : '${signed(d, eur0)} / mois';
      final deltaColor = d > 0.004 ? t.warn : (d < -0.004 ? t.mint : t.muted);
      final unit = switch (h.freq) { 'week' => ' / sem.', 'year' => ' / an', _ => '' };
      Widget stepBtn(String icon, double k) => Pressable(
            onTap: h.keep ? () => setState(() => h.newAmount = max(0, ((h.newAmount + k * step) / step).round() * step)) : null,
            semantics: k < 0 ? 'Diminuer' : 'Augmenter',
            child: Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: g ? Colors.transparent : t.chip,
                borderRadius: BorderRadius.circular(g ? 24 : 16),
                border: g ? Border.all(color: t.lineStrong) : null,
              ),
              child: Ico(icon, size: 20, color: t.ink, stroke: g ? 1.4 : 2),
            ),
          );
      final card = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          CatIcon(cat: h.cat, name: h.name, size: g ? 34 : 32),
          SizedBox(width: g ? 14 : 10),
          Expanded(child: Text(h.name, style: t.ts(15, g ? FontWeight.w400 : FontWeight.w700))),
          Text(h.isNew ? 'nouvelle charge' : 'actuel ${eurAuto(h.oldAmount)}$unit', style: t.ts(13, t.wSemi, t.muted)),
          Pressable(
            onTap: () => setState(() => _hyps.remove(h)),
            semantics: 'Retirer l’hypothèse',
            child: Padding(padding: const EdgeInsets.only(left: 10), child: Ico('close', size: 16, color: t.muted)),
          ),
        ]),
        SizedBox(height: g ? 16 : 12),
        Opacity(
          opacity: h.keep ? 1 : 0.35,
          child: Column(children: [
            Row(children: [
              stepBtn('minus', -1),
              Expanded(
                child: Column(children: [
                  FittedBox(
                    child: Text('${eurAuto(h.newAmount)}$unit',
                        style: t.ts(g ? 52 : 34, g ? FontWeight.w300 : FontWeight.w800).copyWith(letterSpacing: g ? -2 : -0.7, height: 1.1)),
                  ),
                  Text(deltaText, style: t.ts(13, g ? FontWeight.w400 : FontWeight.w800, deltaColor)),
                ]),
              ),
              stepBtn('plus', 1),
            ]),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: g ? t.fab : t.mint,
                inactiveTrackColor: g ? t.lineStrong : t.track,
                thumbColor: g ? t.fab : t.mint,
                overlayColor: (g ? t.fab : t.mint).withValues(alpha: 0.12),
                trackHeight: g ? 2 : 4,
              ),
              child: Slider(
                value: h.newAmount.clamp(0, maxV).toDouble(),
                min: 0,
                max: maxV,
                onChanged: h.keep ? (v) => setState(() => h.newAmount = (v / step).round() * step) : null,
              ),
            ),
          ]),
        ),
        if (!h.isNew)
          Row(children: [
            Expanded(child: Text('Garder ${h.name}', style: t.ts(14, t.wSemi, t.muted))),
            Toggle(value: h.keep, onChanged: (v) => setState(() => h.keep = v)),
          ]),
      ]);
      return g ? Ruled(padV: 18, child: card) : Panel(child: card);
    }

    final hypsSection = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionLabel(g ? 'Hypothèses' : 'Tes hypothèses'),
      SizedBox(height: g ? 6 : 6),
      if (_hyps.isEmpty)
        Panel(
          padding: const EdgeInsets.all(16),
          child: Ruled(
            child: Text('« Et si mon loyer passait à 900 € ? » Choisis une charge à modifier ou à couper, ou ajoute-en une nouvelle.',
                style: t.ts(14, t.wBody, t.muted).copyWith(height: 1.45)),
          ),
        ),
      ...spaced([for (final h in _hyps) hypCard(h)], g ? 0 : 8),
      SizedBox(height: g ? 0 : 8),
      if (g && _hyps.isNotEmpty) Container(height: 1, color: t.line),
      DashedButton('+ Ajouter une hypothèse', onTap: _addHyp),
    ]);

    // Résultats
    bool worse(double d) => d > 0.004;
    bool better(double d) => d < -0.004;
    final results = <(String, String, String, String, double)>[]; // libellé, avant, après, puce, sens
    results.add(('Charges fixes / mois', eur(fix), eur(fix + delta), signed(delta, eur0), delta));
    if (income > 0) {
      results.add(('Reste à vivre (revenus ${eur0(income)})', eur(income - fix), eur(income - fix - delta), signed(-delta, eur0), delta));
    }
    final catDelta = <String, double>{};
    for (final h in _hyps) {
      catDelta[h.cat] = (catDelta[h.cat] ?? 0) + h.delta;
    }
    for (final e in catDelta.entries) {
      final cs = s.perCat[e.key]!;
      if (cs.budget <= 0 || e.value.abs() < 0.005) continue;
      final before = cs.budget - cs.projected;
      final after = before - e.value;
      String txt(double m) => m >= 0 ? 'marge ${eur0(m)}' : 'dépasse de ${eur0(-m)}';
      results.add((
        'Enveloppe ${catOf(e.key).name} (${eur0(cs.budget)})',
        txt(before),
        txt(after),
        after < 0 ? 'à revoir' : 'ok',
        after < 0 ? 1 : (after < before ? 0.5 : -1),
      ));
    }
    final typical = store.typicalMonth;
    results.add(('Dépenses d’un mois type', eur0(typical), eur0(typical + delta), signed(delta, eur0), delta));
    if (store.goals.isNotEmpty) {
      final goal = store.goals.first;
      final mBefore = goal.monthsWith(goal.monthly);
      final mAfter = goal.monthsWith(max(0, goal.monthly - delta));
      final diff = (mAfter ?? 999) - (mBefore ?? 999);
      results.add((
        'Objectif ${goal.name} (reste ${eur0(goal.remaining)})',
        goalWhen(mBefore),
        goalWhen(mAfter),
        diff == 0 ? 'inchangé' : (mAfter == null || mBefore == null ? (mAfter == null ? 'bloqué' : 'débloqué') : signed(diff.toDouble(), (n) => '${n.round()} mois')),
        diff.toDouble(),
      ));
    }

    Widget resultRow((String, String, String, String, double) r) {
      final chipColor = worse(r.$5) ? t.warn : (better(r.$5) ? t.mint : t.muted);
      final chipBg = worse(r.$5) ? t.warnSoft : (better(r.$5) ? t.mintSoft : t.chip);
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(child: Text(r.$1, style: g ? t.ts(13, FontWeight.w400, t.muted) : t.ts(14, FontWeight.w700))),
          g
              ? Text(r.$4, style: t.mono(11, chipColor))
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: chipBg, borderRadius: BorderRadius.circular(999)),
                  child: Text(r.$4, style: t.ts(12, FontWeight.w800, chipColor)),
                ),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          Flexible(child: Text(r.$2, style: t.ts(g ? 15 : 14, t.wSemi, g ? t.faint : t.muted))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: g ? Text('→', style: t.ts(15, FontWeight.w400, t.faint)) : Ico('arrowR', size: 14, color: t.muted),
          ),
          Flexible(child: Text(r.$3, style: t.ts(g ? 15 : 14, g ? FontWeight.w400 : FontWeight.w800))),
        ]),
      ]);
    }

    final noChange = delta.abs() < 0.005;
    final impactColor = worse(delta)
        ? (g ? t.warn : (t.dark ? const Color(0xFFF2A65A) : const Color(0xFFF5B47A)))
        : (g ? (noChange ? t.ink : t.mint) : t.heroAccent);
    final impact = g
        ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('IMPACT PAR MOIS', style: t.label()),
            const SizedBox(height: 10),
            Text(noChange ? '0 €' : signed(delta, eur),
                style: t.ts(52, FontWeight.w300, impactColor).copyWith(letterSpacing: -2, height: 1)),
            const SizedBox(height: 10),
            Text(noChange ? 'Aucun changement' : '${signed(delta * 12, eur0)} sur un an', style: t.ts(14, FontWeight.w400, t.muted)),
          ])
        : Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: t.hero, borderRadius: BorderRadius.circular(22)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Impact par mois', style: t.ts(13, FontWeight.w600, t.heroMuted)),
              const SizedBox(height: 4),
              Text(noChange ? '0 €' : signed(delta, eur),
                  style: t.ts(34, FontWeight.w800, impactColor).copyWith(letterSpacing: -0.7)),
              Text(noChange ? 'Aucun changement' : '${signed(delta * 12, eur0)} sur un an',
                  style: t.ts(13, FontWeight.w600, t.heroMuted)),
            ]),
          );

    final resultsSection = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (!g) ...[SectionLabel('Ce que ça change'), const SizedBox(height: 6)],
      impact,
      SizedBox(height: g ? 18 : 8),
      g
          ? Column(children: [for (final r in results) Ruled(child: resultRow(r))])
          : Panel(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(children: [for (final r in results) Ruled(padV: 20, child: resultRow(r))]),
            ),
    ]);

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(t.pad, g ? 14 : 12, t.pad, 24),
              children: spaced([header, hypsSection, resultsSection], g ? 28 : 14),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(t.pad, 12, t.pad, 16),
            child: Row(children: [
              Expanded(
                  flex: g ? 1 : 5,
                  child: SecondaryButton('Mes simulations',
                      onTap: () => Navigator.of(context)
                          .pushReplacement(MaterialPageRoute(builder: (_) => const SimulationsScreen())))),
              const SizedBox(width: 10),
              Expanded(
                flex: g ? 1 : 7,
                child: PrimaryButton('Enregistrer', icon: g ? null : 'save', onTap: _hyps.isEmpty ? null : _save),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
