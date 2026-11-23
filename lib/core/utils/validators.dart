import 'package:admin_mobile_app/l10n/app_localizations.dart';

import 'package:flutter/src/widgets/framework.dart';

class Validators {
  static String? email(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppLocalizations.of(context)!.emailIsRequired;
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
    if (!emailRegex.hasMatch(value.trim())) {
      return AppLocalizations.of(context)!.enterValidEmail;
    }
    return null;
  }

  static String? required(BuildContext context, String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? AppLocalizations.of(context)!.thisField} ${AppLocalizations.of(context)!.isRequired}';
    }
    return null;
  }

  static String? minLength(BuildContext context, String? value, int minLength, {String? fieldName}) {
    if (value == null || value.trim().length < minLength) {
      return '${fieldName ?? AppLocalizations.of(context)!.thisField} ${AppLocalizations.of(context)!.mustBeAtleast} $minLength ${AppLocalizations.of(context)!.characters}';
    }
    return null;
  }

  static String? phone(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppLocalizations.of(context)!.phoneNumberIsRequired;
    }
    
    final phoneRegex = RegExp(r'^\+?[0-9]{8,15}$');
    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[\s\-\(\)]'), ''))) {
      return AppLocalizations.of(context)!.enterValidPhoneNumber;
    }
    return null;
  }
}
