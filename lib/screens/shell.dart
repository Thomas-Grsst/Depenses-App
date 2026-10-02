import 'package:flutter/material.dart';

import '../icons.dart';
import '../theme.dart';
import '../ui.dart';
import 'add_expense.dart';
import 'expenses.dart';
import 'home.dart';
import 'profile.dart';
import 'recurrences.dart';

/// Permet aux pages de changer d'onglet ("Tout voir").
class ShellNav extends InheritedWidget {
  final void Function(int) goTab;
  const ShellNav({super.key, required this.goTab, required super.child});

  static void tab(BuildContext context, int i) =>
      context.getInheritedWidgetOfExactType<ShellNav>()?.goTab(i);

  @override
  bool updateShouldNotify(ShellNav old) => false;
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _i = 0;

  static const _tabs = [
    ('home', 'Accueil'),
    ('list', 'Dépenses'),
    ('repeat', 'Récurrences'),
    ('user', 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = TkScope.of(context);
    return PopScope(
      canPop: _i == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _i = 0);
      },
      child: ShellNav(
        goTab: (i) => setState(() => _i = i),
        child: Scaffold(
          backgroundColor: t.bg,
          body: IndexedStack(index: _i, children: const [
            HomeScreen(),
            ExpensesScreen(),
            RecurrencesScreen(),
            ProfileScreen(),
          ]),
          bottomNavigationBar: _NavBar(
            index: _i,
            onTap: (i) => setState(() => _i = i),
            onAdd: () => go(context, const AddExpenseScreen()),
          ),
        ),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  final VoidCallback onAdd;
  const _NavBar({required this.index, required this.onTap, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final t = TkScope.of(context);
    final inset = MediaQuery.of(context).padding.bottom;
    Widget item(int i) {
      final on = i == index;
      final (icon, label) = _ShellState._tabs[i];
      if (t.graphite) {
        return Expanded(
          child: Pressable(
            onTap: () => onTap(i),
            semantics: label,
            child: SizedBox(
              height: 56,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Ico(icon, size: 22, color: on ? t.ink : t.faint),
                const SizedBox(height: 5),
                Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(color: on ? t.accent : Colors.transparent, shape: BoxShape.circle)),
              ]),
            ),
          ),
        );
      }
      return Expanded(
        child: Pressable(
          onTap: () => onTap(i),
          child: SizedBox(
            height: 56,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Ico(icon, size: 22, color: on ? t.ink : t.muted),
              const SizedBox(height: 3),
              Text(label, style: t.ts(11, on ? FontWeight.w800 : FontWeight.w600, on ? t.ink : t.muted)),
            ]),
          ),
        ),
      );
    }

    final fab = Pressable(
      onTap: onAdd,
      semantics: 'Ajouter une dépense',
      child: Container(
        width: t.graphite ? 48 : 56,
        height: t.graphite ? 48 : 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: t.fab,
          shape: BoxShape.circle,
          boxShadow: t.graphite
              ? null
              : [BoxShadow(color: const Color(0x470D2B24), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Ico('plus', size: t.graphite ? 22 : 24, color: t.fabInk, stroke: t.graphite ? 1.8 : 2.2),
      ),
    );

    return Container(
      padding: EdgeInsets.only(bottom: inset, left: t.graphite ? 16 : 8, right: t.graphite ? 16 : 8),
      decoration: BoxDecoration(
        color: t.graphite ? t.bg : t.card,
        border: t.graphite ? Border(top: BorderSide(color: t.line)) : null,
      ),
      child: SizedBox(
        height: 64,
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          item(0),
          item(1),
          SizedBox(
            width: 72,
            child: Transform.translate(offset: Offset(0, t.graphite ? 0 : -14), child: Center(child: fab)),
          ),
          item(2),
          item(3),
        ]),
      ),
    );
  }
}
