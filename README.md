# 🛡️ SOSecure

SOSecure is a mobile application developed using Flutter that enhances personal safety in emergency situations. The app enables users to quickly trigger an SOS alert, share their real-time location, and notify predefined emergency contacts.

## 🚀 Features

- 🔴 **SOS Alert System**
  - Press-and-hold SOS button with visual feedback
  - Emergency trigger with progress indicator

- 📍 **Location Awareness**
  - Real-time GPS location tracking (planned)
  - Map integration for visual positioning

- 👥 **Emergency Contacts**
  - Add, edit, and delete trusted contacts
  - Manage contact relationships

- 📜 **Alert History**
  - View previous emergency events (planned)

- 🎨 **Modern UI/UX**
  - Clean and responsive design
  - Light and dark mode support
  - Animated SOS button with pulse and progress ring

## 🏗️ Architecture

The application follows a **clean MVVM architecture**:

- **View (UI)** – Flutter widgets and screens
- **ViewModel** – Handles UI logic and state
- **Repository** – Abstracts data operations
- **Service** – Handles external APIs (Firebase, GPS, etc.)

## 🛠️ Tech Stack

- **Flutter** (Dart)
- **Provider** (state management)
- **GoRouter** (navigation)
- **Google Fonts**
- **Geolocator & Google Maps** (planned)
- **Firebase (Auth + Firestore)** (planned)

## 📱 Current Status

- ✅ Home screen with animated SOS button
- ✅ Contacts feature (add/remove contacts)
- ✅ Navigation between screens
- ✅ MVVM structure implemented
- 🚧 Map and location integration in progress
- 🚧 Firebase integration planned

## 📸 Screenshots

> Add screenshots here later

## ⚙️ Setup

```bash
git clone https://github.com/BrunoK2410/SOSecure.git
cd sosecure
flutter pub get
flutter run
```
