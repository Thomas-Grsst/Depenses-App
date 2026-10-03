import 'package:flutter/material.dart';

import '../format.dart';
import '../icons.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../ui.dart';

Expense? _lastRounded(AppStore store) {
  Expense? best;
  for (final e in store.expenses) {
    if (e.roundUp <= 0) continue;
    if (best == null || e.date.isAfter(best.date) || (sameDay(e.date, best.date) && e.id.compareTo(best.id) > 0)) {
      best = e;
    }
  }
  return best;
}

/// Carte « Arrondis » de l'accueil : ce qui a été mis de côté en arrondissant chaque dépense.
class RoundUpCard extends StatelessWidget {
  const RoundUpCard({super.key});

  @override
  Widget build(BuildContext context) {
    final t = TkScope.of(context);
    final g = t.graphite;
    final store = StoreScope.of(context);
    final s = store.stats;
    final month = store.roundUpMonth(s.y, s.m);
    final total = store.roundUpTotal;
    final last = _lastRounded(store);
    final sub = total <= 0
        ? ''
        : [
            '${eur(total)} depuis le début',
            if (last != null) 'dernière : ${eur(last.amount)} → ${eur0(last.amount + last.roundUp)}',
          ].join(' · ');

    if (g) {
      return Pressable(
        onTap: () => showRoundUp(context),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(border: Border.symmetric(horizontal: BorderSide(color: t.line))),
          child: Row(children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: t.lineStrong)),
              child: Ico('piggy', size: 19, color: t.ink),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('ARRONDIS · ${monthsFr[s.m - 1].toUpperCase()}', style: t.label()),
                const SizedBox(height: 4),
                if (sub.isNotEmpty) Text(sub, style: t.ts(12, FontWeight.w400, t.muted)),
              ]),
            ),
            const SizedBox(width: 10),
            Text('+${eur(month)}', style: t.ts(17, FontWeight.w400, t.mint)),
          ]),
        ),
      );
    }
    return Pressable(
      onTap: () => showRoundUp(context),
      child: Panel(
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: t.mintSoft, borderRadius: BorderRadius.circular(14)),
            child: Ico('piggy', size: 22, color: t.mint, stroke: 2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Arrondis mis de côté en ${monthsFr[s.m - 1]}', style: t.ts(13, FontWeight.w600, t.muted)),
              Text('+${eur(month)}', style: t.ts(20, FontWeight.w800, t.mint)),
              if (sub.isNotEmpty) Text(sub, style: t.ts(12, FontWeight.w600, t.muted).copyWith(height: 1.35)),
            ]),
          ),
          Ico('chevR', size: 18, color: t.muted),
        ]),
      ),
    );
  }
}

/// Détail des arrondis : réglage, total, versement dans un objectif.
Future<void> showRoundUp(BuildContext context) => showSheet<void>(context,
    title: 'Arrondis à l’euro',
    builder: (ctx) => ListenableBuilder(
          listenable: StoreScope.read(context),
          builder: (ctx, _) {
            final t = TkScope.of(ctx);
            final store = StoreScope.read(context);
            final st = store.settings;
            final avail = store.roundUpAvailable;
            final rounded = [...store.expenses.where((e) => e.roundUp > 0)]
              ..sort((a, b) => b.date.compareTo(a.date));
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Ruled(
                child: Row(children: [
                  Expanded(child: Text('Arrondir mes dépenses', style: t.ts(15, t.wItem))),
                  Toggle(
                      value: st.roundUp,
                      onChanged: (v) {
                        st.roundUp = v;
                        store.commit();
                      }),
                ]),
              ),
              Ruled(
                child: Row(children: [
                  Expanded(child: Text('Mis de côté au total', style: t.ts(15, t.wItem))),
                  Text(eur(store.roundUpTotal), style: t.ts(15, t.wStrong)),
                ]),
              ),
              if (st.roundUpUsed > 0)
                Ruled(
                  child: Row(children: [
                    Expanded(child: Text('Déjà versé dans tes objectifs', style: t.ts(15, t.wItem))),
                    Text(eur(st.roundUpUsed), style: t.ts(15, t.wItem, t.muted)),
                  ]),
                ),
              Ruled(
                bottom: true,
                child: Row(children: [
                  Expanded(child: Text('Disponible', style: t.ts(15, t.wStrong))),
                  Text(eur(avail), style: t.ts(17, t.wStrong, t.mint)),
                ]),
              ),
              const SizedBox(height: 16),
              if (avail > 0 && store.goals.isNotEmpty) ...[
                for (final goal in store.goals) ...[
                  PrimaryButton('Verser ${eur(avail)} dans « ${goal.name} »', onTap: () {
                    store.moveRoundUpTo(goal);
                    toast(ctx, '${goal.name} : ${eur0(goal.saved)} / ${eur0(goal.target)}');
                  }),
                  const SizedBox(height: 8),
                ],
              ] else if (avail > 0)
                Text('Crée un objectif d’épargne dans ton profil pour y verser tes arrondis.',
                    style: t.ts(12, t.wSemi, t.muted)),
              if (rounded.isNotEmpty) ...[
                const SizedBox(height: 14),
                SectionLabel('Derniers arrondis'),
                const SizedBox(height: 4),
                for (final e in rounded.take(8))
                  Ruled(
                    child: ItemRow(
                      leading: CatIcon(cat: e.cat, name: e.name, size: 32),
                      title: e.name,
                      subtitle: '${shortDate(e.date)} · ${eur(e.amount)} → ${eur0(e.amount + e.roundUp)}',
                      trailingWidget: Text('+${eur(e.roundUp)}', style: t.ts(14, t.wItem, t.mint)),
                    ),
                  ),
              ],
            ]);
          },
        ));
