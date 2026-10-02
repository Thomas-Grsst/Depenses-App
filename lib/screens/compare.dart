import 'dart:math';

import 'package:flutter/material.dart';

import '../format.dart';
import '../icons.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../ui.dart';

class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});
  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  (int, int)? _ref;
  bool _toDate = true;

  @override
  Widget build(BuildContext context) {
    final t = TkScope.of(context);
    final g = t.graphite;
    final store = StoreScope.of(context);
    final today = store.today;
    final prev = DateTime(today.year, today.month - 1);
    final ref = _ref ?? (prev.year, prev.month);
    final refName = monthsFr[ref.$2 - 1];
    final cutoff = _toDate ? today.day : 31;

    final cur = <String, double>{for (final c in cats) c.key: 0};
    final old = <String, double>{for (final c in cats) c.key: 0};
    for (final e in store.inMonth(today.year, today.month)) {
      if (!e.date.isAfter(today)) cur[e.cat] = (cur[e.cat] ?? 0) + e.amount;
    }
    final refList = store.inMonth(ref.$1, ref.$2);
    for (final e in refList) {
      if (e.date.day <= cutoff) old[e.cat] = (old[e.cat] ?? 0) + e.amount;
    }
    final curTotal = cur.values.fold(0.0, (a, v) => a + v);
    final oldTotal = old.values.fold(0.0, (a, v) => a + v);
    final ratio = oldTotal > 0 ? curTotal / oldTotal - 1 : null;
    final diff = curTotal - oldTotal;

    final rows = [
      for (final c in cats)
        if (cur[c.key]! > 0 || old[c.key]! > 0) (c, cur[c.key]!, old[c.key]!),
    ];
    final maxAbs = rows.fold(1.0, (a, r) => max(a, (r.$2 - r.$3).abs()));

    Future<void> pickRef() async {
      final months = store.monthsWithData().where((m) => !(m.$1 == today.year && m.$2 == today.month)).toList();
      if (months.isEmpty) return;
      final r = await showSheet<(int, int)>(context,
          title: 'Comparer avec',
          builder: (ctx) => Column(children: [
                for (final m in months)
                  Ruled(
                    child: Pressable(
                      onTap: () => Navigator.pop(ctx, m),
                      child: SizedBox(
                          height: 40,
                          child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(monthYear(m.$1, m.$2), style: t.ts(16, t.wItem)))),
                    ),
                  ),
              ]));
      if (r != null) setState(() => _ref = r);
    }

    final selector = g
        ? Pressable(
            onTap: pickRef,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('vs ${cap(refName)}', style: t.ts(15, FontWeight.w500)),
              const SizedBox(width: 6),
              Ico('chevD', size: 14, color: t.ink, stroke: 1.6),
            ]),
          )
        : null;

    // Insight : plus forte hausse / baisse
    final sorted = [...rows]..sort((a, b) => (a.$2 - a.$3).compareTo(b.$2 - b.$3));
    final down = sorted.isNotEmpty && sorted.first.$2 - sorted.first.$3 < 0 ? sorted.first : null;
    final up = sorted.isNotEmpty && sorted.last.$2 - sorted.last.$3 > 0 ? sorted.last : null;
    final insight = <(String, bool, Color?)>[
      if (down != null) ...[
        ('La ', false, null),
        ('baisse', g, t.mint),
        (' vient surtout de ', false, null),
        (down.$1.name, !g, null),
        (' (${signed(down.$2 - down.$3, eur0)})', false, null),
      ],
      if (down != null && up != null) ('. ', false, null),
      if (up != null) ...[
        (down == null ? 'C’est ' : 'À l’inverse, c’est ', false, null),
        (up.$1.name, true, g ? t.warn : null),
        (' qui grimpe le plus (${signed(up.$2 - up.$3, eur0)}).', false, null),
      ],
      if (up == null && down != null) ('.', false, null),
    ];

    final emptyRef = refList.isEmpty;

    final hero = g
        ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(monthsFr[today.month - 1].toUpperCase(), style: t.label()),
            const SizedBox(height: 10),
            Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
              Flexible(child: BigAmount(curTotal, size: 60)),
              if (ratio != null) ...[
                const SizedBox(width: 14),
                Text('${ratio <= 0 ? '↓' : '↑'} ${pct(ratio.abs())}',
                    style: t.ts(18, FontWeight.w400, ratio <= 0 ? t.mint : t.warn)),
              ],
            ]),
            const SizedBox(height: 10),
            Text(
                '${cap(refName)}${_toDate ? ' à la même date' : ' (mois entier)'} : ${eur(oldTotal)} · ${signed(diff, eur)}',
                style: t.ts(14, FontWeight.w400, t.muted)),
          ])
        : Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: t.hero, borderRadius: BorderRadius.circular(24)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Ce mois-ci', style: t.ts(14, FontWeight.w600, t.heroMuted)),
              const SizedBox(height: 6),
              Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                Flexible(child: BigAmount(curTotal, size: 36, color: t.heroInk)),
                if (ratio != null) ...[
                  const SizedBox(width: 10),
                  Text(signedPct(ratio),
                      style: t.ts(15, FontWeight.w800, ratio <= 0 ? t.heroAccent : const Color(0xFFF5B47A))),
                ],
              ]),
              const SizedBox(height: 6),
              Text(
                  '${cap(refName)}${_toDate ? ' à la même date' : ' (mois entier)'} : ${eur(oldTotal)} · soit ${eur(diff.abs())} de ${diff <= 0 ? 'moins' : 'plus'}',
                  style: t.ts(13, FontWeight.w600, t.heroMuted)),
            ]),
          );

    Widget row((Cat, double, double) r) {
      final d = r.$2 - r.$3;
      final p = r.$3 > 0 ? r.$2 / r.$3 - 1 : null;
      final tone = d > 0.005 ? t.warn : (d < -0.005 ? t.mint : t.muted);
      final pctText = p == null ? 'nouveau' : signedPct(p);
      final deltaText = d.abs() < 0.005 ? '—' : signed(d, eur);
      final detail = '${eur(r.$2)} · ${monthsShort[ref.$2 - 1]} ${eur(r.$3)}';
      final w = d.abs() / maxAbs;
      final bars = LayoutBuilder(builder: (ctx, c) {
        final half = c.maxWidth / 2;
        return SizedBox(
          height: g ? 3 : 10,
          child: Row(children: [
            SizedBox(
              width: half,
              child: Container(
                alignment: Alignment.centerRight,
                decoration: BoxDecoration(border: Border(right: BorderSide(color: g ? t.ghost : t.lineStrong))),
                child: Container(
                  width: d < 0 ? half * w : 0,
                  decoration: BoxDecoration(
                      color: t.good, borderRadius: g ? null : const BorderRadius.horizontal(left: Radius.circular(5))),
                ),
              ),
            ),
            SizedBox(
              width: half,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: d > 0 ? half * w : 0,
                  decoration: BoxDecoration(
                      color: t.bad, borderRadius: g ? null : const BorderRadius.horizontal(right: Radius.circular(5))),
                ),
              ),
            ),
          ]),
        );
      });
      if (g) {
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            CatIcon(cat: r.$1.key, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.$1.name, style: t.ts(15, FontWeight.w400)),
                Text(detail, style: t.ts(12, FontWeight.w400, t.muted)),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(pctText, style: t.ts(15, FontWeight.w400, tone)),
              Text(deltaText, style: t.mono(11, t.muted)),
            ]),
          ]),
          const SizedBox(height: 10),
          Padding(padding: const EdgeInsets.only(left: 44), child: bars),
        ]);
      }
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            CatIcon(cat: r.$1.key, size: 28),
            const SizedBox(width: 10),
            Expanded(child: Text(r.$1.name, style: t.ts(14, FontWeight.w700))),
            Text(pctText, style: t.ts(14, FontWeight.w800, tone)),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(child: bars),
            SizedBox(
                width: 86,
                child: Text(deltaText, textAlign: TextAlign.right, style: t.ts(12, FontWeight.w700, t.muted))),
          ]),
          const SizedBox(height: 6),
          Text(detail, style: t.ts(12, FontWeight.w500, t.muted)),
        ]),
      );
    }

    final breakdown = g
        ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                Expanded(child: Text('POURQUOI ÇA BOUGE', style: t.label())),
                Text('ÉCART €', style: t.label()),
              ]),
            ),
            for (final r in rows) Ruled(child: row(r)),
          ])
        : Panel(
            radius: 22,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Expanded(child: Text('Pourquoi ça bouge', style: t.ts(15, FontWeight.w800))),
                Text('écart en €', style: t.ts(12, FontWeight.w600, t.muted)),
              ]),
              const SizedBox(height: 8),
              for (final r in rows) row(r),
            ]),
          );

    final insightW = insight.isEmpty
        ? null
        : g
            ? Container(
                padding: const EdgeInsets.only(top: 16),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: t.line))),
                child: Text.rich(
                  TextSpan(children: [
                    for (final p in insight)
                      TextSpan(text: p.$1, style: p.$3 != null ? TextStyle(color: p.$3) : null),
                  ]),
                  style: t.ts(16, FontWeight.w300, t.body).copyWith(height: 1.5),
                ),
              )
            : Callout(parts: [for (final p in insight) (p.$1, p.$2)]);

    return Scaffold(
      backgroundColor: t.bg,
      body: PageList(children: [
        g
            ? Row(children: [
                RoundButton('chevL', semantics: 'Retour', onTap: () => Navigator.pop(context)),
                Expanded(child: Center(child: selector)),
                Pressable(
                  onTap: () => setState(() => _toDate = !_toDate),
                  child: SizedBox(
                    width: 64,
                    child: Text(_toDate ? 'AU ${today.day}' : 'MOIS ENTIER',
                        textAlign: TextAlign.right, style: t.mono(10, t.muted)),
                  ),
                ),
              ])
            : const BackHeader('Comparaison'),
        if (!g)
          Row(children: [
            Pressable(
              onTap: pickRef,
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(999)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('vs $refName', style: t.ts(13, FontWeight.w700)),
                  const SizedBox(width: 6),
                  Ico('chevD', size: 14, color: t.ink, stroke: 2),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            PillChip(_toDate ? 'À date (au ${today.day})' : 'Mois entier',
                selected: true, height: 40, onTap: () => setState(() => _toDate = !_toDate)),
          ]),
        if (emptyRef)
          Panel(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Pas encore de dépenses en $refName pour comparer. Reviens le mois prochain : tu verras ici ce qui a bougé, catégorie par catégorie.',
              style: t.ts(14, t.wBody, t.muted).copyWith(height: 1.45),
            ),
          )
        else ...[
          hero,
          if (rows.isNotEmpty) breakdown,
          ?insightW,
        ],
      ]),
    );
  }
}
