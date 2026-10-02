import 'dart:math';

import 'package:flutter/material.dart';

import 'format.dart';
import 'store.dart';
import 'theme.dart';

void _dashed(Canvas c, Path path, Paint p, double dash, double gap) {
  for (final m in path.computeMetrics()) {
    for (double d = 0; d < m.length; d += dash + gap) {
      c.drawPath(m.extractPath(d, min(d + dash, m.length)), p);
    }
  }
}

Path _poly(List<Offset> pts) {
  final p = Path();
  for (var i = 0; i < pts.length; i++) {
    i == 0 ? p.moveTo(pts[i].dx, pts[i].dy) : p.lineTo(pts[i].dx, pts[i].dy);
  }
  return p;
}

double _niceStep(double max) {
  if (max <= 0) return 100;
  final raw = max / 3;
  final mag = pow(10, (log(raw) / ln10).floor()).toDouble();
  for (final m in [1, 2, 2.5, 5, 10]) {
    if (m * mag >= raw) return m * mag;
  }
  return 10 * mag;
}

/// Cumul des dépenses du mois : réel (plein), estimé (pointillés), mois précédent (gris), budget.
class ForecastChart extends StatelessWidget {
  final MonthStats s;
  final double height;
  const ForecastChart(this.s, {super.key, this.height = 210});

  @override
  Widget build(BuildContext context) {
    final t = TkScope.of(context);
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _ForecastPainter(s, t)),
    );
  }
}

class _ForecastPainter extends CustomPainter {
  final MonthStats s;
  final Tk t;
  _ForecastPainter(this.s, this.t);

  TextPainter _text(String txt, Color c, {bool bold = false}) => TextPainter(
        text: TextSpan(
            text: txt,
            style: TextStyle(
                fontFamily: t.graphite ? 'GeistMono' : 'Manrope',
                fontSize: 10,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                color: c)),
        textDirection: TextDirection.ltr,
      )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    final g = t.graphite;
    final left = g ? 2.0 : 34.0, right = size.width - 2, top = 10.0, bottom = size.height - 26;
    final endV = s.forecastCurve.isEmpty ? s.spent : s.forecastCurve.last;
    final prevMax = s.prevCurve.isEmpty ? 0.0 : s.prevCurve.last;
    final maxV = [s.budget, endV, prevMax, s.spent, 10.0].reduce(max) * 1.08;
    double x(num d, int dim) => left + (d - 1) / max(1, dim - 1) * (right - left);
    double y(double v) => bottom - v / maxV * (bottom - top);

    final grid = Paint()
      ..color = t.grid
      ..strokeWidth = 1;
    final step = _niceStep(maxV);
    for (double v = step; v < maxV; v += step) {
      if (s.budget > 0 && (v - s.budget).abs() < step * 0.35) continue;
      canvas.drawLine(Offset(left, y(v)), Offset(right, y(v)), grid);
      final tp = _text(num0(v), g ? t.faint : t.muted);
      tp.paint(canvas, g ? Offset(right - tp.width, y(v) - tp.height - 2) : Offset(0, y(v) - tp.height / 2));
    }
    canvas.drawLine(Offset(left, bottom), Offset(right, bottom), Paint()
      ..color = g ? t.lineStrong : t.grid
      ..strokeWidth = 1);

    if (s.budget > 0) {
      final bp = Paint()
        ..color = g ? t.faint : t.warn
        ..strokeWidth = 1;
      _dashed(canvas, Path()..moveTo(left, y(s.budget))..lineTo(right, y(s.budget)), bp, 2, 4);
      final tp = _text(g ? 'BUDGET ${num0(s.budget)}' : num0(s.budget), g ? t.muted : t.warn, bold: true);
      tp.paint(canvas, g ? Offset(right - tp.width, y(s.budget) + 4) : Offset(0, y(s.budget) - tp.height / 2));
    }

    // Mois précédent
    if (s.prevCurve.isNotEmpty && s.prevFull > 0) {
      final pts = [for (var i = 0; i < s.prevCurve.length; i++) Offset(x(i + 1, s.prevDim), y(s.prevCurve[i]))];
      canvas.drawPath(
          _poly(pts),
          Paint()
            ..color = t.ghost
            ..style = PaintingStyle.stroke
            ..strokeWidth = g ? 1.2 : 1.5
            ..strokeJoin = StrokeJoin.round
            ..strokeCap = StrokeCap.round);
    }

