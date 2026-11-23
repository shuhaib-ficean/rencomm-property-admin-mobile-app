# Admin Mobile App - Rencomm SRM

Flutter mobile application for Rencomm Smart Rental Management System using BLOC architecture.

## Architecture

This app follows the **BLOC (Business Logic Component) architecture** pattern:

```
lib/
├── core/
│   ├── constants/
│   ├── errors/
│   ├── network/
│   └── utils/
├── data/
│   ├── models/
│   ├── repositories/
│   └── datasources/
├── domain/
│   ├── entities/
│   └── repositories/
├── presentation/
│   ├── blocs/
│   ├── screens/
│   └── widgets/
└── main.dart
```

## Setup

1. Install Flutter dependencies:

```bash
flutter pub get
```

2. Generate code (for models and API clients):

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

3. Configure API base URL in `lib/core/constants/api_constants.dart`

4. Run the app:

```bash
flutter run
```

## Features

- Authentication (Login/Logout)
- Dashboard
- Flat Management
- Tenant Management
- Staff Management
- Payment Tracking
- Analytics
- Settings

## BLOC Pattern

Each feature follows the BLOC pattern:

- **Events**: User actions/triggers
- **States**: UI states (loading, success, error)
- **BLOC**: Business logic handler
- **Repository**: Data layer abstraction
- **Data Source**: API/DB implementation
