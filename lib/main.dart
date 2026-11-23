import 'package:admin_mobile_app/l10n/app_localizations.dart';
import 'package:admin_mobile_app/presentation/blocs/tenant/tenant_payment_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/di/injection_container.dart';
import 'core/network/api_client.dart';
import 'core/routes/app_routes_list.dart';
import 'presentation/pages/splash/splash_page.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/global_keys.dart';
import 'data/repositories/property_repository.dart';
import 'data/repositories/tenant_repository.dart';
import 'data/repositories/role_repository.dart';
import 'presentation/blocs/role/role_bloc.dart';
import 'data/repositories/staff_repository.dart';
import 'data/repositories/payment_repository.dart';
import 'data/repositories/analytics_repository.dart';
import 'data/repositories/notification_repository.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/property/property_bloc.dart';
import 'presentation/blocs/tenant/tenant_bloc.dart';
import 'presentation/blocs/staff/staff_bloc.dart';
import 'presentation/blocs/payment/payment_bloc.dart';
import 'presentation/blocs/analytics/analytics_bloc.dart';
import 'presentation/blocs/notification/notification_bloc.dart';
import 'presentation/blocs/settings/settings_bloc.dart';
import 'presentation/blocs/navigation/navigation_cubit.dart';
import 'presentation/blocs/expense/expense_bloc.dart';
import 'presentation/blocs/expense/expense_event.dart';
import 'data/repositories/expense_repository.dart';
import 'presentation/blocs/lease/lease_bloc.dart';
import 'data/repositories/lease_repository.dart';
import 'presentation/blocs/amenity/amenity_bloc.dart';
import 'presentation/blocs/amenity/amenity_event.dart';
import 'data/repositories/amenity_repository.dart';
import 'presentation/blocs/billing/billing_bloc.dart';
import 'presentation/blocs/billing/billing_event.dart';
import 'data/repositories/subscription_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'presentation/blocs/auth/auth_state.dart';
import 'core/services/enquiry_service.dart';
import 'presentation/blocs/enquiry/enquiry_bloc.dart';
import 'presentation/blocs/enquiry/enquiry_event.dart';
import 'core/services/department_service.dart';
import 'presentation/blocs/department/department_bloc.dart';
import 'presentation/blocs/department/department_event.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize DI
  await configureDependencies();

  // Get ApiClient from DI for legacy repositories
  final apiClient = getIt<ApiClient>();

  // Initialize Repositories (Legacy)
  final propertyRepository = PropertyRepository(apiClient);
  final tenantRepository = TenantRepository(apiClient);
  final staffRepository = StaffRepository(apiClient);
  final roleRepository = RoleRepository(apiClient);
  final paymentRepository = PaymentRepository(apiClient);
  getIt.registerLazySingleton<PaymentRepository>(() => paymentRepository);
  final analyticsRepository = AnalyticsRepository(apiClient);
  final notificationRepository = NotificationRepository(apiClient);
  final expenseRepository = ExpenseRepository(apiClient: apiClient);
  final leaseRepository = LeaseRepository(apiClient);
  final amenityRepository = AmenityRepository(apiClient: apiClient);
  final subscriptionRepository = SubscriptionRepository(apiClient: apiClient);
  final settingsRepository = SettingsRepository(apiClient);
  final enquiryService = EnquiryService();
  final departmentService = DepartmentService();

  runApp(MyApp(
    propertyRepository: propertyRepository,
    tenantRepository: tenantRepository,
    staffRepository: staffRepository,
    roleRepository: roleRepository,
    paymentRepository: paymentRepository,
    analyticsRepository: analyticsRepository,
    notificationRepository: notificationRepository,
    expenseRepository: expenseRepository,
    leaseRepository: leaseRepository,
    amenityRepository: amenityRepository,
    subscriptionRepository: subscriptionRepository,
    settingsRepository: settingsRepository,
    enquiryService: enquiryService,
    departmentService: departmentService,
  ));
}

class MyApp extends StatelessWidget {
  final PropertyRepository propertyRepository;
  final TenantRepository tenantRepository;
  final StaffRepository staffRepository;
  final RoleRepository roleRepository;
  final PaymentRepository paymentRepository;
  final AnalyticsRepository analyticsRepository;
  final NotificationRepository notificationRepository;
  final ExpenseRepository expenseRepository;
  final LeaseRepository leaseRepository;
  final AmenityRepository amenityRepository;
  final SubscriptionRepository subscriptionRepository;
  final SettingsRepository settingsRepository;
  final EnquiryService enquiryService;
  final DepartmentService departmentService;

