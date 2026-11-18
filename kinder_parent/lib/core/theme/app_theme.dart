import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Kolory wspólne z panelem admina (kinder_admin: plugins/vuetify.ts, App.vue).
class AppColors {
  static const background = Color(0xFFFDF5EA); // kremowe tło
  static const surface = Colors.white;
  static const primary = Color(0xFFC2410C); // rdzawy pomarańcz (przyciski)
  static const accent = Color(0xFFFCD34D); // żółty (logo)
  static const violet = Color(0xFFEDE9FE); // pastelowy fiolet (pasek menu)
  static const violetText = Color(0xFF4C1D95);
  static const violetMuted = Color(0xFF7C3AED);
  static const violetDeep = Color(0xFF5B21B6); // opisy na fioletowym tle

  /// Gradient panelu marki – ten sam co w logowaniu do panelu (LoginView.vue)
  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEDE9FE), Color(0xFFF5F0FF), Color(0xFFFDE7C8)],
    stops: [0, 0.55, 1],
  );
  static const ink = Color(0xFF1C1917); // główny tekst
  static const inkMuted = Color(0xFF57534E);
  static const border = Color(0xFFF3E6D3); // ramki kart
  static const soft = Color(0xFFF7F1E8); // tło ikon i przycisków
  static const error = Color(0xFFDC2626);
}

class GroupColor {
  final Color bg;
  final Color text;
  final Color avatar;

  const GroupColor(this.bg, this.text, this.avatar);
}

/// Pastelowe kolory grup – jak w panelu (src/groupColors.ts):
/// przydzielane po kolejności grup posortowanych alfabetycznie.
class GroupColors {
  static const palette = [
    GroupColor(Color(0xFFEDE9FE), Color(0xFF5B21B6), Color(0xFFC4B5FD)),
    GroupColor(Color(0xFFFFEDD5), Color(0xFF9A3412), Color(0xFFFDBA74)),
    GroupColor(Color(0xFFDCFCE7), Color(0xFF166534), Color(0xFF86EFAC)),
    GroupColor(Color(0xFFE0F2FE), Color(0xFF075985), Color(0xFF7DD3FC)),
    GroupColor(Color(0xFFFCE7F3), Color(0xFF9D174D), Color(0xFFF9A8D4)),
    GroupColor(Color(0xFFFEF9C3), Color(0xFF854D0E), Color(0xFFFDE047)),
  ];
  static const none = GroupColor(
    Color(0xFFF5F5F4),
    Color(0xFF57534E),
    Color(0xFFE7E5E4),
  );

  static GroupColor of(Map<String, String> groupNames, String? groupId) {
    final ids = groupNames.keys.toList()
      ..sort((a, b) => groupNames[a]!.compareTo(groupNames[b]!));
    final i = ids.indexOf(groupId ?? '');
    return i < 0 ? none : palette[i % palette.length];
  }
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.violetText,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );

    final text = GoogleFonts.nunitoTextTheme(
      base.textTheme,
    ).apply(bodyColor: AppColors.ink, displayColor: AppColors.ink);

    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.border, width: 2),
    );

    return base.copyWith(
      textTheme: text,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        prefixIconColor: AppColors.inkMuted,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          textStyle: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.violetText,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.violet,
        height: 72,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.violetText
                : AppColors.inkMuted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelMedium?.copyWith(
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? AppColors.violetText
                : AppColors.inkMuted,
          ),
        ),
      ),
      badgeTheme: const BadgeThemeData(backgroundColor: AppColors.primary),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
    );
  }
}
