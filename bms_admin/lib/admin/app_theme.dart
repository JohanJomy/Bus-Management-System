import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Global notifier — flip this to switch the entire app between themes.
final ValueNotifier<bool> appIsDark = ValueNotifier(false);

// ── Colour tokens ────────────────────────────────────────────────────────────

// Light
const _lightBg = Color(0xFFF6F6F8);
const _lightSurface = Colors.white;
const _lightOnSurface = Color(0xFF1E293B);
const _lightOnSurfaceVariant = Color(0xFF64748B);
const _lightBorder = Color(0xFFE2E8F0);
const _lightInputFill = Color(0xFFF1F5F9);

// Dark
const _darkBg = Color(0xFF0F172A);
const _darkSurface = Color(0xFF1E293B);
const _darkOnSurface = Color(0xFFF1F5F9);
const _darkOnSurfaceVariant = Color(0xFF94A3B8);
const _darkBorder = Color(0xFF334155);
const _darkInputFill = Color(0xFF0F172A);

// ── Theme helpers ─────────────────────────────────────────────────────────────

bool isDark(BuildContext ctx) => Theme.of(ctx).brightness == Brightness.dark;

/// Card / panel background
Color surfaceColor(BuildContext ctx) =>
    isDark(ctx) ? _darkSurface : _lightSurface;

/// Page scaffold background
Color bgColor(BuildContext ctx) => isDark(ctx) ? _darkBg : _lightBg;

/// Primary label text
Color onSurface(BuildContext ctx) =>
    isDark(ctx) ? _darkOnSurface : _lightOnSurface;

/// Secondary / muted text
Color onSurfaceVariant(BuildContext ctx) =>
    isDark(ctx) ? _darkOnSurfaceVariant : _lightOnSurfaceVariant;

/// Card / input border
Color borderColor(BuildContext ctx) => isDark(ctx) ? _darkBorder : _lightBorder;

/// Text-field fill
Color inputFillColor(BuildContext ctx) =>
    isDark(ctx) ? _darkInputFill : _lightInputFill;

// ── ThemeData ─────────────────────────────────────────────────────────────────

ThemeData lightTheme() => ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: _lightBg,
  primaryColor: const Color(0xFF195DE6),
  useMaterial3: true,
  textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF195DE6),
    brightness: Brightness.light,
    surface: _lightSurface,
    onSurface: _lightOnSurface,
    onSurfaceVariant: _lightOnSurfaceVariant,
  ),
);

ThemeData darkTheme() => ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: _darkBg,
  primaryColor: const Color(0xFF195DE6),
  useMaterial3: true,
  textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF195DE6),
    brightness: Brightness.dark,
    surface: _darkSurface,
    onSurface: _darkOnSurface,
    onSurfaceVariant: _darkOnSurfaceVariant,
  ),
);
