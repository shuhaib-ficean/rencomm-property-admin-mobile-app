import 'package:admin_mobile_app/presentation/pages/properties/add_property_page.dart';
import '../../core/models/role_model.dart';
import '../../presentation/pages/settings/role_details_page.dart';
import '../../presentation/pages/settings/roles_page.dart';
import '../../presentation/pages/settings/settings_page.dart';
import 'package:flutter/material.dart';
import '../../presentation/pages/splash/splash_page.dart';
import '../../presentation/pages/login/login_page.dart';
import '../../presentation/pages/main_page.dart';
import '../../presentation/pages/people/add_person_page.dart';
import '../../presentation/pages/notifications/notifications_page.dart';
import '../../presentation/pages/people/person_details_page.dart';
import '../../presentation/pages/people/tenant_documents_page.dart';
import '../../presentation/pages/people/tenant_payment_history_page.dart';
import '../../presentation/pages/properties/property_details_page.dart';
import '../../presentation/pages/properties/properties_page.dart';
import 'package:admin_mobile_app/presentation/pages/people/staff_page.dart';
import '../../presentation/pages/registration/registration_page.dart';
import '../../presentation/pages/subscription/subscription_plan_page.dart';
import '../../presentation/pages/subscription/subscription_details_page.dart';
import '../../presentation/pages/billing/billing_page.dart';
import '../../presentation/pages/enquiries/enquiries_page.dart';
import '../../presentation/pages/leases/create_lease_page.dart';
import '../../presentation/pages/amenities/amenities_page.dart';
import '../../presentation/pages/repairs/repair_requests_page.dart';
import '../../presentation/pages/departments/departments_page.dart';
import '../../presentation/pages/leases/renewal_requests_page.dart';
import '../../presentation/pages/expenses/expenses_page.dart';
import 'app_routes.dart';

/// App routes configuration
///
/// This file contains the route map for the MaterialApp.
/// All route definitions should be centralized here.
class AppRoutesList {
  // Private constructor to prevent instantiation
  AppRoutesList._();

  /// The route map for MaterialApp
  static Map<String, WidgetBuilder> get routes => {
        AppRoutes.splash: (context) => const SplashPage(),
        AppRoutes.login: (context) => const LoginPage(),
        AppRoutes.dashboard: (context) => const MainPage(),
        AppRoutes.enquiries: (context) => const EnquiriesPage(),
        AppRoutes.createLease: (context) => const CreateLeasePage(),
        AppRoutes.amenities: (context) => const AmenitiesPage(),
        AppRoutes.repairs: (context) => const RepairRequestsPage(),
        AppRoutes.services: (context) => const RepairRequestsPage(),
        AppRoutes.departments: (context) => const DepartmentsPage(),
        AppRoutes.renewals: (context) => const RenewalRequestsPage(),
        AppRoutes.expenses: (context) => const ExpensesPage(),
        AppRoutes.properties: (context) => const PropertiesPage(),
        AppRoutes.addProperty: (context) => const AddPropertyPage(),
        AppRoutes.addPerson: (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          return AddPersonPage(
            person: args?['person'],
            initialRole: args?['initialRole'],
          );
        },
        AppRoutes.notifications: (context) => const NotificationsPage(),
        AppRoutes.personDetails: (context) => const PersonDetailsPage(),
        AppRoutes.tenantDocuments: (context) => const TenantDocumentsPage(),
        AppRoutes.propertyDetails: (context) => const PropertyDetailsPage(),
        AppRoutes.roles: (context) => const RolesPage(),
        AppRoutes.roleDetails: (context) => RoleDetailsPage(
              role: ModalRoute.of(context)!.settings.arguments as RoleModel,
            ),
        AppRoutes.tenantPaymentHistory: (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return TenantPaymentHistoryPage(
            tenantId: args['tenantId'],
            tenantName: args['tenantName'],
            leaseId: args['leaseId'],
          );
        },
        AppRoutes.staff: (context) {
          return const StaffPage();
        },
        AppRoutes.registration: (context) => const RegistrationPage(),
        AppRoutes.subscriptionPlan: (context) => const SubscriptionPlanPage(),
        AppRoutes.subscriptionDetails: (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return SubscriptionDetailsPage(planDetails: args);
        },
        AppRoutes.billing: (context) => const BillingPage(),
        AppRoutes.settings: (context) => const SettingsPage(),
      };

  /// Get the initial route
  static String get initialRoute => AppRoutes.splash;
}
