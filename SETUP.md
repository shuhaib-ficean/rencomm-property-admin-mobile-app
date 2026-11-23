# Flutter Admin Mobile App - Setup Guide

## Prerequisites

1. **Flutter SDK**: Make sure you have Flutter installed (version 3.0.0 or higher)

   - Check installation: `flutter doctor`
   - Install from: https://flutter.dev/docs/get-started/install

2. **Dart SDK**: Comes with Flutter installation

3. **IDE**: Android Studio, VS Code, or IntelliJ IDEA with Flutter plugins

## Setup Steps

### 1. Install Dependencies

Navigate to the `admin-mobile-app` directory and run:

```bash
cd admin-mobile-app
flutter pub get
```

This will install all the required packages defined in `pubspec.yaml`.

### 2. Configure API Base URL

Update the API base URL in `lib/core/constants/api_constants.dart`:

- **Android Emulator**: Use `http://10.0.2.2:5000/api`
- **iOS Simulator**: Use `http://localhost:5000/api`
- **Physical Device**: Use your computer's IP address, e.g., `http://192.168.1.100:5000/api`

### 3. Run the App

```bash
# List available devices
flutter devices

# Run on a specific device
flutter run

# Or run in debug mode
flutter run --debug

# Or run in release mode
flutter run --release
```

## Project Structure

```
lib/
├── core/                    # Core functionality
│   ├── constants/          # App constants (API URLs, etc.)
│   ├── errors/             # Error handling classes
│   ├── models/             # Shared models
│   ├── network/            # API client setup
│   └── utils/              # Utility functions
├── data/                    # Data layer
│   └── repositories/       # Repository implementations
├── presentation/            # UI layer
│   ├── blocs/              # BLOC state management
│   │   ├── auth/          # Authentication BLOC
│   │   ├── flat/          # Flat management BLOC
│   │   ├── tenant/        # Tenant management BLOC
│   │   └── payment/        # Payment BLOC
│   ├── screens/            # App screens
│   │   ├── splash/        # Splash screen
│   │   ├── login/         # Login screen
│   │   └── dashboard/     # Dashboard screen
│   └── widgets/            # Reusable widgets
└── main.dart               # App entry point
```

## BLOC Architecture

This app follows the **BLOC (Business Logic Component) pattern**:

### Components:

1. **Events**: User actions that trigger state changes

   - Example: `AuthLoginRequested`, `FlatLoadRequested`

2. **States**: Represents the current state of the UI

   - Example: `AuthLoading`, `AuthAuthenticated`, `AuthError`

3. **BLOC**: Handles business logic and state transitions

   - Listens to events and emits states
   - Example: `AuthBloc`, `FlatBloc`

4. **Repository**: Abstracts data sources
   - Handles API calls and data transformation
   - Example: `AuthRepository`

### Usage Example:

```dart
// In a widget
BlocBuilder<AuthBloc, AuthState>(
  builder: (context, state) {
    if (state is AuthLoading) {
      return LoadingWidget();
    } else if (state is AuthAuthenticated) {
      return DashboardScreen();
    } else {
      return LoginScreen();
    }
  },
)

// Trigger an event
context.read<AuthBloc>().add(
  AuthLoginRequested(
    email: 'user@example.com',
    password: 'password123',
  ),
);
```

## Features Implemented

✅ **Authentication**

- Login screen with form validation
- Token-based authentication
- Secure token storage
- Auto-login on app start
- Logout functionality

✅ **BLOC Architecture**

- Complete BLOC setup with flutter_bloc
- Event-driven state management
- Repository pattern for data access

✅ **Project Structure**

- Clean architecture with separation of concerns
- Reusable widgets
- Error handling
- API client with interceptors

## Next Steps

To extend the app, you can:

1. **Add more BLOCs**: Create BLOCs for properties, Tenants, Payments, etc.
2. **Create Repositories**: Implement data repositories for each feature
3. **Build Screens**: Create UI screens for each feature
4. **Add Navigation**: Implement proper navigation between screens
5. **Add Models**: Create data models for entities (Flat, Tenant, Payment, etc.)

## Troubleshooting

### Common Issues:

1. **Package not found errors**: Run `flutter pub get`
2. **API connection issues**: Check API base URL and ensure backend is running
3. **Build errors**: Run `flutter clean` then `flutter pub get`
4. **Android build issues**: Make sure Android SDK is properly configured

### Useful Commands:

```bash
# Clean build files
flutter clean

# Get dependencies
flutter pub get

# Analyze code
flutter analyze

# Format code
flutter format .

# Check for issues
flutter doctor
```

## Backend Integration

The app is configured to work with the existing Node.js backend. Make sure:

1. Backend server is running on port 5000 (or update the URL)
2. CORS is enabled for mobile app requests
3. API endpoints match the routes defined in `api_constants.dart`

## Development Tips

1. Use hot reload: Press `r` in the terminal while app is running
2. Use hot restart: Press `R` in the terminal
3. View logs: Check the terminal output or use `flutter logs`
4. Debug: Use Flutter DevTools for debugging
