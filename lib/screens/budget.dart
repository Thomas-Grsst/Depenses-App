import 'package:flutter/material.dart';

import '../format.dart';
import '../icons.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../ui.dart';
import 'simulation.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  /// Budget d'une seule catégorie.
  static Future<void> editEnvelope(BuildContext context, String catKey) async {
    final store = StoreScope.read(context);
    final c = catOf(catKey);
    final cur = store.envelopes[catKey];
    final ctrl = TextEditingController(text: cur == null ? '' : amountInput(cur));
    final ok = await showSheet<bool>(context,
        title: 'Budget ${c.name}',
        builder: (ctx) {
          final t = TkScope.of(ctx);
          final cs = store.stats.perCat[catKey];
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              CatIcon(cat: catKey, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                    'Combien prévois-tu de dépenser par mois en ${c.name.toLowerCase()} ?'
                    '${cs != null && cs.spent > 0 ? '\nDéjà ${eur(cs.spent)} ce mois-ci.' : ''}',
                    style: t.ts(13, t.wBody, t.muted).copyWith(height: 1.4)),
              ),
            ]),
            const SizedBox(height: 16),
            Field('Montant par mois', controller: ctrl, number: true, hint: 'Ex. 300', autofocus: true),
            const SizedBox(height: 20),
            PrimaryButton('Enregistrer', onTap: () => Navigator.pop(ctx, true)),
            if (cur != null) ...[
              const SizedBox(height: 10),
              SecondaryButton('Ne plus suivre cette catégorie', color: t.warn, onTap: () {
                ctrl.clear();
                Navigator.pop(ctx, true);
              }),
            ],
          ]);
        });
    if (ok == true) {
      store.setEnvelope(catKey, parseAmount(ctrl.text) ?? 0);
      store.commit();
    }
  }

  static Future<void> editEnvelopes(BuildContext context) async {
    final store = StoreScope.read(context);
    final ctrls = {
      for (final c in cats)
        c.key: TextEditingController(text: store.envelopes[c.key] == null ? '' : num0(store.envelopes[c.key]!).replaceAll(nbsp, ''))
    };
    final ok = await showSheet<bool>(context,
        title: 'Mon budget par catégorie',
        builder: (ctx) {
          final t = TkScope.of(ctx);
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Combien prévois-tu de dépenser par mois dans chaque catégorie ? Laisse vide pour ne pas suivre.',
                style: t.ts(13, t.wBody, t.muted).copyWith(height: 1.4)),
            const SizedBox(height: 12),
            for (final c in cats)
              Ruled(
                child: Row(children: [
                  CatIcon(cat: c.key, size: 32),
                  const SizedBox(width: 12),
                  Expanded(child: Text(c.name, style: t.ts(15, t.wItem))),
                  SizedBox(
                    width: 110,
                    child: TextField(
                      controller: ctrls[c.key],
                      textAlign: TextAlign.right,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: t.ts(16, t.graphite ? FontWeight.w400 : FontWeight.w800),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: '—',
                        hintStyle: t.ts(16, FontWeight.w400, t.faint),
                        suffixText: ' €',
                        suffixStyle: t.ts(15, FontWeight.w400, t.muted),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ]),
              ),
            const SizedBox(height: 18),
            PrimaryButton('Enregistrer', onTap: () => Navigator.pop(ctx, true)),
          ]);
        });
    if (ok == true) {
      for (final c in cats) {
        store.setEnvelope(c.key, parseAmount(ctrls[c.key]!.text) ?? 0);
      }
      store.commit();
    }
  }

  static Future<void> editLabelEnvelope(BuildContext context, [LabelEnvelope? env]) async {
    final store = StoreScope.read(context);
    final name = TextEditingController(text: env?.name ?? '');
    final amount = TextEditingController(text: env == null ? '' : amountInput(env.amount));
    var label = env?.label ?? (store.labels.isNotEmpty ? store.labels.first : '');
    final res = await showSheet<String>(context,
        title: env == null ? 'Nouvelle enveloppe' : 'Enveloppe',
        builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
              final t = TkScope.of(ctx);
              return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('Une enveloppe perso suit toutes les dépenses qui portent un libellé, quelle que soit leur catégorie.',
                    style: t.ts(13, t.wBody, t.muted).copyWith(height: 1.4)),
                const SizedBox(height: 16),
                Field('Nom', controller: name, hint: 'Ex. Mes sorties'),
                const SizedBox(height: 16),
                SectionLabel('Libellé suivi'),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final l in store.labels) PillChip(l, selected: l == label, onTap: () => set(() => label = l)),
                ]),
                const SizedBox(height: 16),
                Field('Montant par mois', controller: amount, hint: 'Ex. 120', number: true),
                const SizedBox(height: 20),
                PrimaryButton('Enregistrer', onTap: () => Navigator.pop(ctx, 'save')),
                if (env != null) ...[
                  const SizedBox(height: 10),
                  SecondaryButton('Supprimer l’enveloppe', color: t.warn, onTap: () => Navigator.pop(ctx, 'delete')),
                ],
              ]);
            }));
    if (res == 'delete' && env != null) {
      store.labelEnvs.remove(env);
      store.commit();
    } else if (res == 'save') {
      final a = parseAmount(amount.text) ?? 0;
      if (a <= 0 || label.isEmpty) return;
      final n = name.text.trim().isEmpty ? 'Libellé « $label »' : name.text.trim();
      if (env == null) {
        store.labelEnvs.add(LabelEnvelope(id: newId(), name: n, label: label, amount: a));
      } else {
        env
          ..name = n
          ..label = label
          ..amount = a;
      }
      store.commit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = TkScope.of(context);
    final g = t.graphite;
    final store = StoreScope.of(context);
    final s = store.stats;
    final hasBudget = s.budget > 0;

    final header = BackHeader(
      g ? 'Budget · ${cap(monthsFr[s.m - 1])}' : 'Budget · ${monthsFr[s.m - 1]}',
      trailing: g
          ? Pressable(onTap: () => editEnvelopes(context), child: Text('Modifier', style: t.ts(13, FontWeight.w400, t.muted)))
          : SmallButton('Modifier', onTap: () => editEnvelopes(context)),
    );

    final marge = s.budget - s.forecast;
    final hero = !hasBudget
        ? Panel(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('Budget = enveloppes', style: t.ts(17, t.wStrong)),
              const SizedBox(height: 6),
              Text('« Je prévois 400 € pour l’alimentation, 120 € pour mes sorties. » Fixe un montant par catégorie : '
                  'l’app suit ton rythme et te prévient avant de dépasser.',
                  style: t.ts(14, t.wBody, t.muted).copyWith(height: 1.45)),
              const SizedBox(height: 16),
              PrimaryButton('Définir mes enveloppes', onTap: () => editEnvelopes(context)),
            ]),
          )
        : g
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('ENVELOPPES', style: t.label()),
                const SizedBox(height: 10),
                BigAmount(s.spent, size: 56, decimals: false, suffix: '/ ${num0(s.budget)} €'),
                const SizedBox(height: 10),
                Text.rich(
                  TextSpan(children: [
                    TextSpan(text: 'Prévu au ${s.dim} : ${eur0(s.forecast)} — '),
                    TextSpan(
                        text: marge >= 0 ? 'marge de ${eur0(marge)}' : 'dépassement de ${eur0(-marge)}',
                        style: TextStyle(color: marge >= 0 ? t.mint : t.warn)),
                  ]),
                  style: t.ts(14, FontWeight.w400, t.muted),
                ),
              ])
            : Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: t.hero, borderRadius: BorderRadius.circular(24)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Tes enveloppes du mois', style: t.ts(14, FontWeight.w600, t.heroMuted)),
                  const SizedBox(height: 10),
                  Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                    Text(eur0(s.spent), style: t.ts(34, FontWeight.w800, t.heroInk).copyWith(letterSpacing: -0.7)),
                    const SizedBox(width: 6),
                    Text('/ ${eur0(s.budget)}', style: t.ts(17, FontWeight.w700, t.heroMuted)),
                  ]),
                  const SizedBox(height: 12),
                  Bar(s.spent / s.budget,
                      marker: s.forecast / s.budget,
                      height: 10,
                      fill: s.spent > s.budget ? const Color(0xFFF5B47A) : t.heroAccent,
                      track: t.heroInk.withValues(alpha: 0.14),
                      markerColor: t.heroInk),
                  const SizedBox(height: 8),
                  Row(children: [
                    Text('${pct(s.spent / s.budget)} utilisé', style: t.ts(13, FontWeight.w600, t.heroMuted)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                          'Prévu au ${s.dim} : ${eur0(s.forecast)} · ${marge >= 0 ? 'marge ${eur0(marge)}' : 'dépasse de ${eur0(-marge)}'}',
                          textAlign: TextAlign.right,
                          style: t.ts(13, FontWeight.w600, t.heroMuted)),
                    ),
                  ]),
                ]),
              );

    final simLink = g
        ? Pressable(
            onTap: () => go(context, const SimulationScreen()),
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), border: Border.all(color: t.lineStrong)),
              child: Row(children: [
                Expanded(child: Text('Simuler un changement', style: t.ts(15, FontWeight.w400))),
                Ico('arrowR', size: 18, color: t.ink),
              ]),
            ),
          )
        : Pressable(
            onTap: () => go(context, const SimulationScreen()),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(color: t.mintSoft, borderRadius: BorderRadius.circular(18)),
              child: Row(children: [
                Ico('flask', size: 22, color: t.mint),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Simuler un changement', style: t.ts(15, FontWeight.w800)),
                    Text('« Et si mon loyer augmentait ? »', style: t.ts(12, FontWeight.w600, t.muted)),
                  ]),
                ),
                Ico('chevR', size: 18, color: t.ink),
              ]),
            ),
          );

    final envRows = <Widget>[];
    for (final c in cats) {
      final cs = s.perCat[c.key]!;
      final hasEnv = cs.budget > 0;
      final over = hasEnv && cs.projected > cs.budget;
      final String note;
      if (!hasEnv) {
        note = cs.spent > 0 ? 'Pas de budget prévu · touche pour en définir un' : 'Touche pour définir un budget';
      } else if (cs.spent > cs.budget) {
        note = 'Dépassé de ${eurAuto(cs.spent - cs.budget)}';
      } else if (over) {
        note = '${pct(cs.spent / cs.budget)} au ${s.day} du mois · dépassement prévu ≈ ${eur0(cs.projected - cs.budget)}';
      } else {
        note = 'Prévu au ${s.dim} : ≈ ${eur0(cs.projected)}';
      }
      envRows.add(Pressable(onTap: () => editEnvelope(context, c.key), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          CatIcon(cat: c.key, size: g ? 34 : 32),
          SizedBox(width: g ? 14 : 10),
          Expanded(child: Text(c.name, style: t.ts(15, g ? FontWeight.w400 : FontWeight.w700))),
          if (g)
            Text.rich(TextSpan(children: [
              TextSpan(text: num0(cs.spent)),
              if (hasEnv) TextSpan(text: ' / ${num0(cs.budget)}', style: TextStyle(color: t.faint)),
            ]), style: t.mono(13))
          else ...[
            Text(eurAuto(cs.spent), style: t.ts(14, FontWeight.w800)),
            if (hasEnv) Text(' / ${eurAuto(cs.budget)}', style: t.ts(13, FontWeight.w600, t.muted)),
          ],
        ]),
        if (hasEnv) ...[
          SizedBox(height: g ? 10 : 8),
          Padding(
            padding: EdgeInsets.only(left: g ? 48 : 0),
            child: Bar(cs.spent / cs.budget,
                marker: g ? null : cs.projected / cs.budget, fill: over ? t.warnFill : (g ? t.ink : t.mintFill)),
          ),
        ],
        if (!g || over || !hasEnv) ...[
          const SizedBox(height: 6),
          Padding(
            padding: EdgeInsets.only(left: g ? 48 : 0),
            child: Text(note, style: t.ts(12, t.wSemi, over ? t.warn : t.muted)),
          ),
        ],
      ])));
    }

    final envList = envRows.isEmpty
        ? null
        : g
            ? Column(children: [for (final r in envRows) Ruled(padV: 16, child: r)])
            : Panel(
                radius: 22,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(children: [for (final r in envRows) Ruled(padV: 22, child: r)]),
              );

    final labelRows = [
      for (final le in store.labelEnvs)
        () {
          final spent = store.labelSpent(le.label, s.y, s.m);
          final over = spent > le.amount;
          return Pressable(
            onTap: () => editLabelEnvelope(context, le),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                CatIcon(cat: 'loi', look: Look('letter', le.label.isEmpty ? '#' : le.label[0].toUpperCase()), size: g ? 34 : 32),
                SizedBox(width: g ? 14 : 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(le.name, style: t.ts(15, g ? FontWeight.w400 : FontWeight.w700)),
                    Text('libellé « ${le.label} »', style: t.ts(12, t.wSemi, t.muted)),
                  ]),
                ),
                if (g)
                  Text.rich(TextSpan(children: [
                    TextSpan(text: num0(spent)),
                    TextSpan(text: ' / ${num0(le.amount)}', style: TextStyle(color: t.faint)),
                  ]), style: t.mono(13))
                else ...[
                  Text(eur(spent), style: t.ts(14, FontWeight.w800)),
                  Text(' / ${eurAuto(le.amount)}', style: t.ts(13, FontWeight.w600, t.muted)),
                ],
              ]),
              SizedBox(height: g ? 10 : 8),
              Padding(
                padding: EdgeInsets.only(left: g ? 48 : 0),
                child: Bar(spent / le.amount, fill: over ? t.warnFill : (g ? t.ink : t.mintFill)),
              ),
            ]),
          );
        }(),
    ];

    final labelSection = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionLabel(g ? 'Perso · par libellé' : 'Enveloppes perso · par libellé'),
      SizedBox(height: g ? 12 : 8),
      if (labelRows.isNotEmpty)
        g
            ? Column(children: [
                for (var i = 0; i < labelRows.length; i++)
                  Ruled(padV: 16, bottom: i == labelRows.length - 1, child: labelRows[i]),
              ])
            : Column(children: spaced([for (final r in labelRows) Panel(child: r)], 8)),
      SizedBox(height: labelRows.isEmpty ? 0 : 8),
      DashedButton('+ Nouvelle enveloppe', onTap: () => editLabelEnvelope(context)),
    ]);

    return Scaffold(
      backgroundColor: t.bg,
      body: PageList(gap: g ? 30 : 14, children: [
        header,
        hero,
        if (!g) simLink,
        ?envList,
        labelSection,
        if (g) simLink,
      ]),
    );
  }
}
