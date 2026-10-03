import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'format.dart';
import 'models.dart';
import 'theme.dart';

/// Tracés des icônes (viewBox 24×24, trait = currentColor).
const _paths = <String, String>{
  // Icônes de dépense
  'home': '<path d="M3 10.5 12 3l9 7.5V20a1 1 0 0 1-1 1h-5v-6h-6v6H4a1 1 0 0 1-1-1z"/>',
  'cart': '<circle cx="9" cy="20" r="1.5"/><circle cx="18" cy="20" r="1.5"/><path d="M2 3h3l2.7 12.4a2 2 0 0 0 2 1.6h7.7a2 2 0 0 0 2-1.5L21 8H6"/>',
  'food': '<path d="M4 2v6a3 3 0 0 0 6 0V2"/><path d="M7 2v20"/><path d="M20 15V2a5 5 0 0 0-5 5v6a2 2 0 0 0 2 2h3zm0 0v7"/>',
  'bolt': '<path d="M13 2 4 14h7l-1 8 9-12h-7z"/>',
  'sport': '<path d="M6.5 6.5v11M3 9v6M17.5 6.5v11M21 9v6M6.5 12h11"/>',
  'film': '<path d="M3 9V7a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v2a3 3 0 0 0 0 6v2a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-2a3 3 0 0 0 0-6z"/><path d="M14 5v2M14 11v2M14 17v2"/>',
  'pill': '<path d="M10.5 20.5a5 5 0 0 1-7-7l10-10a5 5 0 0 1 7 7z"/><path d="m8.5 8.5 7 7"/>',
  'car': '<path d="M5 17H4a1 1 0 0 1-1-1v-3l2.2-5.2A2 2 0 0 1 7 6.5h10a2 2 0 0 1 1.8 1.3L21 13v3a1 1 0 0 1-1 1h-1"/><path d="M3 13h18M9 17h6"/><circle cx="7" cy="17" r="2"/><circle cx="17" cy="17" r="2"/>',
  'heart': '<path d="M19 14c1.5-1.5 3-3.2 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.8 0-3 .5-4.5 2-1.5-1.5-2.7-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4 3 5.5l7 7z"/>',
  'dots': '<circle cx="5" cy="12" r="2" fill="currentColor" stroke="none"/><circle cx="12" cy="12" r="2" fill="currentColor" stroke="none"/><circle cx="19" cy="12" r="2" fill="currentColor" stroke="none"/>',
  'train': '<rect x="5" y="3" width="14" height="14" rx="3"/><path d="M5 11h14M9 21l-2-4M15 21l2-4"/><path d="M9 14h.01M15 14h.01"/>',
  'gift': '<rect x="3" y="8" width="18" height="4" rx="1"/><path d="M12 8v13M19 12v8a1 1 0 0 1-1 1H6a1 1 0 0 1-1-1v-8"/><path d="M7.5 8a2.5 2.5 0 0 1 0-5C10 3 12 8 12 8s2-5 4.5-5a2.5 2.5 0 0 1 0 5"/>',
  'plane': '<path d="M17.8 19.2 16 11l3.5-3.5C21 6 21.5 4 21 3c-1-.5-3 0-4.5 1.5L13 8 4.8 6.2c-.5-.1-.9.1-1.1.5l-.3.5c-.2.5-.1 1 .3 1.3L9 12l-2 3H4l-1 1 3 2 2 3 1-1v-3l3-2 3.5 5.3c.3.4.8.5 1.3.3l.5-.2c.4-.3.6-.7.5-1.2z"/>',
  // Icônes d'interface
  'bell': '<path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10.3 21a1.94 1.94 0 0 0 3.4 0"/>',
  'list': '<path d="M8 6h13M8 12h13M8 18h13M3 6h.01M3 12h.01M3 18h.01"/>',
  'plus': '<path d="M12 5v14M5 12h14"/>',
  'minus': '<path d="M5 12h14"/>',
  'repeat': '<path d="M17 2l4 4-4 4"/><path d="M3 11V9a3 3 0 0 1 3-3h15"/><path d="M7 22l-4-4 4-4"/><path d="M21 13v2a3 3 0 0 1-3 3H3"/>',
  'user': '<circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/>',
  'close': '<path d="M18 6 6 18M6 6l12 12"/>',
  'calendar': '<rect x="3" y="4" width="18" height="18" rx="3"/><path d="M16 2v4M8 2v4M3 10h18"/>',
  'chevL': '<path d="m15 18-6-6 6-6"/>',
  'chevR': '<path d="m9 18 6-6-6-6"/>',
  'chevD': '<path d="m6 9 6 6 6-6"/>',
  'arrowR': '<path d="M5 12h14M13 6l6 6-6 6"/>',
  'search': '<circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/>',
  'alert': '<path d="M12 9v4"/><path d="M12 17h.01"/><path d="M10.3 3.9 1.8 18a2 2 0 0 0 1.7 3h17a2 2 0 0 0 1.7-3L13.7 3.9a2 2 0 0 0-3.4 0z"/>',
  'bulb': '<path d="M9 18h6M10 22h4"/><path d="M12 2a7 7 0 0 0-4 12.7V16h8v-1.3A7 7 0 0 0 12 2z"/>',
  'flask': '<path d="M10 2v7.3L4.4 19A2 2 0 0 0 6.1 22h11.8a2 2 0 0 0 1.7-3L14 9.3V2"/><path d="M8.5 2h7"/><path d="M7 16h10"/>',
  'check': '<path d="M20 6 9 17l-5-5"/>',
  'trash': '<path d="M3 6h18M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/>',
  'save': '<path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/><path d="M17 21v-8H7v8M7 3v5h8"/>',
  'edit': '<path d="M12 20h9"/><path d="M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4z"/>',
  'tag': '<path d="M20.6 13.4 13.4 20.6a2 2 0 0 1-2.8 0L3 13V3h10l7.6 7.6a2 2 0 0 1 0 2.8z"/><circle cx="7.5" cy="7.5" r="1.5"/>',
  'piggy': '<path d="M19 5c-1.5 0-2.8 1.4-3 2-3.5-1.5-11-.3-11 5 0 1.8 0 3 2 4.5V20h4v-2h3v2h4v-4c1-.5 1.7-1 2-2h2v-4h-2c0-1-.5-1.5-1-2V5z"/><path d="M2 9v1c0 1.1.9 2 2 2h1"/><path d="M16 11h.01"/>',
};

