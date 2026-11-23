import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../presentation/blocs/auth/auth_bloc.dart';
import '../../presentation/blocs/auth/auth_state.dart';

class PermissionHelper {
  static bool hasPermission(BuildContext context, String permission) {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      if (authState.user.role == 'admin') return true;
      return authState.user.permissions.contains(permission);
    }
    return false;
  }

  static bool isAdmin(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      return authState.user.role == 'admin';
    }
    return false;
  }
}
