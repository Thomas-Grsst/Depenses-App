import 'package:flutter/material.dart';

import '../format.dart';
import '../icons.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../ui.dart';
import 'budget.dart';
import 'categories.dart';

/// Ajout / modification d'une dépense ou d'une récurrence.
class AddExpenseScreen extends StatefulWidget {
  final Expense? expense;
  final Recurrence? rec;
  final bool startRecurring;
  const AddExpenseScreen({super.key, this.expense, this.rec, this.startRecurring = false});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  late String _mode; // occ | rec
  late String _freq;
  late String _cat;
  late DateTime _date;
  late Set<String> _labels;
  bool _catTouched = false;
  final _amount = TextEditingController();
  final _name = TextEditingController();

  bool get _editing => widget.expense != null || widget.rec != null;

  @override
  void initState() {
    super.initState();
    final e = widget.expense, r = widget.rec;
    _mode = r != null || widget.startRecurring ? 'rec' : 'occ';
    _freq = r?.freq ?? 'month';
    _cat = e?.cat ?? r?.cat ?? 'ali';
    _date = e?.date ?? r?.start ?? dOnly(DateTime.now());
    _labels = {...?e?.labels, ...?r?.labels};
    _catTouched = _editing;
    if (e != null) {
      _amount.text = amountInput(e.amount);
      _name.text = e.name;
    } else if (r != null) {
      _amount.text = amountInput(r.amount);
      _name.text = r.name;
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _name.dispose();
    super.dispose();
  }

  double? get _value {
    final v = parseAmount(_amount.text);
    return v == null || v <= 0 ? null : v;
  }

  void _onName(String v) {
    if (!_catTouched) {
      final g = guessCat(v);
      if (g != null) _cat = g;
    }
    setState(() {});
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 5),
      helpText: _mode == 'rec' ? 'Première échéance' : 'Date de la dépense',
    );
    if (d != null) setState(() => _date = dOnly(d));
  }

  Future<void> _addLabel() async {
    final c = TextEditingController();
    final res = await showSheet<String>(context,
        title: 'Nouveau libellé',
        builder: (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Field('Libellé', controller: c, hint: 'Ex. Vacances, Bébé, Bureau…', autofocus: true),
              const SizedBox(height: 18),
              PrimaryButton('Ajouter', onTap: () => Navigator.pop(ctx, c.text.trim())),
            ]));
    if (res != null && res.isNotEmpty && mounted) {
      final store = StoreScope.read(context);
      if (!store.labels.contains(res)) store.labels.add(res);
      setState(() => _labels.add(res));
    }
  }

  void _save() {
    final store = StoreScope.read(context);
    final amount = _value!;
    final name = _name.text.trim().isEmpty ? catOf(_cat).name : _name.text.trim();
    final labels = _labels.toList();
    String msg;
    if (widget.expense != null) {
      final e = widget.expense!
        ..name = name
        ..amount = amount
        ..date = _date
        ..cat = _cat
        ..labels = labels;
      store.updateExpense(e);
      msg = 'Dépense modifiée';
    } else if (widget.rec != null) {
      final r = widget.rec!
        ..name = name
        ..amount = amount
        ..cat = _cat
        ..freq = _freq
        ..start = _date
        ..labels = labels;
      store.updateRecurrence(r);
      msg = 'Récurrence modifiée';
    } else if (_mode == 'rec') {
      store.addRecurrence(Recurrence(
          id: newId(), name: name, amount: amount, cat: _cat, freq: _freq, start: _date, labels: labels));
      msg = 'Récurrence créée';
    } else {
      store.addExpense(Expense(id: newId(), name: name, amount: amount, date: _date, cat: _cat, labels: labels));
      msg = 'Dépense enregistrée';
    }
    Navigator.pop(context);
    toast(context, msg);
  }

  Future<void> _delete() async {
    final store = StoreScope.read(context);
    if (widget.expense != null) {
      if (!await confirm(context, 'Supprimer cette dépense ?', '« ${widget.expense!.name} » sera retirée de l’historique.')) {
        return;
      }
      store.deleteExpense(widget.expense!.id);
    } else if (widget.rec != null) {
      if (!await confirm(context, 'Supprimer cette récurrence ?',
          'Les prochaines échéances ne seront plus créées. Les dépenses déjà passées restent dans l’historique.')) {
        return;
      }
      store.deleteRecurrence(widget.rec!.id);
    }
    if (mounted) Navigator.pop(context);
  }

  (String, String) _ruleTexts() {
    final d = _date;
    final rule = switch (_freq) {
      'week' => 'Chaque ${daysFr[d.weekday - 1]}',
      'year' => 'Chaque ${d.day == 1 ? '1er' : d.day} ${monthsFr[d.month - 1]}',
      _ => 'Le ${d.day} de chaque mois',
    };
    final tmp = Recurrence(id: '', name: '', amount: 0, cat: _cat, freq: _freq, start: d);
    final today = dOnly(DateTime.now());
    final next = d.isAfter(today) ? d : tmp.nextAfter(today);
    String fmt(DateTime x) => x.year != today.year ? '${shortDate(x)} ${x.year}' : shortDate(x);
    return (rule, next == null ? '—' : fmt(next));
  }

  @override
  Widget build(BuildContext context) {
    final t = TkScope.of(context);
    final store = StoreScope.of(context);
    final g = t.graphite;
    final isRec = _mode == 'rec';
    final title = widget.expense != null
        ? 'Modifier la dépense'
        : widget.rec != null
            ? 'Récurrence'
            : 'Nouvelle dépense';
    final cta = widget.expense != null || widget.rec != null
        ? 'Enregistrer les modifications'
        : isRec
            ? 'Créer la récurrence'
            : 'Enregistrer';
    final allLabels = {...store.labels, ..._labels}.toList();

    final header = Row(children: [
      RoundButton('close', semantics: 'Fermer', onTap: () => Navigator.pop(context)),
      Expanded(
          child: Text(title,
              textAlign: TextAlign.center, style: t.ts(g ? 15 : 16, g ? FontWeight.w500 : FontWeight.w800))),
      _editing
          ? Pressable(
              onTap: _delete,
              semantics: 'Supprimer',
              child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Align(
                      alignment: g ? Alignment.centerRight : Alignment.center,
                      child: Ico('trash', size: 20, color: t.warn))))
          : const SizedBox(width: 44),
    ]);

    final amountField = Column(children: [
      if (!g) Text('Montant', style: t.ts(13, FontWeight.w600, t.muted)),
      IntrinsicWidth(
        child: TextField(
          controller: _amount,
          autofocus: !_editing,
          textAlign: TextAlign.center,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
          style: t.ts(g ? 72 : 52, g ? FontWeight.w300 : FontWeight.w800).copyWith(letterSpacing: g ? -2.8 : -1.5, height: 1.1),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: '0,00',
            hintStyle: t.ts(g ? 72 : 52, g ? FontWeight.w300 : FontWeight.w800, t.off).copyWith(letterSpacing: -1.5),
            suffixText: ' €',
            suffixStyle: t.ts(g ? 26 : 40, g ? FontWeight.w300 : FontWeight.w800, g ? t.muted : t.ink),
            isDense: true,
          ),
        ),
      ),
    ]);

    Widget fieldRow(String label, Widget child, {VoidCallback? onTap, bool last = false}) {
      final side = BorderSide(color: t.line);
      return Pressable(
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(minHeight: g ? 54 : 52),
          decoration: BoxDecoration(
              border: g
                  ? Border(top: side, bottom: last ? side : BorderSide.none)
                  : Border(bottom: last ? BorderSide.none : side)),
          child: Row(children: [
            SizedBox(
                width: g ? 72 : 84,
                child: Text(g ? label.toUpperCase() : label, style: g ? t.label() : t.ts(13, FontWeight.w600, t.muted))),
            const SizedBox(width: 12),
            Expanded(child: child),
          ]),
        ),
      );
    }

    final fields = Panel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(children: [
        fieldRow(
          'Nom',
          TextField(
            controller: _name,
            onChanged: _onName,
            textCapitalization: TextCapitalization.sentences,
            style: t.ts(16, g ? FontWeight.w400 : FontWeight.w700),
            decoration: InputDecoration.collapsed(
                hintText: 'Ex. Courses, Netflix, Loyer…', hintStyle: t.ts(16, FontWeight.w400, t.faint)),
          ),
        ),
        fieldRow(
          isRec ? 'Début' : 'Date',
          Row(children: [
            Expanded(child: Text(longDate(_date), style: t.ts(16, g ? FontWeight.w400 : FontWeight.w700))),
            Ico('calendar', size: 18, color: t.muted),
          ]),
          onTap: _pickDate,
          last: !g || !isRec,
        ),
      ]),
    );

    final (ruleText, nextText) = _ruleTexts();
    final freqBlock = Panel(
      child: Container(
        padding: g ? const EdgeInsets.symmetric(vertical: 16) : EdgeInsets.zero,
        decoration: g ? BoxDecoration(border: Border(bottom: BorderSide(color: t.line))) : null,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(g ? 'RÉPÉTITION' : 'Répétition', style: t.label()),
          const SizedBox(height: 10),
          Row(
            children: spaced([
              for (final f in const [('week', 'Semaine'), ('month', 'Mois'), ('year', 'Année')])
                Expanded(child: _FreqButton(label: f.$2, on: _freq == f.$1, onTap: () => setState(() => _freq = f.$1))),
            ], 8),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: Text(ruleText, style: t.ts(g ? 13 : 14, t.wSemi, g ? t.muted : t.ink))),
            Text('Prochaine : $nextText', style: t.ts(g ? 13 : 14, t.wSemi, g ? t.muted : t.mint)),
          ]),
        ]),
      ),
    );

    void pick(String key) => setState(() {
          _cat = key;
          _catTouched = true;
        });
    Future<void> newCat() async {
      final k = await editCategory(context);
      if (k != null) pick(k);
    }

    final cs = store.stats.perCat[_cat];
    final envHint = Pressable(
      onTap: () => BudgetScreen.editEnvelope(context, _cat),
      child: Padding(
        padding: const EdgeInsets.only(top: 10, left: 2),
        child: Row(children: [
          Ico('tag', size: 14, color: t.muted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              cs != null && cs.budget > 0
                  ? 'Budget ${catOf(_cat).name} ce mois : ${eur(cs.spent)} / ${eurAuto(cs.budget)}'
                  : 'Pas de budget prévu pour ${catOf(_cat).name} · Définir',
              style: t.ts(12, t.wSemi, cs != null && cs.budget > 0 && cs.spent > cs.budget ? t.warn : t.muted),
            ),
          ),
        ]),
      ),
    );

    final catGrid = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionLabel('Catégorie'),
      SizedBox(height: g ? 14 : 10),
      GridView.count(
        crossAxisCount: g ? 5 : 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: g ? 12 : 8,
        crossAxisSpacing: g ? 4 : 8,
        childAspectRatio: g ? 0.85 : 1.45,
        padding: EdgeInsets.zero,
        children: [
          for (final c in cats)
            Pressable(
              onTap: () => pick(c.key),
              onLongPress: c.custom ? () => editCategory(context, c) : null,
              semantics: c.name,
              child: g
                  ? Column(children: [
                      CatIcon(cat: c.key, size: 44, selected: _cat == c.key),
                      const SizedBox(height: 6),
                      Text(c.short, maxLines: 1, style: t.ts(10, FontWeight.w400, _cat == c.key ? t.ink : t.muted)),
                    ])
                  : AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: t.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _cat == c.key ? t.ink : Colors.transparent, width: 2),
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        CatIcon(cat: c.key, size: 36),
                        const SizedBox(height: 6),
                        Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.ts(12, FontWeight.w700)),
                      ]),
                    ),
            ),
          Pressable(
            onTap: newCat,
            semantics: 'Nouvelle catégorie',
            child: g
                ? Column(children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: t.faint)),
                      child: Ico('plus', size: 20, color: t.muted),
                    ),
                    const SizedBox(height: 6),
                    Text('Nouvelle', style: t.ts(10, FontWeight.w400, t.muted)),
                  ])
                : Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: t.off, width: 1.5),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Ico('plus', size: 22, color: t.muted),
                      const SizedBox(height: 6),
                      Text('Nouvelle', style: t.ts(12, FontWeight.w700, t.muted)),
                    ]),
                  ),
          ),
        ],
      ),
      envHint,
    ]);

    final labelsBlock = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionLabel('Libellés'),
      SizedBox(height: g ? 14 : 10),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final l in allLabels)
          PillChip(l,
              selected: _labels.contains(l),
              onTap: () => setState(() => _labels.contains(l) ? _labels.remove(l) : _labels.add(l))),
        PillChip(g ? '+ Libellé' : '+ Ajouter un libellé', dashed: true, onTap: _addLabel),
      ]),
    ]);

    final preview = _name.text.trim().isEmpty
        ? null
        : Row(children: [
            CatIcon(cat: _cat, name: _name.text, size: 28),
            const SizedBox(width: 10),
            Expanded(
                child: Text('Icône choisie automatiquement d’après le nom', style: t.ts(12, t.wSemi, t.muted))),
          ]);

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(t.pad, 8, t.pad, 24),
              children: spaced([
                header,
                if (!_editing)
                  Segmented<String>(
                    options: const [('occ', 'Occasionnelle'), ('rec', 'Récurrente')],
                    value: _mode,
                    center: true,
                    onChanged: (v) => setState(() => _mode = v),
                  ),
                amountField,
                Column(children: [
                  fields,
                  if (isRec) ...[SizedBox(height: g ? 0 : 16), freqBlock],
                ]),
                ?preview,
                catGrid,
                labelsBlock,
              ], g ? 26 : 16),
            ),
          ),
          Container(
            color: t.bg,
            padding: EdgeInsets.fromLTRB(t.pad, 12, t.pad, 16),
            child: PrimaryButton(cta, onTap: _value == null ? null : _save),
          ),
        ]),
      ),
    );
  }
}

class _FreqButton extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback onTap;
  const _FreqButton({required this.label, required this.on, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = TkScope.of(context);
    final g = t.graphite;
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: g ? (on ? t.fab : Colors.transparent) : (on ? t.mintSoft : t.chip),
          borderRadius: BorderRadius.circular(g ? 22 : 12),
          border: g ? Border.all(color: on ? t.fab : t.lineStrong) : null,
        ),
        child: Text(label,
            style: t.ts(14, g ? FontWeight.w400 : FontWeight.w700, g ? (on ? t.fabInk : t.ink) : (on ? t.mint : t.muted))),
      ),
    );
  }
}