const expenseKinds = [
  'cart', 'food', 'home', 'bolt', 'sport', 'film', 'pill', 'heart', 'car', 'train', 'gift', 'plane', 'dots',
];

final _cache = <String, String>{};

String _svg(String name, double stroke) => _cache.putIfAbsent(
    '$name@$stroke',
    () =>
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#000" '
        'stroke-width="$stroke" stroke-linecap="round" stroke-linejoin="round">'
        '${(_paths[name] ?? '').replaceAll('currentColor', '#000')}</svg>');

/// Icône vectorielle simple.
class Ico extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;
  final double? stroke;
  const Ico(this.name, {super.key, this.size = 22, this.color, this.stroke});

  @override
  Widget build(BuildContext context) {
    final t = TkScope.of(context);
    return SvgPicture.string(
      _svg(name, stroke ?? (t.graphite ? 1.4 : 1.8)),
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color ?? t.ink, BlendMode.srcIn),
    );
  }
}

/// Apparence d'une dépense : pictogramme ou initiale du marchand.
class Look {
  final String kind; // un des expenseKinds, ou 'letter'
  final String letter;
  const Look(this.kind, [this.letter = '']);
}

const _brands = <String, String>{
  'netflix': 'N', 'spotify': 'S', 'amazon': 'a', 'uber': 'U', 'deezer': 'D', 'disney': 'D',
  'canal+': 'C', 'canal plus': 'C', 'youtube': 'Y', 'apple': 'A', 'icloud': 'A', 'google': 'G',
  'free': 'F', 'orange': 'O', 'sfr': 'S', 'bouygues': 'B', 'sosh': 'S', 'red by': 'R',
  'ikea': 'I', 'fnac': 'F', 'decathlon': 'D', 'zara': 'Z', 'h&m': 'H', 'leroy merlin': 'L',
  'paypal': 'P', 'microsoft': 'M', 'xbox': 'X', 'playstation': 'P', 'nintendo': 'N', 'steam': 'S',
  'chatgpt': 'C', 'openai': 'O', 'claude': 'C', 'twitch': 'T', 'crunchyroll': 'C', 'adobe': 'A',
  'blablacar': 'B', 'deliveroo': 'D', 'uber eats': 'U', 'airbnb': 'A', 'booking': 'B',
};

