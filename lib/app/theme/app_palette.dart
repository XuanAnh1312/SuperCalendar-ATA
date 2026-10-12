import 'package:flutter/material.dart';

/// Every color a screen may use. Built from a theme's primary color and the
/// light / dark setting, so screens never hard-code colors.
class AppPalette {
  const AppPalette({
    required this.dark,
    required this.background,
    required this.surface,
    required this.border,
    required this.subtle,
    required this.text,
    required this.muted,
    required this.faint,
    required this.primary,
    required this.primaryTint,
    required this.primarySoft,
    required this.pink,
    required this.blue,
    required this.green,
    required this.yellow,
    required this.purple,
    required this.note,
    required this.lockTop,
    required this.lockMid,
    required this.lockBottom,
    required this.lockCard,
    required this.shadeTop,
    required this.shadeBottom,
    required this.dotDone,
    required this.dotIdle,
  });

  factory AppPalette.build({required Color primary, required bool dark}) {
    if (dark) {
      const surface = Color(0xFF1F2126);
      return AppPalette(
        dark: true,
        background: const Color(0xFF15161A),
        surface: surface,
        border: const Color(0xFF2E3138),
        subtle: const Color(0xFF24262C),
        text: const Color(0xFFF1F2F4),
        muted: const Color(0xFFA0A5AF),
        faint: const Color(0xFF6B7079),
        primary: Color.lerp(primary, Colors.white, 0.18)!,
        primaryTint: Color.lerp(primary, Colors.white, 0.3)!,
        primarySoft: Color.lerp(surface, primary, 0.28)!,
        pink: const Color(0xFF3F2C35),
        blue: const Color(0xFF27323F),
        green: const Color(0xFF24382E),
        yellow: const Color(0xFF3D3724),
        purple: const Color(0xFF322D45),
        note: const Color(0xFF3D3724),
        lockTop: const Color(0xFF211C22),
        lockMid: const Color(0xFF17181C),
        lockBottom: const Color(0xFF1E1B2A),
        lockCard: const Color(0xFF22242A),
        shadeTop: const Color(0xFF1B1A1F),
        shadeBottom: const Color(0xFF121317),
        dotDone: const Color(0xFF3B6E57),
        dotIdle: const Color(0xFF3A3D45),
      );
    }
    const surface = Color(0xFFFFFFFF);
    return AppPalette(
      dark: false,
      background: const Color(0xFFF8F9FB),
      surface: surface,
      border: const Color(0xFFE6E8EC),
      subtle: const Color(0xFFF1F2F5),
      text: const Color(0xFF202124),
      muted: const Color(0xFF767B85),
      faint: const Color(0xFFA9AEB7),
      primary: primary,
      primaryTint: Color.lerp(primary, Colors.white, 0.13)!,
      primarySoft: Color.lerp(surface, primary, 0.11)!,
      pink: const Color(0xFFF7DDE7),
      blue: const Color(0xFFDDEBFA),
      green: const Color(0xFFDDF1E6),
      yellow: const Color(0xFFF8EFCB),
      purple: const Color(0xFFE9E2FA),
      note: const Color(0xFFFFF9DA),
      lockTop: const Color(0xFFF8EFF3),
      lockMid: const Color(0xFFFCFCFE),
      lockBottom: const Color(0xFFEDE9F8),
      lockCard: const Color(0xFFFDFCFE),
      shadeTop: const Color(0xFFF4F1F6),
      shadeBottom: const Color(0xFFE7E9EF),
      dotDone: const Color(0xFFBFE0CF),
      dotIdle: const Color(0xFFD5D8DE),
    );
  }

  final bool dark;
  final Color background;
  final Color surface;
  final Color border;

  /// Slightly darker than [background]; used for inset panels.
  final Color subtle;
  final Color text;
  final Color muted;
  final Color faint;
  final Color primary;
  final Color primaryTint;
  final Color primarySoft;

  // Pastel surfaces.
  final Color pink;
  final Color blue;
  final Color green;
  final Color yellow;
  final Color purple;
  final Color note;

  // Lock screen and notification shade backgrounds.
  final Color lockTop;
  final Color lockMid;
  final Color lockBottom;
  final Color lockCard;
  final Color shadeTop;
  final Color shadeBottom;

  // Habit week dots.
  final Color dotDone;
  final Color dotIdle;
}
