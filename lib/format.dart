// Formatage en français : montants, dates, libellés.

const monthsFr = [
  'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
  'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
];
const monthsShort = [
  'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
  'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
];
const daysFr = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];
const daysShort = ['lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.', 'dim.'];

const nbsp = ' ';

String cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

String _group(int n) {
  final s = n.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(nbsp);
    b.write(s[i]);
  }
  return b.toString();
}

/// "1 308,12"
String num2(double v) {
  final cents = (v.abs() * 100).round();
  final s = '${_group(cents ~/ 100)},${(cents % 100).toString().padLeft(2, '0')}';
  return v < 0 && cents != 0 ? '−$s' : s;
}

/// "1 308"
String num0(double v) {
  final r = v.round();
  return (r < 0 ? '−' : '') + _group(r);
}

/// "1 308,12 €"
String eur(double v) => '${num2(v)}$nbsp€';

/// "1 308 €"
String eur0(double v) => '${num0(v)}$nbsp€';

/// Pas de décimales si le montant est rond.
String eurAuto(double v) => (v * 100).round() % 100 == 0 ? eur0(v) : eur(v);

/// Montant saisi par l'utilisateur ("12,5" ou "12.50") -> double.
double? parseAmount(String s) {
  final c = s.replaceAll(RegExp(r'[\s €]'), '').replaceAll(',', '.');
  if (c.isEmpty) return null;
  return double.tryParse(c);
}

/// Montant pour un champ éditable : "45,6" -> "45,60"
String amountInput(double v) => num2(v).replaceAll(nbsp, '');

String signed(double v, String Function(double) f) {
  if (v.abs() < 0.005) return '±${f(0)}';
  return (v > 0 ? '+' : '−') + f(v.abs());
}

String pct(double ratio) => '${(ratio * 100).round()}$nbsp%';

String signedPct(double ratio) {
  final p = (ratio * 100).round();
  if (p == 0) return '0$nbsp%';
  return '${p > 0 ? '+' : '−'}${p.abs()}$nbsp%';
}

DateTime dOnly(DateTime d) => DateTime(d.year, d.month, d.day);
int daysInMonth(int y, int m) => DateTime(y, m + 1, 0).day;
bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
String dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// "Vendredi 16 octobre" (+ année si différente de l'année courante)
String longDate(DateTime d, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final day = d.day == 1 ? '1er' : '${d.day}';
  final y = d.year != n.year ? ' ${d.year}' : '';
  return '${cap(daysFr[d.weekday - 1])} $day ${monthsFr[d.month - 1]}$y';
}

/// "16 oct."
String shortDate(DateTime d) => '${d.day} ${monthsShort[d.month - 1]}';

/// "Hier · 17 octobre", "Aujourd’hui", "Vendredi 16 octobre"
String dayHeader(DateTime d, DateTime today) {
  if (sameDay(d, today)) return 'Aujourd’hui';
  if (sameDay(d, today.subtract(const Duration(days: 1)))) {
    return 'Hier · ${d.day == 1 ? '1er' : d.day} ${monthsFr[d.month - 1]}';
  }
  return longDate(d, now: today);
}

/// "Hier", "16 oct.", "Aujourd’hui"
String relDay(DateTime d, DateTime today) {
  if (sameDay(d, today)) return 'Aujourd’hui';
  if (sameDay(d, today.subtract(const Duration(days: 1)))) return 'Hier';
  if (sameDay(d, today.add(const Duration(days: 1)))) return 'Demain';
  return shortDate(d);
}

String monthYear(int y, int m) => '${cap(monthsFr[m - 1])} $y';

/// Minuscules sans accents, pour les recherches et rapprochements.
String norm(String s) {
  const from = 'àâäáãåçéèêëíìîïñóòôöõúùûüýÿœæ';
  const to = 'aaaaaaceeeeiiiinooooouuuuyyoa';
  final b = StringBuffer();
  for (final ch in s.toLowerCase().trim().split('')) {
    final i = from.indexOf(ch);
    b.write(i >= 0 ? to[i] : ch);
  }
  return b.toString().replaceAll(RegExp(r'\s+'), ' ');
}
