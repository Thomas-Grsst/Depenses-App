import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'format.dart';
import 'models.dart';

const _key = 'depenses_state_v1';

/// Une échéance à venir d'une récurrence.
class Occ {
  final DateTime date;
  final Recurrence rec;
  Occ(this.date, this.rec);
}

class CatStat {
  final String cat;
  double spent = 0, occSpent = 0, prevSame = 0, budget = 0, remainingRec = 0, projected = 0;
  CatStat(this.cat);
}

class Alert {
  final String cat;
  final List<(String, bool)> parts; // (texte, gras)
  Alert(this.cat, this.parts);
  String get plain => parts.map((p) => p.$1).join();
}

class Suggestion {
  final String key, name, cat;
  final double amount;
  final int months;
  final DateTime last;
  final List<String> labels;
  final List<String> expenseIds;
  Suggestion(this.key, this.name, this.cat, this.amount, this.months, this.last, this.labels, this.expenseIds);
}

/// Statistiques du mois en cours (calculées à la demande, mises en cache).
class MonthStats {
  final DateTime today;
  late final int y, m, dim, day;
  double spent = 0, spentRec = 0, spentOcc = 0, prevSame = 0, prevFull = 0;
  bool hasPrev = false;
  double budget = 0, rate = 0, estOcc = 0, remainingRecTotal = 0, forecast = 0;
  int remainingDays = 0;
  List<Occ> remainingRec = [];
  final Map<String, CatStat> perCat = {for (final c in cats) c.key: CatStat(c.key)};
  List<double> realCurve = []; // index 0 = jour 1
  List<double> prevCurve = [];
  List<double> forecastCurve = []; // du jour courant à la fin du mois
  int prevDim = 30;

  MonthStats(this.today) {
    y = today.year;
    m = today.month;
    dim = daysInMonth(y, m);
    day = today.day;
  }

  double? get vsPrev => hasPrev && prevSame > 0 ? spent / prevSame - 1 : null;
}

class AppStore extends ChangeNotifier {
  SharedPreferences? _prefs;
  Settings settings = Settings();
  List<Expense> expenses = [];
  List<Recurrence> recs = [];
  Map<String, double> envelopes = {};
  List<LabelEnvelope> labelEnvs = [];
  List<Goal> goals = [];
  List<Scenario> sims = [];
  List<String> labels = [];

