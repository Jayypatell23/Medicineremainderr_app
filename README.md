# Medicine Reminder App

A Flutter application that helps users manage their medication schedule with reminders and notifications.

## Features

- User authentication (Email/Password and Google Sign-in)
- Add, view, and delete medicines
- Set medication schedules with time
- Local notifications for medication reminders
- Beautiful and intuitive UI
- Firebase integration for data storage

## Setup Instructions

1. Clone the repository
2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

3. Configure Firebase:
   - Create a new Firebase project
   - Add Android app to Firebase project
   - Download and place `google-services.json` in `android/app/`
   - Enable Email/Password and Google Sign-in authentication methods in Firebase Console

4. Run the app:
   ```bash
   flutter run
   ```

## Required Permissions

The app requires the following permissions:
- Internet access
- Notifications
- Exact alarm scheduling
- Vibration
- Boot completed (for restarting notifications after device reboot)

## Dependencies

- firebase_core: ^2.24.2
- firebase_auth: ^4.15.3
- cloud_firestore: ^4.13.6
- google_sign_in: ^6.1.6
- flutter_local_notifications: ^16.3.0
- timezone: ^0.9.2
- provider: ^6.1.1
- shared_preferences: ^2.2.2
- intl: ^0.18.1

## Project Structure

```
lib/
  ├── main.dart
  ├── screens/
  │   ├── auth/
  │   │   └── auth_screen.dart
  │   └── home/
  │       └── home_screen.dart
  ├── services/
  │   └── auth_service.dart
  └── widgets/
      ├── medicine_list.dart
      └── add_medicine_dialog.dart
```

## Contributing

Feel free to submit issues and enhancement requests.

## License

This project is licensed under the MIT License. 