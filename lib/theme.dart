import 'package:flutter/material.dart';

import 'models.dart';

/// Jetons de couleur et de style. Deux directions : Menthe (cartes) et Graphite (filets).
class Tk {
  final bool dark, graphite;
  final Color bg, card, ink, muted, faint, line, lineStrong;
  final Color mint, mintSoft, mintFill, onMint;
  final Color warn, warnSoft, warnFill;
  final Color chip, fab, fabInk, hero, heroInk, heroMuted, heroAccent, heroChip;
  final Color track, grid, ghost, good, bad, off, sheet, body, accent;
  final Map<String, Color> catColors;

  const Tk({
    required this.dark,
    required this.graphite,
    required this.bg,
    required this.card,
    required this.ink,
    required this.muted,
    required this.faint,
    required this.line,
    required this.lineStrong,
    required this.mint,
    required this.mintSoft,
    required this.mintFill,
    required this.onMint,
    required this.warn,
    required this.warnSoft,
    required this.warnFill,
    required this.chip,
    required this.fab,
    required this.fabInk,
    required this.hero,
    required this.heroInk,
    required this.heroMuted,
    required this.heroAccent,
    required this.heroChip,
    required this.track,
    required this.grid,
    required this.ghost,
    required this.good,
    required this.bad,
    required this.off,
    required this.sheet,
    required this.body,
    required this.accent,
    required this.catColors,
  });

  String get font => graphite ? 'Geist' : 'Manrope';
  double get pad => graphite ? 24 : 20;

  Color cat(String key) {
    final c = catColors[key];
    if (c != null) return c;
    final idx = catOf(key).color;
    if (idx == null) return catColors['aut']!;
    return (dark ? customCatDark : customCatLight)[idx % customCatLight.length];
  }

  static const customCatLight = [
    Color(0xFFD14B4B), Color(0xFFB8860B), Color(0xFF2E8B57), Color(0xFF1E88A8),
    Color(0xFF8E5BD6), Color(0xFFD16BA5), Color(0xFF5D7A2E), Color(0xFF8B5E3C),
  ];
  static const customCatDark = [
    Color(0xFFF28B8B), Color(0xFFE8C15A), Color(0xFF6FD39B), Color(0xFF6CC8E6),
    Color(0xFFC3A2F5), Color(0xFFF2A3CF), Color(0xFFA8CC6E), Color(0xFFD1A27F),
  ];

