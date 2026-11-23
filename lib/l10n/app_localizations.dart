import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///

abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// The application title
  ///
  /// In en, this message translates to:
  /// **'Rencomm Admin'**
  String get appTitle;

  /// Welcome message on login screen
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// Subtitle on login screen
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue to your account'**
  String get signInToContinue;

  /// Email Address option
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// Password input label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Sign in button text
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// Loading state text for sign in
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get signingIn;

  /// Email validation error
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// Invalid Email option
  ///
  /// In en, this message translates to:
  /// **'Invalid Email'**
  String get invalidEmail;

  /// Password validation error
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// Footer text on login screen
  ///
  /// In en, this message translates to:
  /// **'Secure login powered by Ficean Technology'**
  String get secureLoginFooter;

  /// Dashboard screen title
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// Dashboard welcome message
  ///
  /// In en, this message translates to:
  /// **'Welcome to Dashboard'**
  String get welcomeToDashboard;

  /// Dashboard placeholder text
  ///
  /// In en, this message translates to:
  /// **'Dashboard features coming soon...'**
  String get dashboardFeaturesComingSoon;

  /// Logout button text
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Splash screen title
  ///
  /// In en, this message translates to:
  /// **'Admin Portal'**
  String get adminPortal;

  /// Splash screen Subtitle
  ///
  /// In en, this message translates to:
  /// **'Rencomm Smart Rental Management'**
  String get ficeanSmartRental;

  /// Properties tab label
  ///
  /// In en, this message translates to:
  /// **'Properties'**
  String get properties;

  /// People tab label
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get people;

  /// Profile tab label
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Account section header
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// Edit Profile option
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// Notifications option
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Settings section header
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Dark Mode option
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// Language option
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Support section header
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// Help & Support option
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// Error Message
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No notifications Message
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotification;

  /// Please select tenant and property Message
  ///
  /// In en, this message translates to:
  /// **'Please select tenant and property'**
  String get pleaseSelectTenantAndProperty;

  /// Record Payment option
  ///
  /// In en, this message translates to:
  /// **'Record Payment'**
  String get recordPayment;

  /// Payments option
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No payments found message
  ///
  /// In en, this message translates to:
  /// **'No payments found'**
  String get noPaymentsFound;

  /// Add New Person option
  ///
  /// In en, this message translates to:
  /// **'Add New Person'**
  String get addNewPerson;

  /// Contract Start Date option
  ///
  /// In en, this message translates to:
  /// **'Contract Start Date'**
  String get contractStartDate;

  /// Contract End Date option
  ///
  /// In en, this message translates to:
  /// **'Contract End Date'**
  String get contractEndDate;

  /// No tenants found Message
  ///
  /// In en, this message translates to:
  /// **'No tenants found'**
  String get noTenantsFound;

  /// No staff found Message
  ///
  /// In en, this message translates to:
  /// **'No staff found'**
  String get noStaffFound;

  /// Number of rooms must be greater than 0 Message
  ///
  /// In en, this message translates to:
  /// **'Number of rooms must be greater than 0'**
  String get numberOfRoomsMustBeGreaterThanZero;

  /// Floors and units must be greater than 0 Message
  ///
  /// In en, this message translates to:
  /// **'Floors and units must be greater than 0'**
  String get floorsAndUnitsMustBeGreaterThanZero;

  /// Flat option
  ///
  /// In en, this message translates to:
  /// **'Flat'**
  String get flat;

  /// Villa option
  ///
  /// In en, this message translates to:
  /// **'Villa'**
  String get villa;

  /// Configure Property option
  ///
  /// In en, this message translates to:
  /// **'Configure Property'**
  String get configureProperty;

  /// Back option
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Save Property option
  ///
  /// In en, this message translates to:
  /// **'Save Property'**
  String get saveProperty;

  /// Rooms Configuration option
  ///
  /// In en, this message translates to:
  /// **'Rooms Configuration'**
  String get roomsConfiguration;

  /// Add Room option
  ///
  /// In en, this message translates to:
  /// **'Add Room'**
  String get addRoom;

  /// Floors & Units option
  ///
  /// In en, this message translates to:
  /// **'Floors & Units'**
  String get floorsAndUnits;

  /// Add Floor option
  ///
  /// In en, this message translates to:
  /// **'Add Floor'**
  String get addFloor;

  /// Add Unit option
  ///
  /// In en, this message translates to:
  /// **'Add Unit'**
  String get addUnit;

  /// No Properties Found option
  ///
  /// In en, this message translates to:
  /// **'No Properties Found'**
  String get noPropertiesFound;

  /// Add Property option
  ///
  /// In en, this message translates to:
  /// **'Add Property'**
  String get addProperty;

  /// Retry option
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Failed to load properties option
  ///
  /// In en, this message translates to:
  /// **'Failed to load properties'**
  String get failedToLoadProperties;

  /// Phone number is required option
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phoneNumberIsRequired;

  /// Please enter a valid phone number option
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get enterValidPhoneNumber;

  /// Email is required option
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailIsRequired;

  /// Please enter a valid email option
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get enterValidEmail;

  /// No description provided for @thisField.
  ///
  /// In en, this message translates to:
  /// **'This Field'**
  String get thisField;

  /// is required option
  ///
  /// In en, this message translates to:
  /// **'is required'**
  String get isRequired;

  /// No description provided for @mustBeAtleast.
  ///
  /// In en, this message translates to:
  /// **'must be atleast'**
  String get mustBeAtleast;

  /// characters option
  ///
  /// In en, this message translates to:
  /// **'characters'**
  String get characters;

  /// Recent Activities option
  ///
  /// In en, this message translates to:
  /// **'Recent Activities'**
  String get recentActivities;

  /// Overview option
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @paymentReceived.
  ///
  /// In en, this message translates to:
  /// **'Payment Received'**
  String get paymentReceived;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just Now'**
  String get justNow;

  /// No description provided for @unknownTenant.
  ///
  /// In en, this message translates to:
  /// **'Unknown Tenant'**
  String get unknownTenant;

  /// No description provided for @property.
  ///
  /// In en, this message translates to:
  /// **'Property'**
  String get property;

  /// Save Tenant option
  ///
  /// In en, this message translates to:
  /// **'Save Tenant'**
  String get saveTenant;

  /// Save Staff option
  ///
  /// In en, this message translates to:
  /// **'Save Staff'**
  String get saveStaff;

  /// Add Property Details option
  ///
  /// In en, this message translates to:
  /// **'Add Property Details'**
  String get addPropertyDetails;

  /// Quick Start Configuration option
  ///
  /// In en, this message translates to:
  /// **'Quick Start Configuration'**
  String get quickStartConfiguration;

  /// Prefilled Data option
  ///
  /// In en, this message translates to:
  /// **'Pre-fill the structure below, or leave default values to configure manually in the next step.'**
  String get prefilledData;

  /// General option
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// Push Notifications option
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// About option
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No recent activities placeholder
  ///
  /// In en, this message translates to:
  /// **'No recent activities'**
  String get noRecentActivities;

  /// Total Revenue option
  ///
  /// In en, this message translates to:
  /// **'Total Revenue'**
  String get totalRevenue;

  /// Total Properties option
  ///
  /// In en, this message translates to:
  /// **'Total Properties'**
  String get totalProperties;

  /// Tenants option
  ///
  /// In en, this message translates to:
  /// **'Tenants'**
  String get tenants;

  /// Total Expected option
  ///
  /// In en, this message translates to:
  /// **'Total Expected'**
  String get totalExpected;

  /// Pending option
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// Total Units option
  ///
  /// In en, this message translates to:
  /// **'Total Units'**
  String get totalUnits;

  /// Active Tenants option
  ///
  /// In en, this message translates to:
  /// **'Active Tenants'**
  String get activeTenants;

  /// Target Revenue option
  ///
  /// In en, this message translates to:
  /// **'Target Revenue'**
  String get targetRevenue;

  /// Vacant Rooms count label on dashboard
  ///
  /// In en, this message translates to:
  /// **'Vacant Rooms'**
  String get vacantRooms;

  /// Vacant filter label
  ///
  /// In en, this message translates to:
  /// **'Vacant'**
  String get vacant;

  /// Property floor unit error option
  ///
  /// In en, this message translates to:
  /// **'Each floor must have at least one unit'**
  String get propertyFloorUnitError;

  /// Error message when a unit name is empty
  ///
  /// In en, this message translates to:
  /// **'Each unit must have a name'**
  String get unitNameRequired;

  /// Property Name option
  ///
  /// In en, this message translates to:
  /// **'Property Name'**
  String get propertyName;

  /// Address option
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// Property Type option
  ///
  /// In en, this message translates to:
  /// **'Property Type'**
  String get propertyType;

  /// Delete Property title
  ///
  /// In en, this message translates to:
  /// **'Delete Property'**
  String get deleteProperty;

  /// Delete Property confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this property? This action cannot be undone.'**
  String get deletePropertyConfirmation;

  /// Edit button text
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Delete button text
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Edit Property title
  ///
  /// In en, this message translates to:
  /// **'Edit Property'**
  String get editProperty;

  /// Tenant Details title
  ///
  /// In en, this message translates to:
  /// **'Tenant Details'**
  String get tenantDetails;

  /// Staff Details title
  ///
  /// In en, this message translates to:
  /// **'Staff Details'**
  String get staffDetails;

  /// Property Details title
  ///
  /// In en, this message translates to:
  /// **'Property Details'**
  String get propertyDetails;

  /// Delete person confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this person? This action cannot be undone.'**
  String get deletePersonConfirmation;

  /// Call button text
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// Security Deposit option
  ///
  /// In en, this message translates to:
  /// **'Security Deposit'**
  String get securityDeposit;

  /// Role option
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// Full Name option
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// Required option
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// Phone Number option
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// Rent Amount option
  ///
  /// In en, this message translates to:
  /// **'Rent Amount'**
  String get rentAmount;

  /// Assign Property option
  ///
  /// In en, this message translates to:
  /// **'Assign Property'**
  String get assignProperty;

  /// Please select a property option
  ///
  /// In en, this message translates to:
  /// **'Please select a property'**
  String get pleaseSelectAProperty;

  /// Please select a room option
  ///
  /// In en, this message translates to:
  /// **'Please select a room'**
  String get pleaseSelectARoom;

  /// Number of Rooms option
  ///
  /// In en, this message translates to:
  /// **'Number of Rooms'**
  String get numberOfRooms;

  /// Floors option
  ///
  /// In en, this message translates to:
  /// **'Floors'**
  String get floors;

  /// Units/Floor option
  ///
  /// In en, this message translates to:
  /// **'Units/Floor'**
  String get unitsPerFloor;
  String get roomName;

  String get floorName;

  String get totalNoOfFloors;

  String get totalNoOfUnits;


  String get location;


  String get occupied;


  String get structure;

  String get floor;

  String get changeLanguage;

  String get totalAmount;

  String get remainingDue;

  String get none;

  String get active;

  String get inactive;

  String get notAssigned;

  String get month;

  String get employmentDetails;
 
  String get employeeId;

  String get department;

  /// Tenant option
  ///
  /// In en, this message translates to:
  /// **'Tenant'**
  String get tenant;

  /// Amount option
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// Staff option
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get staff;

  /// Room option
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get room;

  /// Hint text to select property first
  ///
  /// In en, this message translates to:
  /// **'Select a property first'**
  String get selectPropertyFirst;

  /// Text when no rooms are available
  ///
  /// In en, this message translates to:
  /// **'No rooms available'**
  String get noRoomsAvailable;

  /// Hint text to select room
  ///
  /// In en, this message translates to:
  /// **'Select Room'**
  String get selectRoom;

  /// Assign button text
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get assign;

  /// Unassign button text
  ///
  /// In en, this message translates to:
  /// **'Unassign'**
  String get unassign;

  /// Unassign room confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to unassign this room?'**
  String get unassignConfirmation;

  /// App Role option
  ///
  /// In en, this message translates to:
  /// **'App Role'**
  String get appRole;

  /// Select Role hint
  ///
  /// In en, this message translates to:
  /// **'Select Role'**
  String get selectRole;

  /// Manage Roles option
  ///
  /// In en, this message translates to:
  /// **'Manage Roles'**
  String get manageRoles;

  /// Add New Role option
  ///
  /// In en, this message translates to:
  /// **'Add New Role'**
  String get addNewRole;

  /// Role name is required option
  ///
  /// In en, this message translates to:
  /// **'Role name is required'**
  String get roleNameIsRequired;

  /// Role Name option
  ///
  /// In en, this message translates to:
  /// **'Role Name'**
  String get roleName;

  /// Description option
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// Hint text for description
  ///
  /// In en, this message translates to:
  /// **'Brief description of the role'**
  String get hintText;

  /// Permissions option
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permissions;

  /// Edit Role option
  ///
  /// In en, this message translates to:
  /// **'Edit Role'**
  String get editRole;

  /// Delete Role option
  ///
  /// In en, this message translates to:
  /// **'Delete Role'**
  String get deleteRole;

  /// Delete role confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the role? This action cannot be undone.'**
  String get areYouSureYouWantToDeleteTheRole;

  /// No description provided option
  ///
  /// In en, this message translates to:
  /// **'No description provided.'**
  String get noDescriptionProvided;

  /// No staff members assigned to this role option
  ///
  /// In en, this message translates to:
  /// **'No staff members assigned to this role.'**
  String get noStaffMembersAssignedToThisRole;

  /// Assigned Staff option
  ///
  /// In en, this message translates to:
  /// **'Assigned Staff'**
  String get assignedStaff;

  /// No roles found option
  ///
  /// In en, this message translates to:
  /// **'No roles found'**
  String get noRolesFound;

  /// Edit Person title
  ///
  /// In en, this message translates to:
  /// **'Edit Person'**
  String get editPerson;

  /// Update Tenant button text
  ///
  /// In en, this message translates to:
  /// **'Update Tenant'**
  String get updateTenant;

  /// Update Staff button text
  ///
  /// In en, this message translates to:
  /// **'Update Staff'**
  String get updateStaff;

  /// Change Password button text
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// New Password input label
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// Save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Documents section title
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// Update documents action
  ///
  /// In en, this message translates to:
  /// **'Update documents'**
  String get updateDocuments;

  /// Tenant documents page title
  ///
  /// In en, this message translates to:
  /// **'Tenant documents'**
  String get tenantDocuments;

  /// Emirates ID documents label
  ///
  /// In en, this message translates to:
  /// **'Emirates ID'**
  String get emiratesIdDocuments;

  /// Passport front label
  ///
  /// In en, this message translates to:
  /// **'Passport (front)'**
  String get passportFront;

  /// Passport back label
  ///
  /// In en, this message translates to:
  /// **'Passport (back)'**
  String get passportBack;

  /// Qatar ID label
  ///
  /// In en, this message translates to:
  /// **'Qatar ID'**
  String get qatarId;

  /// Add image button
  ///
  /// In en, this message translates to:
  /// **'Add image'**
  String get addImage;

  /// View document action
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get viewDocument;

  /// No documents message
  ///
  /// In en, this message translates to:
  /// **'No documents uploaded'**
  String get noDocuments;

  /// Documents saved success message
  ///
  /// In en, this message translates to:
  /// **'Documents saved successfully'**
  String get documentsSaved;

  /// Documents save error message
  ///
  /// In en, this message translates to:
  /// **'Failed to save documents'**
  String get documentsSaveFailed;

  /// Loading roles message
  ///
  /// In en, this message translates to:
  /// **'Loading roles...'**
  String get loadingRoles;

  /// View Payment History button text
  ///
  /// In en, this message translates to:
  /// **'View Payment History'**
  String get viewPaymentHistory;

  /// Contact Details section title
  ///
  /// In en, this message translates to:
  /// **'Contact Details'**
  String get contactDetails;

  /// Could not launch PDF message
  ///
  /// In en, this message translates to:
  /// **'Could not launch PDF'**
  String get couldNotLaunchPDF;

  /// Rental Details section title
  ///
  /// In en, this message translates to:
  /// **'Rental Details'**
  String get rentalDetails;

  /// Payment History page title
  ///
  /// In en, this message translates to:
  /// **'Payment History'**
  String get paymentHistory;

  /// Total Paid label
  ///
  /// In en, this message translates to:
  /// **'Total Paid'**
  String get totalPaid;

  /// Received by label
  ///
  /// In en, this message translates to:
  /// **'Received by'**
  String get receivedBy;

  /// Add Payment button text
  ///
  /// In en, this message translates to:
  /// **'Add Payment'**
  String get addPayment;

  /// Notes (Optional) label
  ///
  /// In en, this message translates to:
  /// **'Notes (Optional)'**
  String get notesOptional;

  /// Please select at least one permission message
  ///
  /// In en, this message translates to:
  /// **'Please select at least one permission'**
  String get pleaseSelectAtLeastOnePermission;

  /// Total Pending label
  ///
  /// In en, this message translates to:
  /// **'Total Pending'**
  String get totalPending;

  /// Date label
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// Recorded at label
  ///
  /// In en, this message translates to:
  /// **'Recorded at'**
  String get recordedAt;

  /// Payment Date label
  ///
  /// In en, this message translates to:
  /// **'Payment Date'**
  String get paymentDate;

  /// Past Leases label
  ///
  /// In en, this message translates to:
  /// **'Past Leases'**
  String get pastLeases;

  /// Current Lease label
  ///
  /// In en, this message translates to:
  /// **'Current Lease'**
  String get currentLease;

  /// Lease History label
  ///
  /// In en, this message translates to:
  /// **'Lease History'**
  String get leaseHistory;

  /// Message for tenants without active assignment
  ///
  /// In en, this message translates to:
  /// **'Not currently a tenant'**
  String get noActiveLease;

  /// Start Date label
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// End Date label
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// View Payments button text
  ///
  /// In en, this message translates to:
  /// **'View Payments'**
  String get viewPayments;

  /// Message shown when there is no lease history
  ///
  /// In en, this message translates to:
  /// **'No lease history found'**
  String get noLeaseHistory;

  /// Manage Properties option
  ///
  /// In en, this message translates to:
  /// **'Manage Properties'**
  String get manageProperties;

  /// Manage Staffs option
  ///
  /// In en, this message translates to:
  /// **'Manage Staffs'**
  String get manageStaffs;

  /// Recurring monthly rent toggle label
  ///
  /// In en, this message translates to:
  /// **'Recurring Monthly Rent'**
  String get recurringMonthlyRent;

  /// Lease duration notice text
  ///
  /// In en, this message translates to:
  /// **'Please enter the number of days for this lease'**
  String get leaseDurationNotice;

  /// Lease duration input label
  ///
  /// In en, this message translates to:
  /// **'Duration in Days'**
  String get leaseDurationDays;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
