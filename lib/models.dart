import 'dart:math';

/// Catégorie : clé, nom, nom court, icône par défaut. Les catégories perso ont une couleur (index).
class Cat {
  final String key, name, short, kind;
  final int? color;
  const Cat(this.key, this.name, this.short, this.kind, {this.color});

  bool get custom => color != null;

  Map<String, dynamic> toJson() => {'key': key, 'name': name, 'kind': kind, 'color': color};
  factory Cat.fromJson(Map<String, dynamic> j) =>
      Cat.custom(j['key'], j['name'], j['kind'] ?? 'dots', (j['color'] as num?)?.toInt() ?? 0);

  factory Cat.custom(String key, String name, String kind, int color) =>
      Cat(key, name, name.length > 8 ? '${name.substring(0, 7)}.' : name, kind, color: color);
}

const defaultCats = [
  Cat('log', 'Logement', 'Logem.', 'home'),
  Cat('ali', 'Alimentation', 'Alim.', 'food'),
  Cat('tra', 'Transport', 'Transp.', 'car'),
  Cat('loi', 'Loisirs', 'Loisirs', 'film'),
  Cat('san', 'Santé', 'Santé', 'heart'),
  Cat('aut', 'Autres', 'Autres', 'dots'),
];

/// Toutes les catégories (par défaut + perso, « Autres » toujours en dernier).
List<Cat> cats = [...defaultCats];
List<Cat> get customCats => cats.where((c) => c.custom).toList();

void setCustomCats(List<Cat> custom) {
  cats = [...defaultCats.take(defaultCats.length - 1), ...custom, defaultCats.last];
}

Cat catOf(String key) => cats.firstWhere((c) => c.key == key, orElse: () => defaultCats.last);

final _rnd = Random();
String newId() =>
    DateTime.now().microsecondsSinceEpoch.toRadixString(36) + _rnd.nextInt(1 << 20).toRadixString(36);

DateTime _d(String s) => DateTime.parse(s);
String _s(DateTime d) => d.toIso8601String().substring(0, 10);
double _n(dynamic v) => (v as num).toDouble();

class Expense {
  String id, name, cat;
  double amount;
  DateTime date;
  List<String> labels;
  String? recId;

  Expense({
    required this.id,
    required this.name,
    required this.amount,
    required this.date,
    required this.cat,
    List<String>? labels,
    this.recId,
  }) : labels = labels ?? [];

  bool get isRec => recId != null;

  Map<String, dynamic> toJson() => {
        'id': id, 'name': name, 'amount': amount, 'date': _s(date), 'cat': cat,
        'labels': labels, 'recId': recId,
      };

  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
        id: j['id'], name: j['name'], amount: _n(j['amount']), date: _d(j['date']),
        cat: j['cat'], labels: List<String>.from(j['labels'] ?? const []), recId: j['recId'],
      );
}

/// freq : 'week' | 'month' | 'year'
class Recurrence {
  String id, name, cat, freq;
  double amount;
  DateTime start;
  List<String> labels;
  DateTime? lastGen;

  Recurrence({
    required this.id,
    required this.name,
    required this.amount,
    required this.cat,
    required this.freq,
    required this.start,
    List<String>? labels,
    this.lastGen,
  }) : labels = labels ?? [];

  double get monthly => monthlyOf(amount, freq);

  static double monthlyOf(double amount, String freq) => switch (freq) {
        'week' => amount * 52 / 12,
        'year' => amount / 12,
        _ => amount,
      };

  Map<String, dynamic> toJson() => {
        'id': id, 'name': name, 'amount': amount, 'cat': cat, 'freq': freq, 'start': _s(start),
        'labels': labels, 'lastGen': lastGen == null ? null : _s(lastGen!),
      };

  factory Recurrence.fromJson(Map<String, dynamic> j) => Recurrence(
        id: j['id'], name: j['name'], amount: _n(j['amount']), cat: j['cat'], freq: j['freq'],
        start: _d(j['start']), labels: List<String>.from(j['labels'] ?? const []),
        lastGen: j['lastGen'] == null ? null : _d(j['lastGen']),
      );

  /// Occurrences entre [from] et [to] inclus.
  Iterable<DateTime> occurrences(DateTime from, DateTime to) sync* {
    for (var k = 0; k < 5000; k++) {
      final DateTime d;
      switch (freq) {
        case 'week':
          d = DateTime(start.year, start.month, start.day + 7 * k);
        case 'year':
          final y = start.year + k;
          d = DateTime(y, start.month, min(start.day, DateTime(y, start.month + 1, 0).day));
        default:
          final m = DateTime(start.year, start.month + k, 1);
          d = DateTime(m.year, m.month, min(start.day, DateTime(m.year, m.month + 1, 0).day));
      }
      if (d.isAfter(to)) return;
      if (!d.isBefore(from)) yield d;
    }
  }

  DateTime? nextAfter(DateTime day) {
    for (final d in occurrences(day.add(const Duration(days: 1)), DateTime(day.year + 2, 12, 31))) {
      return d;
    }
    return null;
  }
}

