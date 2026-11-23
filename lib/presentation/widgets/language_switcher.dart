import 'package:admin_mobile_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/localization/app_localizations_helper.dart';
import '../../core/utils/locale_helper.dart';

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context);

    return PopupMenuButton<Locale>(
      icon: const Icon(Icons.language),
      tooltip: AppLocalizations.of(context)!.changeLanguage,
      onSelected: (Locale locale) async {
        await LocaleHelper.setLocale(locale.languageCode);
        // Restart app to apply new locale
        // In a real app, you'd use a state management solution to update locale
        // For now, we'll just save it and it will apply on next app start
      },
      itemBuilder: (BuildContext context) {
        return AppLocalizationsHelper.supportedLocales.map((Locale locale) {
          final isSelected = currentLocale.languageCode == locale.languageCode;
          return PopupMenuItem<Locale>(
            value: locale,
            child: Row(
              children: [
                if (isSelected)
                  const Icon(Icons.check, size: 20)
                else
                  const SizedBox(width: 20),
                const SizedBox(width: 8),
                Text(
                  locale.languageCode == 'en' ? 'English' : 'العربية',
                  style: GoogleFonts.montserrat(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
    );
  }
}
