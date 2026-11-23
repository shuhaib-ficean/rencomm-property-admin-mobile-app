import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models/country_config.dart';
import '../../../core/utils/locale_helper.dart';
import '../../../data/repositories/settings_repository.dart';

// Events
abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object> get props => [];
}

class SettingsThemeChanged extends SettingsEvent {
  final ThemeMode themeMode;
  const SettingsThemeChanged(this.themeMode);

  @override
  List<Object> get props => [themeMode];
}

class SettingsLanguageChanged extends SettingsEvent {
  final Locale locale;
  const SettingsLanguageChanged(this.locale);

  @override
  List<Object> get props => [locale];
}

class SettingsCountryChanged extends SettingsEvent {
  final CountryConfig country;
  const SettingsCountryChanged(this.country);

  @override
  List<Object> get props => [country];
}

class SettingsLoad extends SettingsEvent {}

// State
class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final Locale? locale;
  final CountryConfig country;

  const SettingsState({
    this.themeMode = ThemeMode.light,
    this.locale,
    this.country = CountryConfig.defaultCountry,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    CountryConfig? country,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      country: country ?? this.country,
    );
  }

  @override
  List<Object?> get props => [themeMode, locale, country];
}

// Bloc
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository? _settingsRepository;

  SettingsBloc({SettingsRepository? settingsRepository})
      : _settingsRepository = settingsRepository,
        super(const SettingsState()) {
    on<SettingsLoad>(_onLoad);
    on<SettingsThemeChanged>(_onThemeChanged);
    on<SettingsLanguageChanged>(_onLanguageChanged);
    on<SettingsCountryChanged>(_onCountryChanged);
    // Load saved settings on initialization
    add(SettingsLoad());
  }

  Future<void> _onLoad(SettingsLoad event, Emitter<SettingsState> emit) async {
    final savedLocaleCode = await LocaleHelper.getLocale();
    final locale = savedLocaleCode != null ? Locale(savedLocaleCode) : null;

    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDark') ?? false;
    final cachedCountryCode = prefs.getString('selected_country_code') ?? 'QA';
    final country = CountryConfig.fromCode(cachedCountryCode);

    emit(state.copyWith(
      locale: locale,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      country: country,
    ));

    // Synchronize with backend settings if repository is connected
    if (_settingsRepository != null) {
      try {
        final serverSettings = await _settingsRepository!.getSettings();
        if (serverSettings != null) {
          final serverCountry = serverSettings['country'] as String?;
          if (serverCountry != null && serverCountry.isNotEmpty) {
            final syncedCountry = CountryConfig.fromCode(serverCountry);
            await prefs.setString('selected_country_code', syncedCountry.code);
            emit(state.copyWith(country: syncedCountry));
          } else {
            final currencyObj = serverSettings['currency'] as Map<String, dynamic>?;
            final serverCurrencyCode = currencyObj?['code'] ?? serverSettings['currencyCode'];
            if (serverCurrencyCode != null) {
              final matched = CountryConfig.supportedCountries.firstWhere(
                (c) => c.currency.toUpperCase() == serverCurrencyCode.toString().toUpperCase(),
                orElse: () => CountryConfig.defaultCountry,
              );
              await prefs.setString('selected_country_code', matched.code);
              emit(state.copyWith(country: matched));
            }
          }
        }
      } catch (_) {
        // Safe fallback to locally stored settings
      }
    }
  }

  Future<void> _onThemeChanged(
      SettingsThemeChanged event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(themeMode: event.themeMode));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', event.themeMode == ThemeMode.dark);
  }

  Future<void> _onLanguageChanged(
      SettingsLanguageChanged event, Emitter<SettingsState> emit) async {
    await LocaleHelper.setLocale(event.locale.languageCode);
    emit(state.copyWith(locale: event.locale));
  }

  Future<void> _onCountryChanged(
      SettingsCountryChanged event, Emitter<SettingsState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_country_code', event.country.code);
    emit(state.copyWith(country: event.country));

    // Update backend settings
    if (_settingsRepository != null) {
      try {
        await _settingsRepository!.updateRegionalSettings(
          countryCode: event.country.code,
          currencyCode: event.country.currency,
          currencySymbol: event.country.currencySymbol,
        );
      } catch (_) {
        // Handled in repository
      }
    }
  }
}
