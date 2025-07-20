# Mom's Product Order Management

A Flutter MVP app for managing product orders with separate admin and client dashboards.

## Features

### Client Features
- Google Sign-In authentication
- Client verification with unique codes
- View subscribed products
- Request, cancel, and return orders
- Track expired orders and pending balance
- In-app notifications with badge count
- Profile management with theme and font size settings

### Admin Features
- Google Sign-In authentication
- Client management (view clients, approve join requests)
- Order management (view/manage all client orders)
- Product management (add, edit, delete products)
- Send notifications to clients

## Tech Stack

- **Framework:** Flutter 3.9+
- **State Management:** Riverpod
- **Navigation:** GoRouter
- **Backend:** Firebase (Auth, Firestore, FCM)
- **Architecture:** Clean Architecture
- **Local Storage:** SharedPreferences

## Setup

1. Clone the repository
2. Install Flutter dependencies: `flutter pub get`
3. Set up Firebase project and download google-services.json
4. Configure environment variables in .env file
5. Run the app: `flutter run`

## Project Structure

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   ├── theme/
│   ├── utils/
│   ├── services/
│   ├── widgets/
│   └── router/
└── features/
    ├── auth/
    ├── dashboard/
    ├── orders/
    ├── products/
    ├── notifications/
    └── profile/
```

Each feature follows Clean Architecture with:
- **data/**: Repositories, models, datasources
- **domain/**: Entities, repositories interfaces, use cases
- **presentation/**: Pages, widgets, providers

## Build Variants

- Development: `flutter run --flavor dev`
- Production: `flutter run --flavor prod`

## License

This project is proprietary software.
