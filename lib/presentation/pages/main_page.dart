import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../blocs/navigation/navigation_cubit.dart';
import 'dashboard/dashboard_page.dart';
import 'people/tenants_page.dart';
import 'payments/payments_page.dart';
import 'profile/profile_page.dart';

import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/auth/auth_state.dart';
import '../../core/utils/permission_helper.dart';

import 'repairs/staff_repairs_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  void initState() {
    super.initState();
    // Refresh user profile and permissions on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthBloc>().add(const AuthGetCurrentUser());
    });
  }

  bool _isStaff(AuthState authState) {
    if (authState is AuthAuthenticated) {
      return authState.user.role.toLowerCase() == 'staff';
    }
    return false;
  }

  List<Widget> _getPages(BuildContext context, AuthState authState) {
    if (_isStaff(authState)) {
      return const [
        StaffRepairsPage(),
        ProfilePage(),
      ];
    }

    final pages = <Widget>[];
    if (PermissionHelper.hasPermission(context, 'view_analytics')) {
      pages.add(const DashboardPage());
    }
    if (PermissionHelper.hasPermission(context, 'view_tenants')) {
      pages.add(const TenantsPage());
    }
    if (PermissionHelper.hasPermission(context, 'view_payments')) {
      pages.add(const PaymentsPage());
    }
    pages.add(const ProfilePage());
    return pages;
  }

  void _onItemTapped(int index) {
    context.read<NavigationCubit>().setIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final isStaffUser = _isStaff(authState);
        final pages = _getPages(context, authState);

        return BlocBuilder<NavigationCubit, int>(
          builder: (context, currentIndex) {
            // Ensure currentIndex is within bounds if tabs changed
            final actualIndex = currentIndex >= pages.length ? 0 : currentIndex;

            return Scaffold(
              body: pages[actualIndex],
              bottomNavigationBar: pages.length < 2
                  ? null
                  : Directionality(
                      textDirection: TextDirection.ltr,
                      child: BottomNavigationBar(
                        type: BottomNavigationBarType.fixed,
                        backgroundColor: Colors.white,
                        selectedItemColor: const Color(0xFF2F92D0),
                        unselectedItemColor: const Color(0xFF717171),
                        selectedLabelStyle: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w700, fontSize: 11),
                        unselectedLabelStyle: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w500, fontSize: 11),
                        elevation: 8,
                        showUnselectedLabels: true,
                        items: isStaffUser
                            ? const <BottomNavigationBarItem>[
                                BottomNavigationBarItem(
                                  icon: Icon(Icons.build_outlined),
                                  activeIcon: Icon(Icons.build_rounded),
                                  label: 'My Tasks',
                                ),
                                BottomNavigationBarItem(
                                  icon: Icon(Icons.person_outline),
                                  activeIcon: Icon(Icons.person),
                                  label: 'Profile',
                                ),
                              ]
                            : <BottomNavigationBarItem>[
                                if (PermissionHelper.hasPermission(
                                    context, 'view_analytics'))
                                  BottomNavigationBarItem(
                                    icon: const Icon(Icons.dashboard),
                                    label: AppLocalizations.of(context)!.dashboard,
                                  ),
                                if (PermissionHelper.hasPermission(
                                    context, 'view_tenants'))
                                  BottomNavigationBarItem(
                                      icon: const Icon(Icons.people),
                                      label: AppLocalizations.of(context)!.tenants),
                                if (PermissionHelper.hasPermission(
                                    context, 'view_payments'))
                                  BottomNavigationBarItem(
                                      icon: const Icon(Icons.payment),
                                      label: AppLocalizations.of(context)!.payments),
                                BottomNavigationBarItem(
                                    icon: const Icon(Icons.person),
                                    label: AppLocalizations.of(context)!.profile),
                              ],
                        currentIndex: actualIndex,
                        onTap: _onItemTapped,
                      ),
                    ),
            );
          },
        );
      },
    );
  }
}
