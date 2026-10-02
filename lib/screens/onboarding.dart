import 'package:flutter/material.dart';

import '../format.dart';
import '../store.dart';
import '../theme.dart';
import '../ui.dart';
import 'account.dart';

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});
  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  final _name = TextEditingController();
  final _income = TextEditingController();
  final _balance = TextEditingController();
  int _payDay = 1;

  @override
  void dispose() {
    _name.dispose();
    _income.dispose();
    _balance.dispose();
    super.dispose();
  }

  void _start() {
    final store = StoreScope.read(context);
    store.settings.name = _name.text.trim();
    store.settings.income = parseAmount(_income.text) ?? 0;
    store.settings.payDay = _payDay;
    final b = parseAmount(_balance.text);
    if (b != null) {
      store.setBalance(b);
    } else {
      store.commit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = TkScope.of(context);
    final store = StoreScope.of(context);
    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(t.pad, 48, t.pad, 24),
          children: [
            Text(t.graphite ? 'DÉPENSES' : 'Bienvenue', style: t.graphite ? t.label() : t.ts(14, FontWeight.w700, t.mint)),
            const SizedBox(height: 10),
            Text(
              'Simple au premier regard, puissante quand tu analyses.',
              style: t.ts(t.graphite ? 34 : 32, t.graphite ? FontWeight.w300 : FontWeight.w800)
                  .copyWith(height: 1.15, letterSpacing: -0.6),
            ),
            const SizedBox(height: 12),
            Text('Tes données restent sur ton téléphone.', style: t.ts(15, t.wBody, t.muted)),
            const SizedBox(height: 36),
            Field('Ton prénom', controller: _name, hint: 'Ex. Camille', onChanged: (_) => setState(() {})),
            const SizedBox(height: 18),
            Field('Solde actuel de ton compte', controller: _balance, hint: 'Ex. 1 250,40', number: true),
            const SizedBox(height: 8),
            Text('L’app le tiendra à jour : − tes dépenses, + ton salaire.', style: t.ts(12, t.wSemi, t.muted)),
            const SizedBox(height: 18),
            Field('Salaire mensuel (facultatif)', controller: _income, hint: 'Ex. 2 400', number: true),
            const SizedBox(height: 8),
            Text('Sert au solde, au « reste à vivre » et aux simulations.', style: t.ts(12, t.wSemi, t.muted)),
            const SizedBox(height: 18),
            PayDayPicker(value: _payDay, onChanged: (v) => setState(() => _payDay = v)),
            const SizedBox(height: 32),
            SectionLabel('Style'),
            const SizedBox(height: 10),
            Segmented<String>(
              options: const [('menthe', 'Menthe'), ('graphite', 'Graphite')],
              value: store.settings.style,
              onChanged: (v) {
                store.settings.style = v;
                store.commit();
              },
            ),
            const SizedBox(height: 40),
            PrimaryButton('Commencer', onTap: _name.text.trim().isEmpty ? null : _start),
          ],
        ),
      ),
    );
  }
}