    final tx = x(s.day, s.dim), ty = y(s.spent);
    canvas.drawLine(Offset(tx, top), Offset(tx, bottom), grid);

    final lineColor = g ? t.ink : t.mint;
    // Estimé
    if (s.forecastCurve.length > 1) {
      final pts = [for (var i = 0; i < s.forecastCurve.length; i++) Offset(x(s.day + i, s.dim), y(s.forecastCurve[i]))];
      _dashed(
          canvas,
          _poly(pts),
          Paint()
            ..color = g ? t.muted : t.mint
            ..style = PaintingStyle.stroke
            ..strokeWidth = g ? 1.5 : 2
            ..strokeCap = StrokeCap.round,
          g ? 2 : 4,
          g ? 4 : 5);
      final e = pts.last;
      canvas.drawCircle(e, 3.5, Paint()..color = g ? t.bg : t.card);
      canvas.drawCircle(
          e,
          3.5,
          Paint()
            ..color = g ? t.muted : t.mint
            ..style = PaintingStyle.stroke
            ..strokeWidth = g ? 1.5 : 2);
    }
    // Réel
    final real = [for (var i = 0; i < s.realCurve.length; i++) Offset(x(i + 1, s.dim), y(s.realCurve[i]))];
    if (real.length > 1) {
      canvas.drawPath(
          _poly(real),
          Paint()
            ..color = lineColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = g ? 1.5 : 2.5
            ..strokeJoin = StrokeJoin.round
            ..strokeCap = StrokeCap.round);
    }
    if (!g) canvas.drawCircle(Offset(tx, ty), 6.5, Paint()..color = t.card);
    canvas.drawCircle(Offset(tx, ty), g ? 4 : 4.5, Paint()..color = g ? t.accent : t.mint);

    // Axe des jours
    final days = {1, 8, 15, 22, s.dim};
    for (final d in days) {
      if ((d - s.day).abs() <= 2 && d != s.day) continue;
      final tp = _text('$d', g ? t.faint : t.muted);
      tp.paint(canvas, Offset((x(d, s.dim) - tp.width / 2).clamp(0, size.width - tp.width), bottom + 10));
    }
    final tp = _text('${s.day}', g ? t.accent : t.mint, bold: true);
    tp.paint(canvas, Offset((tx - tp.width / 2).clamp(0, size.width - tp.width), bottom + 10));
  }

  @override
  bool shouldRepaint(_ForecastPainter old) => old.s != s || old.t != t;
}

/// Mini-courbe pour l'accueil.
class Sparkline extends StatelessWidget {
  final MonthStats s;
  final double height;
  final Color? color;
  const Sparkline(this.s, {super.key, this.height = 36, this.color});

  @override
  Widget build(BuildContext context) {
    final t = TkScope.of(context);
    return SizedBox(
        height: height, width: double.infinity, child: CustomPaint(painter: _SparkPainter(s, t, color)));
  }
}

class _SparkPainter extends CustomPainter {
  final MonthStats s;
  final Tk t;
  final Color? color;
  _SparkPainter(this.s, this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final g = t.graphite;
    final endV = s.forecastCurve.isEmpty ? s.spent : s.forecastCurve.last;
    final maxV = max(max(endV, s.spent), 1.0);
    final pad = 4.0;
    double x(num d) => pad + (d - 1) / max(1, s.dim - 1) * (size.width - 2 * pad);
    double y(double v) => size.height - pad - v / maxV * (size.height - 2 * pad);
    final c = color ?? (g ? t.ink : t.mint);
    final real = [for (var i = 0; i < s.realCurve.length; i++) Offset(x(i + 1), y(s.realCurve[i]))];
    final fc = [for (var i = 0; i < s.forecastCurve.length; i++) Offset(x(s.day + i), y(s.forecastCurve[i]))];
    final p = Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = g ? 1.5 : 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (fc.length > 1) {
      _dashed(canvas, _poly(fc), Paint()
        ..color = g ? t.muted : c
        ..style = PaintingStyle.stroke
        ..strokeWidth = g ? 1.5 : 2
        ..strokeCap = StrokeCap.round, g ? 2 : 3, 4);
    }
    if (real.length > 1) canvas.drawPath(_poly(real), p);
    if (real.isNotEmpty) canvas.drawCircle(real.last, g ? 4 : 3, Paint()..color = g ? t.accent : c);
  }

  @override
  bool shouldRepaint(_SparkPainter old) => old.s != s || old.t != t;
}