  const MyApp({
    super.key,
    required this.propertyRepository,
    required this.tenantRepository,
    required this.staffRepository,
    required this.roleRepository,
    required this.paymentRepository,
    required this.analyticsRepository,
    required this.notificationRepository,
    required this.expenseRepository,
    required this.leaseRepository,
    required this.amenityRepository,
    required this.subscriptionRepository,
    required this.settingsRepository,
    required this.enquiryService,
    required this.departmentService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => getIt<AuthBloc>(), // Use DI for AuthBloc
        ),
        BlocProvider(
          create: (context) =>
              SettingsBloc(settingsRepository: settingsRepository),
        ),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'Rencomm Admin',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: state.themeMode,
            locale: state.locale ?? const Locale('en'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'), // English
              Locale('ar'), // Arabic
            ],
            initialRoute: AppRoutesList.initialRoute,
            routes: AppRoutesList.routes,
            onUnknownRoute: (_) =>
                MaterialPageRoute(builder: (_) => const SplashPage()),
            builder: (context, child) {
              return BlocListener<AuthBloc, AuthState>(
                listener: (context, authState) {
                  if (authState is AuthAuthenticated) {
                    context.read<SettingsBloc>().add(SettingsLoad());
                  } else if (authState is AuthUnauthenticated) {
                    navigatorKey.currentState
                        ?.pushNamedAndRemoveUntil('/login', (route) => false);
                  }
                },
                child: BlocBuilder<AuthBloc, AuthState>(
                  buildWhen: (previous, current) {
                    final wasAuth = previous is AuthAuthenticated;
                    final isAuth = current is AuthAuthenticated;
                    return wasAuth != isAuth;
                  },
                  builder: (context, authState) {
                    final isAuthenticated = authState is AuthAuthenticated;
                    return MultiBlocProvider(
                      providers: [
                        BlocProvider(
                          create: (context) {
                            final bloc = PropertyBloc(propertyRepository);
                            if (isAuthenticated) {
                              bloc.add(const LoadProperties());
                            }
                            return bloc;
                          },
                        ),
                        BlocProvider(
                          create: (context) {
                            final bloc = TenantBloc(tenantRepository);
                            if (isAuthenticated) bloc.add(const LoadTenants());
                            return bloc;
                          },
                        ),
                        BlocProvider(
                          create: (context) =>
                              TenantPaymentBloc(tenantRepository),
                        ),
                        BlocProvider(
                          create: (context) {
                            final bloc = StaffBloc(staffRepository);
                            if (isAuthenticated) bloc.add(const LoadStaff());
                            return bloc;
                          },
                        ),
                        BlocProvider(
                          create: (context) {
                            final bloc = RoleBloc(roleRepository);
                            if (isAuthenticated) bloc.add(const LoadRoles());
                            return bloc;
                          },
                        ),
                        BlocProvider(
                          create: (context) {
                            final bloc = PaymentBloc(paymentRepository);
                            if (isAuthenticated) bloc.add(const LoadPayments());
                            return bloc;
                          },
                        ),
                        BlocProvider(
                          create: (context) {
                            final bloc = AnalyticsBloc(analyticsRepository);
                            if (isAuthenticated) {
                              bloc.add(const LoadAnalyticsOverview());
                            }
                            return bloc;
                          },
                        ),
                        BlocProvider(
                          create: (context) {
                            final bloc =
                                NotificationBloc(notificationRepository);
                            if (isAuthenticated) bloc.add(LoadNotifications());
                            return bloc;
                          },
                        ),
                        BlocProvider(
                          create: (context) {
                            final bloc = ExpenseBloc(repository: expenseRepository);
                            if (isAuthenticated) bloc.add(const LoadExpenses());
                            return bloc;
                          },
                        ),
                        BlocProvider(
                          create: (context) => LeaseBloc(repository: leaseRepository),
                        ),
                        BlocProvider(
                          create: (context) {
                            final bloc = AmenityBloc(repository: amenityRepository);
                            if (isAuthenticated) bloc.add(LoadAmenities());
                            return bloc;
                          }
                        ),
                        BlocProvider(
                          create: (context) {
                            final bloc = BillingBloc(repository: subscriptionRepository);
                            if (isAuthenticated) bloc.add(LoadBillingInfo());
                            return bloc;
                          }
                        ),
                        BlocProvider(
                          create: (context) {
                            final bloc = EnquiryBloc(enquiryService: enquiryService);
                            if (isAuthenticated) bloc.add(LoadEnquiries());
                            return bloc;
                          }
                        ),
                        BlocProvider(
                          create: (context) {
                            final bloc = DepartmentBloc(departmentService: departmentService);
                            if (isAuthenticated) bloc.add(LoadDepartments());
                            return bloc;
                          }
                        ),
                        BlocProvider(
                          create: (context) => NavigationCubit(),
                        ),
                      ],
                      child: child ?? const SizedBox.shrink(),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
