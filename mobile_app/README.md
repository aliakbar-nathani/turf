# Turf Booking Mobile App

This is a cross-platform mobile app for the Turf Booking platform built with Flutter. The app connects to the same backend as the web application, providing users with a native mobile experience.

## Features

- User authentication (login/register)
- Browse available turfs
- Search and filter turfs
- View turf details
- Book turfs with available time slots
- Negotiate prices
- Manage bookings (view, cancel)
- User profile management
- Favorites management

## Architecture

The app follows a layered architecture pattern:

1. **Presentation Layer**: UI screens and widgets
2. **Service Layer**: API services for communication with the backend
3. **Model Layer**: Data models representing the application's domain
4. **Config Layer**: Configuration and constants

### Directory Structure

```
lib/
├── config/          # App configuration and constants
├── models/          # Data models
├── screens/         # UI screens
│   ├── auth/        # Authentication screens
│   ├── booking/     # Booking-related screens
│   ├── profile/     # User profile screens
│   ├── turf/        # Turf-related screens
│   └── negotiation/ # Price negotiation screens
├── services/        # API services
├── utils/           # Utility functions
├── widgets/         # Reusable UI components
└── main.dart        # App entry point
```

## Backend API Integration

The mobile app communicates with the Flask backend API. The API endpoints are defined in `lib/config/api_config.dart`. The app makes HTTP requests to these endpoints using the `http` package.

The `services` directory contains classes responsible for communicating with the backend:

- `auth_service.dart`: Authentication-related API calls
- `turf_service.dart`: Turf-related API calls
- `booking_service.dart`: Booking-related API calls
- `negotiation_service.dart`: Price negotiation API calls
- `user_service.dart`: User profile and bookings API calls

## Running the App

### Prerequisites

- Flutter SDK (version 3.0.0 or higher)
- Dart SDK (version 2.17.0 or higher)
- IDE (VS Code, Android Studio, or IntelliJ IDEA)

### Setup

1. Navigate to the `mobile_app/turf_booking_app` directory:
   ```
   cd mobile_app/turf_booking_app
   ```

2. Install dependencies:
   ```
   flutter pub get
   ```

3. Run the app:

   For development/debug mode:
   ```
   flutter run
   ```

   For web:
   ```
   flutter run -d chrome
   ```

   For Android:
   ```
   flutter run -d android
   ```

   For iOS:
   ```
   flutter run -d ios
   ```

## API Base URL Configuration

The app connects to the backend API using the base URL defined in `lib/config/api_config.dart`. By default, it's configured to connect to:

```dart
static const String baseUrl = 'http://10.0.2.2:5000'; // Android emulator pointing to localhost
// static const String baseUrl = 'http://localhost:5000'; // For iOS simulator
```

For production, update the `baseUrl` to point to your deployed backend URL.

## Authentication

The app uses token-based authentication. When a user logs in, the auth token is stored in the device's secure storage using the `shared_preferences` package. This token is then included in the headers of API requests that require authentication.

## State Management

The app uses a simple state management approach with `StatefulWidget`s for most screens. For larger applications, consider using more robust state management solutions like Provider, Riverpod, or Bloc.

## Theming

The app's theme is defined in `lib/config/app_theme.dart`. The theme provides consistent colors, text styles, and component styling throughout the app.

## Navigation

The app uses Flutter's standard navigation system with named routes defined in `main.dart` and also uses direct navigation with `Navigator.push()` for screen transitions.

## Extending the App

To add new features:

1. Define models in the `models` directory
2. Add API services in the `services` directory
3. Create UI screens in the `screens` directory
4. Update the navigation in `main.dart` or the relevant screen files

## Dependencies

- `http`: For making API requests
- `shared_preferences`: For storing tokens and user data
- `provider`: For state management
- `intl`: For date formatting
- `cached_network_image`: For caching and loading images
- `flutter_spinkit`: For loading animations