  DateTime get today => dOnly(DateTime.now());
  bool get onboarded => settings.name.trim().isNotEmpty;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_key);
    if (raw != null) {
      try {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        settings = Settings.fromJson(Map<String, dynamic>.from(j['settings'] ?? {}));
        expenses = [for (final e in j['expenses'] ?? []) Expense.fromJson(Map<String, dynamic>.from(e))];
        recs = [for (final e in j['recs'] ?? []) Recurrence.fromJson(Map<String, dynamic>.from(e))];
        envelopes = {
          for (final e in (j['envelopes'] as Map? ?? {}).entries) e.key as String: (e.value as num).toDouble(),
        };
        labelEnvs = [for (final e in j['labelEnvs'] ?? []) LabelEnvelope.fromJson(Map<String, dynamic>.from(e))];
        goals = [for (final e in j['goals'] ?? []) Goal.fromJson(Map<String, dynamic>.from(e))];
        sims = [for (final e in j['sims'] ?? []) Scenario.fromJson(Map<String, dynamic>.from(e))];
        labels = List<String>.from(j['labels'] ?? const []);
        setCustomCats([for (final c in j['cats'] ?? []) Cat.fromJson(Map<String, dynamic>.from(c))]);
      } catch (_) {
        // Données illisibles : on repart de zéro plutôt que de planter.
      }
    }
    if (labels.isEmpty) labels = ['Sortie', 'Amis', 'Restaurant', 'Abonnement', 'Maison', 'Travail', 'Voyage', 'Sport'];
    materialize(save: false);
    _persist();
  }

  String exportJson() => jsonEncode({
    'settings': settings.toJson(),
    'expenses': expenses.map((e) => e.toJson()).toList(),
    'recs': recs.map((e) => e.toJson()).toList(),
    'envelopes': envelopes,
    'labelEnvs': labelEnvs.map((e) => e.toJson()).toList(),
    'goals': goals.map((e) => e.toJson()).toList(),
    'sims': sims.map((e) => e.toJson()).toList(),
    'labels': labels,
    'cats': customCats.map((c) => c.toJson()).toList(),
  });

  void _persist() => _prefs?.setString(_key, exportJson());

  void commit() {
    _stats = null;
    _persist();
    notifyListeners();
  }

  // ---------- Récurrences -> dépenses ----------

  /// Crée les dépenses des échéances passées (jusqu'à aujourd'hui) qui n'existent pas encore.
  void materialize({bool save = true}) {
    final t = today;
    var changed = false;
    for (final r in recs) {
      final from = r.lastGen == null ? r.start : r.lastGen!.add(const Duration(days: 1));
      for (final d in r.occurrences(from, t)) {
        expenses.add(
          Expense(
            id: newId(),
            name: r.name,
            amount: r.amount,
            date: d,
            cat: r.cat,
            labels: [...r.labels],
            recId: r.id,
            roundUp: settings.roundUp ? roundUpOf(r.amount) : 0,
          ),
        );
        changed = true;
      }
      if (r.lastGen == null || r.lastGen!.isBefore(t)) {
        r.lastGen = t;
        changed = true;
      }
    }
    if (changed && save) commit();
  }

  // ---------- CRUD ----------

  void _learnLabels(List<String> ls) {
    for (final l in ls) {
      if (!labels.contains(l)) labels.add(l);
    }
  }

  /// Arrondi à l'euro supérieur : 8,37 € -> 0,63 € mis de côté (0 si le montant est rond).
  static double roundUpOf(double amount) {
    final c = (amount * 100).round();
    return ((100 - c % 100) % 100) / 100;
  }

  void addExpense(Expense e) {
    _learnLabels(e.labels);
    if (settings.roundUp) e.roundUp = roundUpOf(e.amount);
    expenses.add(e);
    commit();
  }

  void updateExpense(Expense e) {
    _learnLabels(e.labels);
    if (e.roundUp > 0 || settings.roundUp) e.roundUp = roundUpOf(e.amount);
    commit();
  }

  void deleteExpense(String id) {
    expenses.removeWhere((e) => e.id == id);
    commit();
  }

  void addRecurrence(Recurrence r) {
    _learnLabels(r.labels);
    recs.add(r);
    materialize(save: false);
    commit();
  }

  void updateRecurrence(Recurrence r) {
    _learnLabels(r.labels);
    commit();
  }

  /// Supprime la récurrence ; les dépenses déjà passées restent dans l'historique.
  void deleteRecurrence(String id) {
    recs.removeWhere((r) => r.id == id);
    commit();
  }

  Recurrence? recById(String? id) {
    if (id == null) return null;
    for (final r in recs) {
      if (r.id == id) return r;
    }
    return null;
  }

  void setEnvelope(String cat, double amount) {
    if (amount <= 0) {
      envelopes.remove(cat);
    } else {
      envelopes[cat] = amount;
    }
  }

  // ---------- Catégories perso ----------

  void addCategory(String name, String kind, int color) {
    final c = Cat.custom('c${newId()}', name, kind, color);
    setCustomCats([...customCats, c]);
    commit();
  }

  void updateCategory(Cat old, String name, String kind, int color) {
    setCustomCats([for (final c in customCats) c.key == old.key ? Cat.custom(c.key, name, kind, color) : c]);
    commit();
  }

  /// Supprime une catégorie perso : ses dépenses, récurrences et enveloppe passent dans « Autres ».
  void deleteCategory(Cat cat) {
    for (final e in expenses) {
      if (e.cat == cat.key) e.cat = 'aut';
    }
    for (final r in recs) {
      if (r.cat == cat.key) r.cat = 'aut';
    }
    final env = envelopes.remove(cat.key);
    if (env != null) envelopes['aut'] = (envelopes['aut'] ?? 0) + env;
    setCustomCats(customCats.where((c) => c.key != cat.key).toList());
    commit();
  }

  void resetAll() {
    final keep = Settings(
      name: settings.name,
      income: settings.income,
      payDay: settings.payDay,
      style: settings.style,
      themeMode: settings.themeMode,
      palette: settings.palette,
    );
    settings = keep;
    expenses = [];
    recs = [];
    envelopes = {};
    labelEnvs = [];
    goals = [];
    sims = [];
    commit();
  }

  // ---------- Requêtes ----------

  List<Expense> inMonth(int y, int m) => expenses.where((e) => e.date.year == y && e.date.month == m).toList();

  double get fixedMonthly => recs.fold(0.0, (a, r) => a + r.monthly);
  double get totalBudget => envelopes.values.fold(0.0, (a, v) => a + v);

  List<Occ> upcoming(DateTime from, DateTime to) {
    final out = <Occ>[];
    for (final r in recs) {
      for (final d in r.occurrences(from, to)) {
        out.add(Occ(d, r));
      }
    }
    out.sort((a, b) => a.date.compareTo(b.date));
    return out;
  }

  List<Occ> nextOccurrences(int n) {
    final t = today;
    return upcoming(t.add(const Duration(days: 1)), DateTime(t.year + 1, t.month, t.day)).take(n).toList();
  }

  List<Expense> recent(int n) {
    final l = [...expenses]
      ..sort((a, b) {
        final c = b.date.compareTo(a.date);
        return c != 0 ? c : b.id.compareTo(a.id);
      });
    return l.take(n).toList();
  }

  /// Mois (année, mois) qui contiennent au moins une dépense, + le mois courant ; du plus récent au plus ancien.
  List<(int, int)> monthsWithData() {
    final t = today;
    final set = <int>{t.year * 12 + t.month - 1};
    for (final e in expenses) {
      set.add(e.date.year * 12 + e.date.month - 1);
    }
    final l = set.toList()..sort((a, b) => b.compareTo(a));
    return [for (final k in l) (k ~/ 12, k % 12 + 1)];
  }

  double labelSpent(String label, int y, int m) =>
      inMonth(y, m).where((e) => e.labels.contains(label)).fold(0.0, (a, e) => a + e.amount);

  // ---------- Solde du compte ----------

  bool get hasBalance => settings.balance != null && settings.balanceDate != null;

  /// Saisit le solde actuel du compte (les dépenses déjà notées aujourd'hui y sont comprises).
  void setBalance(double amount) {
    final t = today;
    settings.balance = amount;
    settings.balanceDate = t;
    settings.balanceSkip = [
      for (final e in expenses)
        if (sameDay(e.date, t)) e.id,
    ];
    commit();
  }

  void clearBalance() {
    settings.balance = null;
    settings.balanceDate = null;
    settings.balanceSkip = [];
    commit();
  }

  /// Jours de paie entre [from] et [to] inclus (jour ramené à la fin du mois si besoin).
  List<DateTime> payDates(DateTime from, DateTime to) {
    final out = <DateTime>[];
    if (settings.income <= 0) return out;
    for (var m = DateTime(from.year, from.month); !m.isAfter(to); m = DateTime(m.year, m.month + 1)) {
      final d = DateTime(m.year, m.month, min(settings.payDay, daysInMonth(m.year, m.month)));
      if (!d.isBefore(from) && !d.isAfter(to)) out.add(d);
    }
    return out;
  }

  DateTime? get nextPayday {
    final t = today;
    final l = payDates(t.add(const Duration(days: 1)), DateTime(t.year, t.month + 2, 1));
    return l.isEmpty ? null : l.first;
  }

  bool _counts(Expense e, DateTime since) =>
      e.date.isAfter(since) || (sameDay(e.date, since) && !settings.balanceSkip.contains(e.id));

  /// Solde à une date : solde saisi + salaires reçus − dépenses depuis la saisie.
  double balanceAt(DateTime day) {
    if (!hasBalance) return 0;
    final since = settings.balanceDate!;
    var b = settings.balance!;
    b += payDates(since.add(const Duration(days: 1)), day).length * settings.income;
    for (final e in expenses) {
      if (_counts(e, since) && !e.date.isAfter(day)) b -= e.amount + e.roundUp;
    }
    return b;
  }

  double get balance => balanceAt(today);

  /// Dépenses déjà saisies pour plus tard dans le mois (non comprises dans la prévision).
  double get futureNoted {
    final t = today;
    return inMonth(t.year, t.month)
        .where((e) => e.date.isAfter(t) && _counts(e, settings.balanceDate ?? t))
        .fold(0.0, (a, e) => a + e.amount + e.roundUp);
  }

  /// Solde estimé au dernier jour du mois (prévision des dépenses + salaire s'il tombe d'ici là).
  double get balanceEndOfMonth {
    final s = stats;
    final t = today;
    final salary = payDates(t.add(const Duration(days: 1)), DateTime(s.y, s.m, s.dim)).length * settings.income;
    final recRoundUps = settings.roundUp ? s.remainingRec.fold(0.0, (a, o) => a + roundUpOf(o.rec.amount)) : 0.0;
    return balance + salary - (s.forecast - s.spent) - futureNoted - recRoundUps;
  }

  // ---------- Arrondis ----------

  double get roundUpTotal => expenses.fold(0.0, (a, e) => a + e.roundUp);
  double roundUpMonth(int y, int m) => inMonth(y, m).fold(0.0, (a, e) => a + e.roundUp);
  double get roundUpAvailable => max(0, roundUpTotal - settings.roundUpUsed);

  /// Verse les arrondis disponibles dans un objectif d'épargne.
  void moveRoundUpTo(Goal g) {
    final v = roundUpAvailable;
    if (v <= 0) return;
    g.saved += v;
    settings.roundUpUsed += v;
    commit();
  }

  // ---------- Statistiques ----------

  MonthStats? _stats;
  MonthStats get stats => _stats ??= _computeStats();

  MonthStats _computeStats() {
    final t = today;
    final s = MonthStats(t);
    s.budget = totalBudget;

    // Mois courant
    final cur = inMonth(s.y, s.m);
    final daily = List<double>.filled(s.dim, 0);
    for (final e in cur) {
      if (e.date.isAfter(t)) continue;
      s.spent += e.amount;
      final cs = s.perCat[e.cat] ?? s.perCat['aut']!;
      cs.spent += e.amount;
      if (e.isRec) {
        s.spentRec += e.amount;
      } else {
        s.spentOcc += e.amount;
        cs.occSpent += e.amount;
      }
      daily[e.date.day - 1] += e.amount;
    }
    var acc = 0.0;
    for (var d = 0; d < s.day; d++) {
      acc += daily[d];
      s.realCurve.add(acc);
    }

    // Mois précédent
    final pm = DateTime(s.y, s.m - 1, 1);
    s.prevDim = daysInMonth(pm.year, pm.month);
    final prev = inMonth(pm.year, pm.month);
    s.hasPrev = prev.isNotEmpty;
    final pdaily = List<double>.filled(s.prevDim, 0);
    final sameDay = min(s.day, s.prevDim);
    for (final e in prev) {
      s.prevFull += e.amount;
      pdaily[e.date.day - 1] += e.amount;
      if (e.date.day <= sameDay) {
        s.prevSame += e.amount;
        (s.perCat[e.cat] ?? s.perCat['aut']!).prevSame += e.amount;
      }
    }
    acc = 0;
    for (final v in pdaily) {
      acc += v;
      s.prevCurve.add(acc);
    }

    // Rythme des dépenses occasionnelles : mois courant mélangé à l'historique (3 mois).
    var histOcc = 0.0, histDays = 0;
    final histCat = <String, double>{};
    for (var k = 1; k <= 3; k++) {
      final hm = DateTime(s.y, s.m - k, 1);
      final list = inMonth(hm.year, hm.month);
      if (list.isEmpty) continue;
      histDays += daysInMonth(hm.year, hm.month);
      for (final e in list.where((e) => !e.isRec)) {
        histOcc += e.amount;
        histCat[e.cat] = (histCat[e.cat] ?? 0) + e.amount;
      }
    }
    double blend(double curTotal, double histTotal) {
      final curRate = curTotal / s.day;
      if (histDays == 0) return curRate;
      final histRate = histTotal / histDays;
      final w = min(1.0, s.day / 10) * 0.6; // en début de mois, l'historique pèse plus
      return curRate * w + histRate * (1 - w);
    }

    s.rate = blend(s.spentOcc, histOcc);
    s.remainingDays = s.dim - s.day;
    s.estOcc = s.rate * s.remainingDays;
    s.remainingRec = upcoming(t.add(const Duration(days: 1)), DateTime(s.y, s.m, s.dim));
    s.remainingRecTotal = s.remainingRec.fold(0.0, (a, o) => a + o.rec.amount);
    s.forecast = s.spent + s.remainingRecTotal + s.estOcc;

    for (final c in s.perCat.values) {
      c.budget = envelopes[c.cat] ?? 0;
      c.remainingRec = s.remainingRec.where((o) => o.rec.cat == c.cat).fold(0.0, (a, o) => a + o.rec.amount);
      c.projected = c.spent + c.remainingRec + blend(c.occSpent, histCat[c.cat] ?? 0) * s.remainingDays;
    }

    // Courbe estimée du jour courant à la fin du mois
    var v = s.spent;
    s.forecastCurve.add(v);
    for (var d = s.day + 1; d <= s.dim; d++) {
      v += s.rate;
      for (final o in s.remainingRec) {
        if (o.date.day == d) v += o.rec.amount;
      }
      s.forecastCurve.add(v);
    }
    return s;
  }

  /// Moyenne des 3 derniers mois complets (ou la prévision du mois si pas d'historique).
  double get typicalMonth {
    final s = stats;
    var total = 0.0, n = 0;
    for (var k = 1; k <= 3; k++) {
      final hm = DateTime(s.y, s.m - k, 1);
      final list = inMonth(hm.year, hm.month);
      if (list.isEmpty) continue;
      total += list.fold(0.0, (a, e) => a + e.amount);
      n++;
    }
    return n == 0 ? s.forecast : total / n;
  }

  List<Alert> get alerts {
    if (!settings.alerts) return [];
    final s = stats;
    final out = <Alert>[];
    final dayRatio = s.day / s.dim;
    for (final c in cats) {
      final cs = s.perCat[c.key]!;
      if (cs.budget <= 0) continue;
      final r = cs.spent / cs.budget;
      if (r >= 1) {
        out.add(
          Alert(c.key, [
            ('Budget ${c.name} dépassé : ', false),
            ('${eurAuto(cs.spent)} sur ${eurAuto(cs.budget)}', true),
            ('.', false),
          ]),
        );
        continue;
      }
      // Le rythme se juge sur les dépenses courantes : les charges fixes (loyer…) tombent en début de mois.
      final fixed = (cs.spent - cs.occSpent) + cs.remainingRec;
      final variable = cs.budget - fixed;
      final pace = variable > 0 ? cs.occSpent / variable : 0.0;
      if (r >= 0.5 && pace >= 0.4 && pace > dayRatio + 0.15) {
        out.add(
          Alert(c.key, [
            ('Tu as déjà dépensé ', false),
            (pct(r), true),
            (' de ton budget ${c.name} et nous sommes seulement le ${s.day}.', false),
          ]),
        );
      } else if (cs.projected > cs.budget * 1.05 && s.day >= 5) {
        out.add(
          Alert(c.key, [
            ('À ce rythme, ton enveloppe ${c.name} dépasserait d’environ ', false),
            (eur0(cs.projected - cs.budget), true),
            (' d’ici la fin du mois.', false),
          ]),
        );
      }
    }
    if (s.budget > 0 && s.forecast > s.budget && out.isEmpty) {
      out.add(
        Alert('aut', [
          ('Au rythme actuel, tu dépasserais ton budget d’environ ', false),
          (eur0(s.forecast - s.budget), true),
          (' ce mois-ci.', false),
        ]),
      );
    }
    return out;
  }

  /// Dépenses occasionnelles qui reviennent chaque mois : proposer une récurrence.
  List<Suggestion> get suggestions {
    if (!settings.detection) return [];
    final t = today;
    final since = DateTime(t.year, t.month - 4, t.day);
    final recNames = recs.map((r) => norm(r.name)).toSet();
    final groups = <String, List<Expense>>{};
    for (final e in expenses) {
      if (e.isRec || e.date.isBefore(since) || e.date.isAfter(t)) continue;
      groups.putIfAbsent(norm(e.name), () => []).add(e);
    }
    final out = <Suggestion>[];
    groups.forEach((k, list) {
      if (k.isEmpty || recNames.contains(k) || settings.ignored.contains(k)) return;
      list.sort((a, b) => a.date.compareTo(b.date));
      final last = list.last;
      // Un abonnement : une seule fois par mois, toujours le même montant, à peu près le même jour.
      final perMonth = <int, int>{};
      for (final e in list) {
        final k = e.date.year * 12 + e.date.month;
        perMonth[k] = (perMonth[k] ?? 0) + 1;
      }
      if (perMonth.values.any((n) => n > 1)) return;
      final similar = list
          .where(
            (e) =>
                (e.amount - last.amount).abs() <= max(0.05, last.amount * 0.03) &&
                (e.date.day - last.date.day).abs() <= 5,
          )
          .toList();
      final months = similar.map((e) => e.date.year * 12 + e.date.month).toSet();
      if (months.length < 2) return;
      out.add(
        Suggestion(
          k,
          last.name,
          last.cat,
          last.amount,
          months.length,
          last.date,
          last.labels,
          similar.map((e) => e.id).toList(),
        ),
      );
    });
    out.sort((a, b) => b.months.compareTo(a.months));
    return out;
  }

  void acceptSuggestion(Suggestion s) {
    final r = Recurrence(
      id: newId(),
      name: s.name,
      amount: s.amount,
      cat: s.cat,
      freq: 'month',
      start: s.last,
      labels: [...s.labels],
      lastGen: today,
    );
    recs.add(r);
    for (final e in expenses) {
      if (s.expenseIds.contains(e.id)) e.recId = r.id;
    }
    commit();
  }

  void ignoreSuggestion(Suggestion s) {
    settings.ignored.add(s.key);
    commit();
  }

  String toCsv() {
    final b = StringBuffer('date;nom;montant;categorie;libelles;recurrente\n');
    final l = [...expenses]..sort((a, b) => a.date.compareTo(b.date));
    for (final e in l) {
      String q(String s) => '"${s.replaceAll('"', '""')}"';
      b.writeln(
        [
          dateKey(e.date),
          q(e.name),
          e.amount.toStringAsFixed(2).replaceAll('.', ','),
          q(catOf(e.cat).name),
          q(e.labels.join(', ')),
          e.isRec ? 'oui' : 'non',
        ].join(';'),
      );
    }
    return b.toString();
  }
}

class StoreScope extends InheritedNotifier<AppStore> {
  const StoreScope({super.key, required AppStore store, required super.child}) : super(notifier: store);

  static AppStore of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<StoreScope>()!.notifier!;

  static AppStore read(BuildContext context) =>
      (context.getElementForInheritedWidgetOfExactType<StoreScope>()!.widget as StoreScope).notifier!;
}