class LabelEnvelope {
  String id, name, label;
  double amount;
  LabelEnvelope({required this.id, required this.name, required this.label, required this.amount});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'label': label, 'amount': amount};
  factory LabelEnvelope.fromJson(Map<String, dynamic> j) =>
      LabelEnvelope(id: j['id'], name: j['name'], label: j['label'], amount: _n(j['amount']));
}

class Goal {
  String id, name;
  double target, saved, monthly;
  Goal({required this.id, required this.name, required this.target, required this.saved, required this.monthly});

  double get remaining => max(0, target - saved);

  /// Nombre de mois pour atteindre l'objectif avec une épargne mensuelle donnée.
  int? monthsWith(double perMonth) {
    if (remaining <= 0) return 0;
    if (perMonth <= 0.004) return null;
    return (remaining / perMonth).ceil();
  }

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'target': target, 'saved': saved, 'monthly': monthly};
  factory Goal.fromJson(Map<String, dynamic> j) => Goal(
      id: j['id'], name: j['name'], target: _n(j['target']), saved: _n(j['saved']), monthly: _n(j['monthly']));
}

/// Une hypothèse de simulation : modifier / supprimer une récurrence, ou ajouter une charge.
class Hyp {
  String? recId;
  String name, cat, freq;
  double oldAmount, newAmount;
  bool keep;

  Hyp({
    this.recId,
    required this.name,
    required this.cat,
    required this.freq,
    required this.oldAmount,
    required this.newAmount,
    this.keep = true,
  });

  bool get isNew => recId == null;
  double get effective => keep ? newAmount : 0;
  double get delta => Recurrence.monthlyOf(effective, freq) - Recurrence.monthlyOf(oldAmount, freq);

  Hyp copy() => Hyp(
      recId: recId, name: name, cat: cat, freq: freq, oldAmount: oldAmount, newAmount: newAmount, keep: keep);

  Map<String, dynamic> toJson() => {
        'recId': recId, 'name': name, 'cat': cat, 'freq': freq,
        'oldAmount': oldAmount, 'newAmount': newAmount, 'keep': keep,
      };
  factory Hyp.fromJson(Map<String, dynamic> j) => Hyp(
        recId: j['recId'], name: j['name'], cat: j['cat'], freq: j['freq'],
        oldAmount: _n(j['oldAmount']), newAmount: _n(j['newAmount']), keep: j['keep'] ?? true,
      );
}

class Scenario {
  String id, title, desc;
  DateTime createdAt;
  List<Hyp> hyps;
  Scenario({required this.id, required this.title, required this.desc, required this.createdAt, required this.hyps});

  double get delta => hyps.fold(0.0, (a, h) => a + h.delta);

  Map<String, dynamic> toJson() => {
        'id': id, 'title': title, 'desc': desc, 'createdAt': _s(createdAt),
        'hyps': hyps.map((h) => h.toJson()).toList(),
      };
  factory Scenario.fromJson(Map<String, dynamic> j) => Scenario(
        id: j['id'], title: j['title'], desc: j['desc'] ?? '', createdAt: _d(j['createdAt']),
        hyps: (j['hyps'] as List).map((h) => Hyp.fromJson(Map<String, dynamic>.from(h))).toList(),
      );
}

class Settings {
  String name;
  double income;
  int payDay; // jour du mois où le salaire tombe (1-31)
  double? balance; // solde du compte saisi par l'utilisateur
  DateTime? balanceDate; // date à laquelle ce solde a été saisi
  List<String> balanceSkip; // dépenses du jour déjà comprises dans le solde saisi
  String themeMode; // light | dark | auto
  String style; // menthe | graphite
  String palette; // menthe | ocean | prune | terracotta
  bool alerts, detection;
  List<String> ignored;

  Settings({
    this.name = '',
    this.income = 0,
    this.payDay = 1,
    this.balance,
    this.balanceDate,
    List<String>? balanceSkip,
    this.themeMode = 'auto',
    this.style = 'menthe',
    this.palette = 'menthe',
    this.alerts = true,
    this.detection = true,
    List<String>? ignored,
  })  : ignored = ignored ?? [],
        balanceSkip = balanceSkip ?? [];

  Map<String, dynamic> toJson() => {
        'name': name, 'income': income, 'payDay': payDay, 'balance': balance,
        'balanceDate': balanceDate == null ? null : _s(balanceDate!), 'balanceSkip': balanceSkip,
        'themeMode': themeMode, 'style': style, 'palette': palette,
        'alerts': alerts, 'detection': detection, 'ignored': ignored,
      };
  factory Settings.fromJson(Map<String, dynamic> j) => Settings(
        name: j['name'] ?? '', income: _n(j['income'] ?? 0), payDay: (j['payDay'] as num?)?.toInt() ?? 1,
        balance: j['balance'] == null ? null : _n(j['balance']),
        balanceDate: j['balanceDate'] == null ? null : _d(j['balanceDate']),
        balanceSkip: List<String>.from(j['balanceSkip'] ?? const []),
        themeMode: j['themeMode'] ?? 'auto',
        style: j['style'] ?? 'menthe', palette: j['palette'] ?? 'menthe', alerts: j['alerts'] ?? true,
        detection: j['detection'] ?? true, ignored: List<String>.from(j['ignored'] ?? const []),
      );
}