const _keywords = <String, List<String>>{
  'cart': ['course', 'carrefour', 'leclerc', 'lidl', 'auchan', 'intermarche', 'monoprix', 'super u', 'casino',
      'franprix', 'aldi', 'supermarche', 'marche', 'epicerie', 'picard', 'biocoop', 'drive'],
  'food': ['restaurant', 'resto', 'mcdo', 'mcdonald', 'burger', 'pizza', 'kebab', 'cafe', 'boulangerie', 'sushi',
      'dejeuner', 'diner', 'brasserie', ' bar ', 'kfc', 'subway', 'traiteur', 'repas', 'snack', 'apero'],
  'home': ['loyer', 'appart', 'logement', 'maison', 'immo', 'syndic', 'charges', 'habitation', 'meuble'],
  'bolt': ['electricite', 'edf', 'engie', 'gaz', 'energie', 'totalenergies', 'chauffage', 'internet', ' box ', ' eau '],
  'sport': ['sport', 'salle', 'fitness', 'basic fit', 'piscine', 'yoga', 'muscu', 'club', 'gym', 'running'],
  'film': ['cinema', 'cine', 'film', 'theatre', 'concert', 'spectacle', 'musee', 'jeu', 'livre', 'bowling'],
  'pill': ['pharmacie', 'medicament', 'doliprane', 'parapharmacie'],
  'heart': ['medecin', 'docteur', 'dentiste', 'mutuelle', 'sante', 'kine', 'hopital', 'ophtalmo', 'psy', 'analyse'],
  'car': ['essence', 'carburant', 'voiture', 'garage', 'parking', 'peage', 'auto', 'total', 'diesel', 'pneu', 'lavage'],
  'train': ['train', 'sncf', 'metro', 'ratp', 'navigo', 'bus', 'tram', 'tgv', 'ouigo', 'transport', 'velib', ' ter '],
  'gift': ['cadeau', 'anniversaire', 'noel', 'fete', 'mariage'],
  'plane': ['avion', ' vol ', 'voyage', 'hotel', 'vacances', 'billet', 'aeroport', 'week-end', 'weekend'],
};

Look lookFor(String name, String cat) {
  final n = norm(name);
  final padded = ' $n ';
  for (final e in _brands.entries) {
    if (n.startsWith(e.key) || n.contains(' ${e.key}')) return Look('letter', e.value);
  }
  for (final e in _keywords.entries) {
    for (final k in e.value) {
      if (padded.contains(k)) return Look(e.key);
    }
  }
  if (cat == 'aut' && name.trim().isNotEmpty) return Look('letter', name.trim()[0].toUpperCase());
  return Look(catOf(cat).kind);
}

/// Icône ronde (Graphite) ou carrée arrondie teintée (Menthe) d'une dépense / catégorie.
class CatIcon extends StatelessWidget {
  final String cat;
  final Look look;
  final double size;
  final bool selected, dashed;

  CatIcon({super.key, required this.cat, Look? look, String? name, this.size = 40, this.selected = false, this.dashed = false})
      : look = look ?? (name != null ? lookFor(name, cat) : Look(catOf(cat).kind));

  @override
  Widget build(BuildContext context) {
    final t = TkScope.of(context);
    final Color fg, bg;
    final BoxBorder? border;
    final double radius;
    if (t.graphite) {
      fg = selected ? Colors.white : t.ink;
      bg = selected ? t.fab : Colors.transparent;
      border = Border.all(color: selected ? t.fab : (dashed ? t.faint : t.lineStrong), width: 1);
      radius = size / 2;
    } else {
      final c = t.cat(cat);
      fg = c;
      bg = c.withValues(alpha: t.dark ? 0.18 : 0.12);
      border = null;
      radius = size * 0.32;
    }
    final child = look.kind == 'letter'
        ? Text(look.letter.isEmpty ? '?' : look.letter,
            style: TextStyle(
                fontFamily: t.font,
                fontWeight: t.graphite ? FontWeight.w500 : FontWeight.w800,
                fontSize: size * 0.42,
                color: fg,
                height: 1))
        : Ico(look.kind, size: size * 0.5, color: fg, stroke: t.graphite ? 1.4 : 2);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(radius), border: border),
      child: child,
    );
  }
}

/// Catégorie probable d'après le nom saisi (null si rien de reconnu).
String? guessCat(String name) {
  final n = norm(name);
  if (n.length < 3) return null;
  const brandCats = {'uber': 'tra', 'blablacar': 'tra', 'deliveroo': 'ali', 'uber eats': 'ali', 'airbnb': 'loi',
      'booking': 'loi', 'free': 'log', 'orange': 'log', 'sfr': 'log', 'bouygues': 'log', 'sosh': 'log', 'red by': 'log',
      'ikea': 'log', 'leroy merlin': 'log', 'decathlon': 'san'};
  for (final e in brandCats.entries) {
    if (n.startsWith(e.key)) return e.value;
  }
  final look = lookFor(name, 'aut');
  return switch (look.kind) {
    'cart' || 'food' => 'ali',
    'home' || 'bolt' => 'log',
    'car' || 'train' => 'tra',
    'film' || 'plane' => 'loi',
    'sport' || 'pill' || 'heart' => 'san',
    'gift' => 'aut',
    'letter' => _brands.keys.any((k) => n.startsWith(k)) ? 'loi' : null,
    _ => null,
  };
}
