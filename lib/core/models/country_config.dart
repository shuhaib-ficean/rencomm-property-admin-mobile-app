import 'package:equatable/equatable.dart';

class CountryConfig extends Equatable {
  final String name;
  final String code;
  final String flag;
  final String currency;
  final String currencySymbol;
  final String dialCode;
  final int phoneLength;

  const CountryConfig({
    required this.name,
    required this.code,
    required this.flag,
    required this.currency,
    required this.currencySymbol,
    required this.dialCode,
    required this.phoneLength,
  });

  static const CountryConfig defaultCountry = CountryConfig(
    name: 'Qatar',
    code: 'QA',
    flag: '🇶🇦',
    currency: 'QAR',
    currencySymbol: 'QR',
    dialCode: '+974',
    phoneLength: 8,
  );

  static const List<CountryConfig> supportedCountries = [
    CountryConfig(
      name: 'Qatar',
      code: 'QA',
      flag: '🇶🇦',
      currency: 'QAR',
      currencySymbol: 'QR',
      dialCode: '+974',
      phoneLength: 8,
    ),
    CountryConfig(
      name: 'United Arab Emirates',
      code: 'AE',
      flag: '🇦🇪',
      currency: 'AED',
      currencySymbol: 'AED',
      dialCode: '+971',
      phoneLength: 9,
    ),
    CountryConfig(
      name: 'Saudi Arabia',
      code: 'SA',
      flag: '🇸🇦',
      currency: 'SAR',
      currencySymbol: 'SAR',
      dialCode: '+966',
      phoneLength: 9,
    ),
    CountryConfig(
      name: 'Kuwait',
      code: 'KW',
      flag: '🇰🇼',
      currency: 'KWD',
      currencySymbol: 'KD',
      dialCode: '+965',
      phoneLength: 8,
    ),
    CountryConfig(
      name: 'Bahrain',
      code: 'BH',
      flag: '🇧🇭',
      currency: 'BHD',
      currencySymbol: 'BD',
      dialCode: '+973',
      phoneLength: 8,
    ),
    CountryConfig(
      name: 'Oman',
      code: 'OM',
      flag: '🇴🇲',
      currency: 'OMR',
      currencySymbol: 'OMR',
      dialCode: '+968',
      phoneLength: 8,
    ),
    CountryConfig(
      name: 'India',
      code: 'IN',
      flag: '🇮🇳',
      currency: 'INR',
      currencySymbol: '₹',
      dialCode: '+91',
      phoneLength: 10,
    ),
    CountryConfig(
      name: 'United Kingdom',
      code: 'GB',
      flag: '🇬🇧',
      currency: 'GBP',
      currencySymbol: '£',
      dialCode: '+44',
      phoneLength: 10,
    ),
    CountryConfig(
      name: 'United States',
      code: 'US',
      flag: '🇺🇸',
      currency: 'USD',
      currencySymbol: '\$',
      dialCode: '+1',
      phoneLength: 10,
    ),
  ];

  static CountryConfig fromCode(String? code) {
    if (code == null) return defaultCountry;
    return supportedCountries.firstWhere(
      (c) => c.code.toUpperCase() == code.toUpperCase(),
      orElse: () => defaultCountry,
    );
  }

  @override
  List<Object?> get props => [
        name,
        code,
        flag,
        currency,
        currencySymbol,
        dialCode,
        phoneLength,
      ];
}
