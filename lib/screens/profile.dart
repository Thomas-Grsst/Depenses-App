import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../format.dart';
import '../icons.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../ui.dart';
import '../widgets.dart';
import 'account.dart';
import 'budget.dart';
import 'categories.dart';
import 'roundup.dart';
import 'simulation.dart';
import 'simulations.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _editGoal(BuildContext context, [Goal? goal]) async {
    final store = StoreScope.read(context);
    final name = TextEditingController(text: goal?.name ?? '');
    final target = TextEditingController(text: goal == null ? '' : amountInput(goal.target));
    final saved = TextEditingController(text: goal == null ? '' : amountInput(goal.saved));
    final monthly = TextEditingController(text: goal == null ? '' : amountInput(goal.monthly));
    final res = await showSheet<String>(context,
        title: goal == null ? 'Nouvel objectif' : 'Objectif',
        builder: (ctx) {
          final t = TkScope.of(ctx);
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Field('Nom', controller: name, hint: 'Ex. Vacances, Voiture, Coussin de sécurité'),
            const SizedBox(height: 14),
            Field('Montant visé', controller: target, number: true, hint: 'Ex. 1 500'),
            const SizedBox(height: 14),
            Field('Déjà mis de côté', controller: saved, number: true, hint: '0'),
            const SizedBox(height: 14),
            Field('Épargne par mois', controller: monthly, number: true, hint: 'Ex. 150'),
            const SizedBox(height: 20),
            PrimaryButton('Enregistrer', onTap: () => Navigator.pop(ctx, 'save')),
            if (goal != null) ...[
              const SizedBox(height: 10),
              SecondaryButton('Supprimer l’objectif', color: t.warn, onTap: () => Navigator.pop(ctx, 'delete')),
            ],
          ]);
        });
    if (res == 'delete' && goal != null) {
      store.goals.remove(goal);
      store.commit();
    } else if (res == 'save') {
      final tg = parseAmount(target.text) ?? 0;
      if (tg <= 0) return;
      final n = name.text.trim().isEmpty ? 'Objectif' : name.text.trim();
      final sv = parseAmount(saved.text) ?? 0, mo = parseAmount(monthly.text) ?? 0;
      if (goal == null) {
        store.goals.add(Goal(id: newId(), name: n, target: tg, saved: sv, monthly: mo));
      } else {
        goal
          ..name = n
          ..target = tg
          ..saved = sv
          ..monthly = mo;
      }
      store.commit();
    }
  }

  Future<void> _labels(BuildContext context) async {
    final store = StoreScope.read(context);
    await showSheet<void>(context,
        title: 'Libellés',
        builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
              final t = TkScope.of(ctx);
              final c = TextEditingController();
              return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('Les libellés regroupent des dépenses de catégories différentes (ex. « Vacances »). '
                    'Supprimer un libellé ne supprime pas les dépenses.',
                    style: t.ts(13, t.wBody, t.muted).copyWith(height: 1.4)),
                const SizedBox(height: 10),
                for (final l in [...store.labels])
                  Ruled(
                    child: Row(children: [
                      Expanded(child: Text(l, style: t.ts(15, t.wItem))),
                      Text('${store.expenses.where((e) => e.labels.contains(l)).length}', style: t.ts(13, t.wSemi, t.muted)),
                      Pressable(
                        onTap: () {
                          store.labels.remove(l);
                          for (final e in store.expenses) {
                            e.labels.remove(l);
                          }
                          for (final r in store.recs) {
                            r.labels.remove(l);
                          }
                          store.commit();
                          set(() {});
                        },
                        semantics: 'Supprimer $l',
                        child: Padding(padding: const EdgeInsets.only(left: 14), child: Ico('trash', size: 18, color: t.warn)),
                      ),
                    ]),
                  ),
                const SizedBox(height: 16),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Expanded(child: Field('Nouveau libellé', controller: c, hint: 'Ex. Vacances')),
                  const SizedBox(width: 10),
                  SmallButton('Ajouter', primary: true, onTap: () {
                    final v = c.text.trim();
                    if (v.isNotEmpty && !store.labels.contains(v)) {
                      store.labels.add(v);
                      store.commit();
                      set(() {});
                    }
                  }),
                ]),
              ]);
            }));
  }

  @override
  Widget build(BuildContext context) {
    final t = TkScope.of(context);
    final g = t.graphite;
    final store = StoreScope.of(context);
    final st = store.settings;
    final name = st.name;

    final avatar = Container(
      width: g ? 60 : 56,
      height: g ? 60 : 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: g ? Colors.transparent : t.hero,
        shape: BoxShape.circle,
        border: g ? Border.all(color: t.lineStrong) : null,
      ),
      child: Text(name.isEmpty ? '?' : name[0].toUpperCase(),
          style: t.ts(g ? 24 : 22, g ? FontWeight.w300 : FontWeight.w800, g ? t.ink : t.heroAccent)),
    );

    final head = Pressable(
      onTap: () => editAccount(context, withName: true),
      child: Row(children: [
        avatar,
        SizedBox(width: g ? 16 : 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: t.ts(g ? 28 : 24, g ? FontWeight.w300 : FontWeight.w800).copyWith(letterSpacing: -0.5)),
            Text(
                st.income > 0
                    ? 'Salaire ${eur0(st.income)} le ${st.payDay == 1 ? '1er' : st.payDay} du mois'
                    : 'Touche pour indiquer ton salaire et ton solde',
                style: t.ts(13, t.wSemi, t.muted)),
          ]),
        ),
        Ico('edit', size: 18, color: t.muted),
      ]),
    );

    Widget goalW(Goal goal) {
      final ratio = goal.target > 0 ? goal.saved / goal.target : 0.0;
      final m = goal.monthsWith(goal.monthly);
      final sub = goal.remaining <= 0
          ? 'Objectif atteint, bravo !'
          : goal.monthly <= 0
              ? 'Indique combien tu mets de côté par mois'
              : '${eur0(goal.monthly)} / mois → ${goalWhen(m)}';
      return Pressable(
        onTap: () => _editGoal(context, goal),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Expanded(child: Text(goal.name, style: t.ts(g ? 15 : 16, g ? FontWeight.w400 : FontWeight.w800))),
            g
                ? Text.rich(TextSpan(children: [
                    TextSpan(text: num0(goal.saved)),
                    TextSpan(text: ' / ${num0(goal.target)}', style: TextStyle(color: t.faint)),
                  ]), style: t.mono(13))
                : Text.rich(TextSpan(children: [
                    TextSpan(text: eur0(goal.saved)),
                    TextSpan(text: ' / ${eur0(goal.target)}', style: TextStyle(color: t.muted, fontWeight: FontWeight.w600)),
                  ]), style: t.ts(14, FontWeight.w700)),
          ]),
          SizedBox(height: g ? 12 : 10),
          Bar(ratio, height: 10, dot: true),
          SizedBox(height: g ? 12 : 8),
          Text(sub, style: t.ts(13, t.wSemi, t.muted)),
        ]),
      );
    }

    final goals = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionLabel('Objectifs', trailing: TextLink(g ? '+ Nouveau' : '+ Nouvel objectif', onTap: () => _editGoal(context))),
      SizedBox(height: g ? 6 : 8),
      if (store.goals.isEmpty)
        Panel(
          child: Ruled(
            bottom: true,
            child: Text('Fixe-toi un objectif d’épargne (vacances, voiture…) : l’app te dira quand tu l’atteindras.',
                style: t.ts(14, t.wBody, t.muted).copyWith(height: 1.45)),
          ),
        ),
      if (g)
        Column(children: [
          for (var i = 0; i < store.goals.length; i++)
            Ruled(padV: 16, bottom: i == store.goals.length - 1, child: goalW(store.goals[i])),
        ])
      else
        ...spaced([for (final goal in store.goals) Panel(child: goalW(goal))], 8),
    ]);

    void set(void Function() f) {
      f();
      store.commit();
    }

    final palettes = const [
      ('menthe', Color(0xFF0F8A5F), 'Menthe'),
      ('ocean', Color(0xFF1259C3), 'Océan'),
      ('prune', Color(0xFF6D3FD0), 'Prune'),
      ('terracotta', Color(0xFFA9471F), 'Terracotta'),
    ];

    final appearance = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionLabel('Apparence'),
      const SizedBox(height: 8),
      Segmented<String>(
        options: const [('menthe', 'Menthe'), ('graphite', 'Graphite')],
        value: st.style,
        onChanged: (v) => set(() => st.style = v),
      ),
      const SizedBox(height: 10),
      Segmented<String>(
        options: const [('light', 'Clair'), ('dark', 'Sombre'), ('auto', 'Auto')],
        value: st.themeMode,
        onChanged: (v) => set(() => st.themeMode = v),
      ),
      if (!g) ...[
        const SizedBox(height: 12),
        Row(children: [
          for (final p in palettes)
            Expanded(
              child: Pressable(
                onTap: () => set(() => st.palette = p.$1),
                semantics: 'Palette ${p.$3}',
                child: Column(children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: p.$2,
                      shape: BoxShape.circle,
                      border: Border.all(color: st.palette == p.$1 ? t.ink : Colors.transparent, width: 2.5),
                    ),
                    child: st.palette == p.$1 ? Center(child: Ico('check', size: 16, color: Colors.white, stroke: 2.6)) : null,
                  ),
                  const SizedBox(height: 4),
                  Text(p.$3, style: t.ts(11, FontWeight.w600, t.muted)),
                ]),
              ),
            ),
        ]),
      ],
    ]);

    final settings = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionLabel('Réglages'),
      SizedBox(height: g ? 6 : 8),
      SettingGroup([
        SettingRow('Compte & salaire',
            value: store.hasBalance ? eur(store.balance) : 'À définir',
            chevron: true,
            onTap: () => editAccount(context)),
        SettingRow('Budget & enveloppes', chevron: true, onTap: () => go(context, const BudgetScreen())),
        SettingRow('Mes simulations',
            value: store.sims.isEmpty ? null : '${store.sims.length}',
            chevron: true,
            onTap: () => go(context, store.sims.isEmpty ? const SimulationScreen() : const SimulationsScreen())),
        SettingRow('Catégories', value: '${cats.length}', chevron: true, onTap: () => manageCategories(context)),
        SettingRow('Libellés', value: '${store.labels.length}', chevron: true, onTap: () => _labels(context)),
        SettingRow('Arrondis à l’euro supérieur',
            value: store.roundUpTotal > 0 ? '+${eur(store.roundUpTotal)}' : (st.roundUp ? 'Activé' : 'Désactivé'),
            chevron: true,
            onTap: () => showRoundUp(context)),
        SettingRow('Alertes intelligentes',
            trailing: Toggle(value: st.alerts, onChanged: (v) => set(() => st.alerts = v))),
        SettingRow('Détection des abonnements',
            trailing: Toggle(value: st.detection, onChanged: (v) => set(() => st.detection = v))),
        SettingRow('Devise', value: 'Euro (€)'),
        SettingRow('Exporter mes données', value: 'CSV', onTap: () async {
          await Clipboard.setData(ClipboardData(text: store.toCsv()));
          if (context.mounted) toast(context, 'CSV copié dans le presse-papiers (${store.expenses.length} dépenses)');
        }),
        SettingRow('Effacer toutes les données', color: t.warn, onTap: () async {
          if (await confirm(context, 'Tout effacer ?',
              'Dépenses, récurrences, budget, objectifs et simulations seront supprimés définitivement.',
              ok: 'Tout effacer')) {
            store.resetAll();
          }
        }),
      ]),
    ]);

    return PageList(gap: g ? 30 : 16, children: [head, goals, appearance, settings]);
  }
}