  TextStyle ts(double size, [FontWeight w = FontWeight.w500, Color? color]) => TextStyle(
        fontFamily: font,
        fontSize: size,
        fontWeight: w,
        color: color ?? ink,
        height: 1.3,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Étiquette en capitales (Geist Mono en Graphite, Manrope gras en Menthe).
  TextStyle label([Color? color]) => graphite
      ? TextStyle(
          fontFamily: 'GeistMono', fontSize: 11, letterSpacing: 1.5, color: color ?? muted,
          fontWeight: FontWeight.w400, height: 1.3)
      : ts(13, FontWeight.w700, color ?? muted);

  TextStyle mono(double size, [Color? color]) => TextStyle(
      fontFamily: 'GeistMono', fontSize: size, color: color ?? ink, height: 1.3, letterSpacing: size * 0.05);

  // Poids typographiques usuels selon le style
  FontWeight get wTitle => graphite ? FontWeight.w300 : FontWeight.w800;
  FontWeight get wStrong => graphite ? FontWeight.w400 : FontWeight.w800;
  FontWeight get wItem => graphite ? FontWeight.w400 : FontWeight.w700;
  FontWeight get wBody => graphite ? FontWeight.w400 : FontWeight.w500;
  FontWeight get wSemi => graphite ? FontWeight.w400 : FontWeight.w600;

  static Tk resolve({required String style, required bool dark, required String palette}) {
    if (style == 'graphite') return dark ? graphiteDark : graphiteLight;
    if (dark) {
      return switch (palette) {
        'ocean' => oceanDark,
        'prune' => pruneDark,
        'terracotta' => terracottaDark,
        _ => mentheDark,
      };
    }
    return switch (palette) {
      'ocean' => ocean,
      'prune' => prune,
      'terracotta' => terracotta,
      _ => mentheLight,
    };
  }

  static const _catLight = {
    'log': Color(0xFF2F6FDB), 'ali': Color(0xFFC9621A), 'tra': Color(0xFF6E4FD6),
    'loi': Color(0xFFC4407F), 'san': Color(0xFF138A84), 'aut': Color(0xFF66736D),
  };
  static const _catDark = {
    'log': Color(0xFF86ADF7), 'ali': Color(0xFFF2A15E), 'tra': Color(0xFFB5A2F6),
    'loi': Color(0xFFF28FC2), 'san': Color(0xFF62D4CC), 'aut': Color(0xFFAAB6B1),
  };

  static const mentheLight = Tk(
    dark: false, graphite: false,
    bg: Color(0xFFF4F7F5), card: Color(0xFFFFFFFF), ink: Color(0xFF0D2B24), muted: Color(0xFF56675F),
    faint: Color(0xFF5F6F69), line: Color(0xFFE3EAE6), lineStrong: Color(0xFFB7C5BF),
    mint: Color(0xFF0F8A5F), mintSoft: Color(0xFFDDF5EA), mintFill: Color(0xFF2FBF85), onMint: Color(0xFFFFFFFF),
    warn: Color(0xFFB4580F), warnSoft: Color(0xFFFBE9D7), warnFill: Color(0xFFE39A55),
    chip: Color(0xFFEEF3F0), fab: Color(0xFF0D2B24), fabInk: Color(0xFFFFFFFF),
    hero: Color(0xFF0D2B24), heroInk: Color(0xFFFFFFFF), heroMuted: Color(0xFFA9C3B9),
    heroAccent: Color(0xFF4FE0A2), heroChip: Color(0x294FE0A2),
    track: Color(0xFFE3EAE6), grid: Color(0xFFE3EAE6), ghost: Color(0xFFB7C5BF),
    good: Color(0xFF2FBF85), bad: Color(0xFFE39A55), off: Color(0xFFB7C5BF),
    sheet: Color(0xFFFFFFFF), body: Color(0xFF0D2B24), accent: Color(0xFF0F8A5F),
    catColors: _catLight,
  );

  static const mentheDark = Tk(
    dark: true, graphite: false,
    bg: Color(0xFF08130F), card: Color(0xFF11211C), ink: Color(0xFFE8F1ED), muted: Color(0xFF9AADA5),
    faint: Color(0xFF8EA199), line: Color(0xFF1E322B), lineStrong: Color(0xFF3D5A4F),
    mint: Color(0xFF4FE0A2), mintSoft: Color(0xFF143A2C), mintFill: Color(0xFF3DD293), onMint: Color(0xFF08130F),
    warn: Color(0xFFF2A65A), warnSoft: Color(0xFF33230F), warnFill: Color(0xFFD9874A),
    chip: Color(0xFF182B25), fab: Color(0xFF4FE0A2), fabInk: Color(0xFF08130F),
    hero: Color(0xFF143A2C), heroInk: Color(0xFFE8F1ED), heroMuted: Color(0xFF9FC4B5),
    heroAccent: Color(0xFF4FE0A2), heroChip: Color(0x294FE0A2),
    track: Color(0xFF1F342C), grid: Color(0xFF1E322B), ghost: Color(0xFF3D5A4F),
    good: Color(0xFF3DD293), bad: Color(0xFFD9874A), off: Color(0xFF3D5A4F),
    sheet: Color(0xFF11211C), body: Color(0xFFE8F1ED), accent: Color(0xFF4FE0A2),
    catColors: _catDark,
  );

  static const ocean = Tk(
    dark: false, graphite: false,
    bg: Color(0xFFF2F5FA), card: Color(0xFFFFFFFF), ink: Color(0xFF0B1F3A), muted: Color(0xFF55627A),
    faint: Color(0xFF55627A), line: Color(0xFFE2E8F1), lineStrong: Color(0xFFB9C4D6),
    mint: Color(0xFF1259C3), mintSoft: Color(0xFFE1ECFB), mintFill: Color(0xFF3B82F6), onMint: Color(0xFFFFFFFF),
    warn: Color(0xFFB4580F), warnSoft: Color(0xFFFBE9D7), warnFill: Color(0xFFE39A55),
    chip: Color(0xFFEBF0F7), fab: Color(0xFF0B1F3A), fabInk: Color(0xFFFFFFFF),
    hero: Color(0xFF0B1F3A), heroInk: Color(0xFFFFFFFF), heroMuted: Color(0xFFA7B6CF),
    heroAccent: Color(0xFF7CB4FF), heroChip: Color(0x2E7CB4FF),
    track: Color(0xFFE2E8F1), grid: Color(0xFFE2E8F1), ghost: Color(0xFFB9C4D6),
    good: Color(0xFF3B82F6), bad: Color(0xFFE39A55), off: Color(0xFFB9C4D6),
    sheet: Color(0xFFFFFFFF), body: Color(0xFF0B1F3A), accent: Color(0xFF1259C3),
    catColors: _catLight,
  );

  static const prune = Tk(
    dark: false, graphite: false,
    bg: Color(0xFFF7F4FA), card: Color(0xFFFFFFFF), ink: Color(0xFF2A1838), muted: Color(0xFF665A72),
    faint: Color(0xFF665A72), line: Color(0xFFE9E2F1), lineStrong: Color(0xFFC9BCD8),
    mint: Color(0xFF6D3FD0), mintSoft: Color(0xFFEDE5FB), mintFill: Color(0xFF8B5CF6), onMint: Color(0xFFFFFFFF),
    warn: Color(0xFFB4580F), warnSoft: Color(0xFFFBE9D7), warnFill: Color(0xFFE39A55),
    chip: Color(0xFFF0EBF6), fab: Color(0xFF2A1838), fabInk: Color(0xFFFFFFFF),
    hero: Color(0xFF2A1838), heroInk: Color(0xFFFFFFFF), heroMuted: Color(0xFFBFAFD2),
    heroAccent: Color(0xFFC9AEFF), heroChip: Color(0x2EC9AEFF),
    track: Color(0xFFE9E2F1), grid: Color(0xFFE9E2F1), ghost: Color(0xFFC9BCD8),
    good: Color(0xFF8B5CF6), bad: Color(0xFFE39A55), off: Color(0xFFC9BCD8),
    sheet: Color(0xFFFFFFFF), body: Color(0xFF2A1838), accent: Color(0xFF6D3FD0),
    catColors: _catLight,
  );

  static const terracotta = Tk(
    dark: false, graphite: false,
    bg: Color(0xFFFAF5EF), card: Color(0xFFFFFFFF), ink: Color(0xFF3A2219), muted: Color(0xFF6E5A50),
    faint: Color(0xFF6E5A50), line: Color(0xFFEEE4D9), lineStrong: Color(0xFFD6C5B5),
    mint: Color(0xFF4F7A12), mintSoft: Color(0xFFEAF1DC), mintFill: Color(0xFF7FA83A), onMint: Color(0xFFFFFFFF),
    warn: Color(0xFFB42318), warnSoft: Color(0xFFFCE7E4), warnFill: Color(0xFFE0614F),
    chip: Color(0xFFF4ECE3), fab: Color(0xFFA9471F), fabInk: Color(0xFFFFFFFF),
    hero: Color(0xFFA9471F), heroInk: Color(0xFFFFFFFF), heroMuted: Color(0xFFF6D6C6),
    heroAccent: Color(0xFFFFE3A3), heroChip: Color(0x33FFE3A3),
    track: Color(0xFFEEE4D9), grid: Color(0xFFEEE4D9), ghost: Color(0xFFD6C5B5),
    good: Color(0xFF7FA83A), bad: Color(0xFFE0614F), off: Color(0xFFD6C5B5),
    sheet: Color(0xFFFFFFFF), body: Color(0xFF3A2219), accent: Color(0xFF4F7A12),
    catColors: _catLight,
  );

  static const oceanDark = Tk(
    dark: true, graphite: false,
    bg: Color(0xFF070E1A), card: Color(0xFF101B2E), ink: Color(0xFFE6EDF7), muted: Color(0xFF9AA8BE),
    faint: Color(0xFF8A98AE), line: Color(0xFF1C2A42), lineStrong: Color(0xFF3A4F72),
    mint: Color(0xFF7CB4FF), mintSoft: Color(0xFF142744), mintFill: Color(0xFF4D94FF), onMint: Color(0xFF070E1A),
    warn: Color(0xFFF2A65A), warnSoft: Color(0xFF33230F), warnFill: Color(0xFFD9874A),
    chip: Color(0xFF16233A), fab: Color(0xFF7CB4FF), fabInk: Color(0xFF070E1A),
    hero: Color(0xFF13284A), heroInk: Color(0xFFE6EDF7), heroMuted: Color(0xFFA3B8D6),
    heroAccent: Color(0xFF7CB4FF), heroChip: Color(0x297CB4FF),
    track: Color(0xFF1D2C46), grid: Color(0xFF1C2A42), ghost: Color(0xFF3A4F72),
    good: Color(0xFF4D94FF), bad: Color(0xFFD9874A), off: Color(0xFF3A4F72),
    sheet: Color(0xFF101B2E), body: Color(0xFFE6EDF7), accent: Color(0xFF7CB4FF),
    catColors: _catDark,
  );

  static const pruneDark = Tk(
    dark: true, graphite: false,
    bg: Color(0xFF110A18), card: Color(0xFF1C1326), ink: Color(0xFFF0E9F7), muted: Color(0xFFABA0B8),
    faint: Color(0xFF9C90AA), line: Color(0xFF2A1F38), lineStrong: Color(0xFF4C3B62),
    mint: Color(0xFFC9AEFF), mintSoft: Color(0xFF2B1E44), mintFill: Color(0xFFA07CF8), onMint: Color(0xFF110A18),
    warn: Color(0xFFF2A65A), warnSoft: Color(0xFF33230F), warnFill: Color(0xFFD9874A),
    chip: Color(0xFF241A31), fab: Color(0xFFC9AEFF), fabInk: Color(0xFF110A18),
    hero: Color(0xFF2C1C45), heroInk: Color(0xFFF0E9F7), heroMuted: Color(0xFFC2B0D9),
    heroAccent: Color(0xFFC9AEFF), heroChip: Color(0x29C9AEFF),
    track: Color(0xFF2C2140), grid: Color(0xFF2A1F38), ghost: Color(0xFF4C3B62),
    good: Color(0xFFA07CF8), bad: Color(0xFFD9874A), off: Color(0xFF4C3B62),
    sheet: Color(0xFF1C1326), body: Color(0xFFF0E9F7), accent: Color(0xFFC9AEFF),
    catColors: _catDark,
  );

  static const terracottaDark = Tk(
    dark: true, graphite: false,
    bg: Color(0xFF150D09), card: Color(0xFF22160F), ink: Color(0xFFF5EBE3), muted: Color(0xFFB8A598),
    faint: Color(0xFFA8968A), line: Color(0xFF33241A), lineStrong: Color(0xFF5A4232),
    mint: Color(0xFFA8D46A), mintSoft: Color(0xFF26301A), mintFill: Color(0xFF8DBB4A), onMint: Color(0xFF150D09),
    warn: Color(0xFFF28B7A), warnSoft: Color(0xFF3A1A15), warnFill: Color(0xFFD9634F),
    chip: Color(0xFF2B1D14), fab: Color(0xFFF0A27A), fabInk: Color(0xFF150D09),
    hero: Color(0xFF4A2414), heroInk: Color(0xFFF5EBE3), heroMuted: Color(0xFFE0BFAE),
    heroAccent: Color(0xFFFFE3A3), heroChip: Color(0x33FFE3A3),
    track: Color(0xFF33241A), grid: Color(0xFF33241A), ghost: Color(0xFF5A4232),
    good: Color(0xFF8DBB4A), bad: Color(0xFFD9634F), off: Color(0xFF5A4232),
    sheet: Color(0xFF22160F), body: Color(0xFFF5EBE3), accent: Color(0xFFA8D46A),
    catColors: _catDark,
  );

  static const graphiteDark = Tk(
    dark: true, graphite: true,
    bg: Color(0xFF141416), card: Color(0xFF1C1C20), ink: Color(0xFFFAFAFA), muted: Color(0xFF9A9AA2),
    faint: Color(0xFF74747C), line: Color(0xFF26262B), lineStrong: Color(0xFF36363C),
    mint: Color(0xFF4ADE80), mintSoft: Color(0x1F4ADE80), mintFill: Color(0xFFFAFAFA), onMint: Color(0xFF141416),
    warn: Color(0xFFFF5A5F), warnSoft: Color(0x1FFF5A5F), warnFill: Color(0xFFFF5A5F),
    chip: Color(0xFF1C1C20), fab: Color(0xFFD93B40), fabInk: Color(0xFFFFFFFF),
    hero: Color(0xFF141416), heroInk: Color(0xFFFAFAFA), heroMuted: Color(0xFF9A9AA2),
    heroAccent: Color(0xFFFAFAFA), heroChip: Color(0x00000000),
    track: Color(0xFF36363C), grid: Color(0xFF26262B), ghost: Color(0xFF4A4A52),
    good: Color(0xFF3FCB72), bad: Color(0xFFFF5A5F), off: Color(0xFF36363C),
    sheet: Color(0xFF1C1C20), body: Color(0xFFD4D4D4), accent: Color(0xFFFF5A5F),
    catColors: _catDark,
  );

  static const graphiteLight = Tk(
    dark: false, graphite: true,
    bg: Color(0xFFF7F7F8), card: Color(0xFFFFFFFF), ink: Color(0xFF141416), muted: Color(0xFF6B6B73),
    faint: Color(0xFF8E8E96), line: Color(0xFFE6E6EA), lineStrong: Color(0xFFD4D4DA),
    mint: Color(0xFF15803D), mintSoft: Color(0x1F15803D), mintFill: Color(0xFF141416), onMint: Color(0xFFFFFFFF),
    warn: Color(0xFFD12F35), warnSoft: Color(0x1FD12F35), warnFill: Color(0xFFD12F35),
    chip: Color(0xFFFFFFFF), fab: Color(0xFFD93B40), fabInk: Color(0xFFFFFFFF),
    hero: Color(0xFFF7F7F8), heroInk: Color(0xFF141416), heroMuted: Color(0xFF6B6B73),
    heroAccent: Color(0xFF141416), heroChip: Color(0x00000000),
    track: Color(0xFFD4D4DA), grid: Color(0xFFE6E6EA), ghost: Color(0xFFC4C4CA),
    good: Color(0xFF22A55A), bad: Color(0xFFD12F35), off: Color(0xFFD4D4DA),
    sheet: Color(0xFFFFFFFF), body: Color(0xFF3A3A40), accent: Color(0xFFD12F35),
    catColors: _catLight,
  );

  ThemeData material() {
    final scheme = ColorScheme(
      brightness: dark ? Brightness.dark : Brightness.light,
      primary: graphite ? fab : (dark ? mint : ink),
      onPrimary: graphite ? fabInk : (dark ? onMint : card),
      secondary: mint,
      onSecondary: onMint,
      error: warn,
      onError: fabInk,
      surface: sheet,
      onSurface: ink,
    );
    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      fontFamily: font,
      splashFactory: InkRipple.splashFactory,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: graphite ? fab : mint,
        selectionColor: (graphite ? fab : mint).withValues(alpha: 0.3),
        selectionHandleColor: graphite ? fab : mint,
      ),
      datePickerTheme: DatePickerThemeData(backgroundColor: sheet, headerBackgroundColor: graphite ? sheet : hero),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: graphite ? sheet : hero,
        contentTextStyle: TextStyle(fontFamily: font, color: graphite ? ink : heroInk, fontSize: 14),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class TkScope extends InheritedWidget {
  final Tk tk;
  const TkScope({super.key, required this.tk, required super.child});

  static Tk of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<TkScope>()!.tk;

  @override
  bool updateShouldNotify(TkScope old) => old.tk != tk;
}
