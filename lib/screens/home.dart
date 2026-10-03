import 'package:flutter/material.dart';

import '../charts.dart';
import '../format.dart';
import '../icons.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../ui.dart';
import '../widgets.dart';
import 'account.dart';
import 'budget.dart';
import 'compare.dart';
import 'roundup.dart';
import 'forecast.dart';
import 'shell.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = TkScope.of(context);
    final store = StoreScope.of(context);
    final s = store.stats;
    final alerts = store.alerts;
    final next = store.nextOccurrences(3);
    final recent = store.recent(3);
    final monthName = monthsFr[s.m - 1];
    final prevName = monthsFr[DateTime(s.y, s.m - 1).month - 1];

    void showAlerts() => showSheet(context,
        title: 'Alertes',
        builder: (_) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: alerts.isEmpty
                  ? [EmptyRow(store.settings.alerts ? 'Rien à signaler, tout est sous contrôle.' : 'Les alertes sont désactivées (Profil).')]
                  : spaced([for (final a in alerts) Callout(parts: a.parts, warn: true, icon: 'alert')], 10),
            ));

    final bell = Pressable(
      onTap: showAlerts,
      semantics: 'Alertes',
      child: Container(
        width: 44,
        height: 44,
        alignment: t.graphite ? Alignment.centerRight : Alignment.center,
        decoration: t.graphite ? null : BoxDecoration(color: t.card, shape: BoxShape.circle),
        child: Stack(clipBehavior: Clip.none, children: [
          Ico('bell', size: 20, color: t.ink),
          if (alerts.isNotEmpty)
            Positioned(
              top: -1,
              right: t.graphite ? -3 : -1,
              child: Container(
                  width: t.graphite ? 6 : 8,
                  height: t.graphite ? 6 : 8,
                  decoration: BoxDecoration(color: t.graphite ? t.accent : t.warn, shape: BoxShape.circle)),
            ),
        ]),
      ),
    );

    final upcoming = ListSection(
      title: t.graphite ? 'À venir' : 'Prochaines dépenses',
      action: 'Tout voir',
      onAction: () => ShellNav.tab(context, 2),
      empty: 'Aucune échéance prévue. Ajoute ton loyer, tes abonnements… en mode « Récurrente ».',
      children: [for (final o in next) OccRow(o)],
    );
    final latest = ListSection(
      title: t.graphite ? 'Récent' : 'Dernières dépenses',
      action: 'Tout voir',
      onAction: () => ShellNav.tab(context, 1),
      empty: 'Aucune dépense pour l’instant. Appuie sur + pour commencer.',
      children: [
        for (final e in recent)
          ExpenseRow(e,
              meta: [
                relDay(e.date, store.today),
                catOf(e.cat).name,
                if (!t.graphite && e.labels.isNotEmpty) e.labels.first,
              ].join(' · ')),
      ],
    );

    final vs = s.vsPrev;

    final g = t.graphite;
    // Solde du compte
    final pay = store.nextPayday;
    final payText = pay == null
        ? null
        : 'Salaire ${relDayLong(pay, store.today).toLowerCase()} · +${eur0(store.settings.income)}';
    final Widget account;
    if (!store.hasBalance) {
      account = Pressable(
        onTap: () => editAccount(context),
        child: g
            ? Text('Indiquer le solde de mon compte →', style: t.ts(14, FontWeight.w400, t.muted))
            : Panel(
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Sur ton compte', style: t.ts(13, FontWeight.w600, t.muted)),
                      const SizedBox(height: 2),
                      Text('Indique ton solde actuel', style: t.ts(15, FontWeight.w800)),
                    ]),
                  ),
                  Ico('chevR', size: 18, color: t.muted),
                ]),
              ),
      );
    } else {
      final bal = store.balance, end = store.balanceEndOfMonth;
      account = Pressable(
        onTap: () => showEndOfMonth(context),
        child: g
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('SUR LE COMPTE', style: t.label()),
                const SizedBox(height: 10),
                BigAmount(bal, size: 68, color: bal < 0 ? t.warn : null),
                const SizedBox(height: 10),
                Text.rich(
                  TextSpan(children: [
                    const TextSpan(text: 'Fin de mois ≈ '),
                    TextSpan(text: eur0(end), style: TextStyle(color: end < 0 ? t.warn : t.ink)),
                    if (payText != null) TextSpan(text: '  ·  $payText', style: TextStyle(color: t.mint)),
                  ]),
                  style: t.ts(14, FontWeight.w400, t.muted),
                ),
              ])
            : Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: t.hero, borderRadius: BorderRadius.circular(24)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Sur ton compte', style: t.ts(14, FontWeight.w600, t.heroMuted)),
                  const SizedBox(height: 8),
                  BigAmount(bal, size: 40, color: bal < 0 ? const Color(0xFFF5B47A) : t.heroInk),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(children: [
                          const TextSpan(text: 'Fin de mois ≈ '),
                          TextSpan(
                              text: eur0(end),
                              style: TextStyle(
                                  color: end < 0 ? const Color(0xFFF5B47A) : t.heroInk, fontWeight: FontWeight.w800)),
                        ]),
                        style: t.ts(14, FontWeight.w600, t.heroMuted),
                      ),
                    ),
                    Text('Détail ›', style: t.ts(13, FontWeight.w700, t.heroAccent)),
                  ]),
                  if (payText != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: t.heroChip, borderRadius: BorderRadius.circular(999)),
                      child: Text(payText, style: t.ts(12, FontWeight.w700, t.heroAccent)),
                    ),
                  ],
                ]),
              ),
      );
    }

    final heroIsAccount = store.hasBalance;
    final budgetBtn = Pressable(
      onTap: () => go(context, const BudgetScreen()),
      child: g
          ? Text(s.budget > 0 ? 'Gérer mon budget par catégorie →' : 'Définir combien je prévois par catégorie →',
              style: t.ts(14, FontWeight.w400, t.muted))
          : Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: heroIsAccount ? t.mintSoft : t.heroInk.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(s.budget > 0 ? 'Gérer mon budget' : 'Définir mon budget',
                    style: t.ts(13, FontWeight.w800, heroIsAccount ? t.mint : t.heroInk)),
                const SizedBox(width: 4),
                Ico('chevR', size: 14, color: heroIsAccount ? t.mint : t.heroInk, stroke: 2.2),
              ]),
            ),
    );

    if (t.graphite) {
      return PageList(children: [
        Row(children: [
          Expanded(child: Text(cap(monthName), style: t.ts(15, FontWeight.w500))),
          bell,
        ]),
        account,
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('DÉPENSÉ EN ${monthName.toUpperCase()}', style: t.label()),
          const SizedBox(height: 10),
          BigAmount(s.spent, size: heroIsAccount ? 40 : 68),
          if (vs != null) ...[
            const SizedBox(height: 10),
            Pressable(
              onTap: () => go(context, const CompareScreen()),
              child: Text('${vs <= 0 ? '↓' : '↑'} ${pct(vs.abs())} par rapport à $prevName →',
                  style: t.ts(14, FontWeight.w400, vs <= 0 ? t.mint : t.warn)),
            ),
          ],
        ]),
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (s.budget > 0)
            Pressable(
              onTap: () => go(context, const BudgetScreen()),
              child: Column(children: [
                Bar(s.spent / s.budget, marker: s.forecast / s.budget, dot: true),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                      child: Text('${pct(s.spent / s.budget)} · BUDGET ${num0(s.budget)} €',
                          style: t.mono(11, t.muted))),
                  Text('PRÉVU ${num0(s.forecast)} €', style: t.mono(11, t.muted)),
                ]),
                const SizedBox(height: 12),
              ]),
            ),
          budgetBtn,
        ]),
        if (store.settings.roundUp || store.roundUpTotal > 0) const RoundUpCard(),
        Pressable(onTap: () => go(context, const ForecastScreen()), child: Sparkline(s, height: 90)),
        if (alerts.isNotEmpty) Callout(parts: alerts.first.parts, warn: true),
        upcoming,
        latest,
      ]);
    }

    // Carte "Dépensé" : en vedette s'il n'y a pas de solde, sinon carte normale sous le solde.
    final hBg = heroIsAccount ? t.card : t.hero;
    final hInk = heroIsAccount ? t.ink : t.heroInk;
    final hMuted = heroIsAccount ? t.muted : t.heroMuted;
    final hAccent = heroIsAccount ? t.mintFill : t.heroAccent;
    final upColor = heroIsAccount ? t.warn : const Color(0xFFF5B47A);
    final hero = Pressable(
      onTap: () => go(context, const BudgetScreen()),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: hBg, borderRadius: BorderRadius.circular(24)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('Dépensé en $monthName', style: t.ts(14, FontWeight.w600, hMuted))),
            if (vs != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: vs <= 0 ? (heroIsAccount ? t.mintSoft : t.heroChip) : upColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999)),
                child: Text('${signedPct(vs)} vs $prevName',
                    style: t.ts(13, FontWeight.w700, vs <= 0 ? (heroIsAccount ? t.mint : t.heroAccent) : upColor)),
              ),
          ]),
          const SizedBox(height: 10),
          BigAmount(s.spent, size: heroIsAccount ? 30 : 40, color: hInk),
          const SizedBox(height: 12),
          if (s.budget > 0) ...[
            Bar(s.spent / s.budget,
                fill: s.spent > s.budget ? upColor : hAccent,
                track: heroIsAccount ? t.track : t.heroInk.withValues(alpha: 0.14)),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(
                  child: Text('${pct(s.spent / s.budget)} du budget de ${eur0(s.budget)}',
                      style: t.ts(13, FontWeight.w600, hMuted))),
              Text(s.spent <= s.budget ? 'Reste ${eur(s.budget - s.spent)}' : 'Dépassé de ${eur(s.spent - s.budget)}',
                  style: t.ts(13, FontWeight.w600, hMuted)),
            ]),
            const SizedBox(height: 12),
          ] else ...[
            Text('Fixe combien tu prévois de dépenser par catégorie (courses, sorties…) pour suivre ton rythme.',
                style: t.ts(13, FontWeight.w600, hMuted).copyWith(height: 1.4)),
            const SizedBox(height: 12),
          ],
          budgetBtn,
        ]),
      ),
    );

    final ms = moves(s)..sort((a, b) => b.delta.abs().compareTo(a.delta.abs()));
    final movedCard = Pressable(
      onTap: () => go(context, const CompareScreen()),
      child: Panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Ce qui a bougé', style: t.ts(13, FontWeight.w600, t.muted)),
          const SizedBox(height: 8),
          if (!s.hasPrev || ms.isEmpty)
            Text('Comparaison dispo dès le mois prochain.', style: t.ts(13, FontWeight.w600, t.muted))
          else
            for (final mv in ms.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(children: [
                  CatIcon(cat: mv.cat.key, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(mv.cat.short, overflow: TextOverflow.ellipsis, style: t.ts(13, FontWeight.w600))),
                  const SizedBox(width: 6),
                  Text(mv.ratio == null ? 'nouveau' : signedPct(mv.ratio!),
                      style: t.ts(13, FontWeight.w600, mv.delta > 0 ? t.warn : t.mint)),
                ]),
              ),
        ]),
      ),
    );

    final forecastCard = Pressable(
      onTap: () => go(context, const ForecastScreen()),
      child: Panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Dépenses prévues ce mois', style: t.ts(13, FontWeight.w600, t.muted)),
          const SizedBox(height: 6),
          Text(eur0(s.forecast), style: t.ts(22, FontWeight.w800)),
          const SizedBox(height: 6),
          Sparkline(s),
          const SizedBox(height: 6),
          Text('≈ ${eur0(s.forecast - s.spent)} encore à venir', style: t.ts(12, FontWeight.w600, t.muted)),
        ]),
      ),
    );

    return PageList(children: [
      Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(longDate(store.today), style: t.ts(14, FontWeight.w600, t.muted)),
            Text('Bonjour ${store.settings.name}',
                overflow: TextOverflow.ellipsis, style: t.ts(26, FontWeight.w800).copyWith(letterSpacing: -0.5)),
          ]),
        ),
        bell,
      ]),
      account,
      hero,
      if (store.settings.roundUp || store.roundUpTotal > 0) const RoundUpCard(),
      if (alerts.isNotEmpty) Callout(parts: alerts.first.parts, warn: true, icon: 'alert'),
      TwoUp(forecastCard, movedCard),
      upcoming,
      latest,
    ]);
  }
}

