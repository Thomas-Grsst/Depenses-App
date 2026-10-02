import 'package:flutter/material.dart';

import '../format.dart';
import '../store.dart';
import '../theme.dart';
import '../ui.dart';

/// Saisie du salaire (montant + jour de paie) et du solde actuel du compte.
Future<void> editAccount(BuildContext context, {bool withName = false}) async {
  final store = StoreScope.read(context);
  final st = store.settings;
  final name = TextEditingController(text: st.name);
  final income = TextEditingController(text: st.income > 0 ? amountInput(st.income) : '');
  final balance = TextEditingController(text: store.hasBalance ? amountInput(store.balance) : '');
  var payDay = st.payDay;
  final ok = await showSheet<bool>(context,
      title: withName ? 'Mon profil' : 'Mon compte',
      builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
            final t = TkScope.of(ctx);
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (withName) ...[Field('Prénom', controller: name), const SizedBox(height: 16)],
              Field('Solde actuel du compte', controller: balance, number: true, hint: 'Ex. 1 250,40'),
              const SizedBox(height: 6),
              Text('Ce qu’il y a sur ton compte aujourd’hui. Ensuite l’app le tient à jour : − tes dépenses, + ton salaire.',
                  style: t.ts(12, t.wSemi, t.muted).copyWith(height: 1.4)),
              const SizedBox(height: 16),
              Field('Salaire mensuel', controller: income, number: true, hint: 'Ex. 2 400'),
              const SizedBox(height: 16),
              PayDayPicker(value: payDay, onChanged: (v) => set(() => payDay = v)),
              const SizedBox(height: 20),
              PrimaryButton('Enregistrer', onTap: () => Navigator.pop(ctx, true)),
            ]);
          }));
  if (ok != true) return;
  if (withName && name.text.trim().isNotEmpty) st.name = name.text.trim();
  st.income = parseAmount(income.text) ?? 0;
  st.payDay = payDay;
  final b = parseAmount(balance.text);
  if (balance.text.trim().isEmpty) {
    store.clearBalance();
  } else if (b != null && (!store.hasBalance || (b - store.balance).abs() >= 0.005)) {
    store.setBalance(b);
  } else {
    store.commit();
  }
}

/// Choix du jour de paie : − / jour / +
class PayDayPicker extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const PayDayPicker({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final t = TkScope.of(context);
    final g = t.graphite;
    Widget btn(String label, int d) => Pressable(
          onTap: () => onChanged(((value - 1 + d) % 31 + 31) % 31 + 1),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: g ? Colors.transparent : t.chip,
              borderRadius: BorderRadius.circular(g ? 22 : 14),
              border: g ? Border.all(color: t.lineStrong) : null,
            ),
            child: Text(label, style: t.ts(20, FontWeight.w500)),
          ),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(g ? 'JOUR DE PAIE' : 'Le salaire tombe le…', style: t.label()),
      const SizedBox(height: 8),
      Row(children: [
        btn('−', -1),
        Expanded(
          child: Column(children: [
            Text('${value == 1 ? '1er' : value}', style: t.ts(28, g ? FontWeight.w300 : FontWeight.w800)),
            Text('de chaque mois', style: t.ts(12, t.wSemi, t.muted)),
          ]),
        ),
        btn('+', 1),
      ]),
      if (value > 28)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text('Les mois plus courts, le dernier jour du mois.',
              textAlign: TextAlign.center, style: t.ts(12, t.wSemi, t.muted)),
        ),
    ]);
  }
}

/// Détail du calcul « fin de mois ».
Future<void> showEndOfMonth(BuildContext context) {
  final store = StoreScope.read(context);
  final s = store.stats;
  final t0 = store.today;
  final pays = store.payDates(t0.add(const Duration(days: 1)), DateTime(s.y, s.m, s.dim));
  final counts = <String, int>{};
  for (final o in s.remainingRec) {
    counts[o.rec.name] = (counts[o.rec.name] ?? 0) + 1;
  }
  final recNames = counts.entries.map((e) => e.value > 1 ? '${e.key} ×${e.value}' : e.key).join(', ');
  final future = store.futureNoted;
  return showSheet<void>(context,
      title: 'Fin de ${monthsFr[s.m - 1]}',
      builder: (ctx) {
        final t = TkScope.of(ctx);
        Widget line(String label, String? sub, double v, {bool bold = false}) => Ruled(
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(label, style: t.ts(15, bold ? t.wStrong : t.wItem)),
                    if (sub != null && sub.isNotEmpty) Text(sub, style: t.ts(12, t.wSemi, t.muted)),
                  ]),
                ),
                Text(bold ? eur(v) : signed(v, eur),
                    style: t.ts(bold ? 17 : 15, bold ? t.wStrong : t.wItem, v < 0 && !bold ? t.ink : (bold && v < 0 ? t.warn : t.ink))),
              ]),
            );
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          line('Sur ton compte aujourd’hui', null, store.balance, bold: true),
          for (final p in pays) line('Salaire', longDate(p), store.settings.income),
          line('Dépenses récurrentes à venir', recNames.isEmpty ? 'Aucune d’ici la fin du mois' : recNames,
              -s.remainingRecTotal),
          if (future > 0) line('Dépenses déjà notées pour plus tard', null, -future),
          line('Dépenses courantes estimées',
              '≈ ${eur0(s.rate)}/jour × ${s.remainingDays} jour${s.remainingDays > 1 ? 's' : ''} (ton rythme habituel)',
              -s.estOcc),
          line('Estimé au ${s.dim} ${monthsFr[s.m - 1]}', null, store.balanceEndOfMonth, bold: true),
          const SizedBox(height: 12),
          Text(
              'Recalculé à chaque dépense : quand tu dépenses, ton solde baisse tout de suite, et le rythme estimé '
              's’ajuste à ta façon de dépenser.',
              style: t.ts(12, t.wSemi, t.muted).copyWith(height: 1.45)),
          const SizedBox(height: 16),
          SecondaryButton('Corriger mon solde ou mon salaire', onTap: () {
            Navigator.pop(ctx);
            editAccount(context);
          }),
        ]);
      });
}
