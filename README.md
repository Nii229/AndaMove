# 🌴 AndaMove — GPS-Based Travel Itinerary App for Phuket

> **Amazing Travel for Southern Thailand**
> A smart, distance- and travel-time-aware itinerary planner for tourists exploring Phuket.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green)
![Status](https://img.shields.io/badge/Status-In%20Development-orange)

---

## 📖 About

**AndaMove** is a Flutter-based mobile application developed as a **Final Year Project (FYP 2026)** for **Universiti Malaysia Perlis (UniMAP)**. The app helps domestic and international tourists plan efficient travel itineraries in Phuket, Thailand, using GPS-based proximity and travel-time estimation.

Unlike popular platforms that rely on ratings and popularity, AndaMove organizes user-selected destinations into optimized sequences based on **distance and estimated travel time**, giving tourists a practical, on-the-go planning tool.

---

## ✨ Features

### Tourist Side
- **Home Dashboard** — Weather integration (OpenWeatherMap API), trending destinations, and quick category browsing
- **Point of Interest (POI) Detail** — Rich destination cards with images, descriptions, ratings, and save functionality
- **Itinerary Generation** — Select multiple POIs and generate an optimized day plan based on proximity
- **Itinerary Result** — Visual timeline of planned stops with travel time estimates
- **Map View** — See all selected destinations plotted on an interactive map
- **Navigation** — Step-by-step route guidance between stops
- **Trips** — Manage upcoming, in-progress, and completed trips
- **Explore (Vlogs)** — Browse video vlogs of Phuket attractions with save and follow functionality
- **Profile** — View saved places, saved videos, edit personal info, and app settings
- **Help Center & About** — In-app support and project information

### Admin Panel
- **Analytics Dashboard** — Overview of app usage, POI stats, and user metrics
- **Manage POIs** — View, hide, delete, and publish points of interest
- **Create POI** — Add new destinations with category, description, and location data
- **Manage Users** — View and manage registered users
- **Activity Logs** — Track admin actions and system events

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (Dart) |
| State Management | Custom static `AppStore` singleton with listener pattern |
| Typography | Google Fonts (Outfit + Playfair Display) |
| Weather API | OpenWeatherMap |
| Video Playback | `video_player` package |
| Design System | Custom `AppColors`, `AppRadius` design tokens |
| Backend (Planned) | Firebase (Auth, Firestore, Storage) |
| Maps (Planned) | Google Maps API, Directions API |

---

## 📁 Project Structure

```
andamove/
├── lib/
│   ├── main.dart                  # App entry point & routing
│   ├── app_store.dart             # Global state management singleton
│   ├── screens/
│   │   ├── screen1_splash.dart
│   │   ├── screen2_login.dart
│   │   ├── screen3_register.dart
│   │   ├── screen4_forgotPassword.dart
│   │   ├── screen5_home.dart
│   │   ├── screen6_POI.dart
│   │   ├── screen6b_pickItinerary.dart
│   │   ├── screen7_generateItinerary.dart
│   │   ├── screen8_itineraryResult.dart
│   │   ├── screen9_mapView.dart
│   │   ├── screen10_navigation.dart
│   │   ├── screen11_trips.dart
│   │   ├── screen12_profile.dart
│   │   ├── screen13_notification.dart
│   │   ├── screen14_explore.dart
│   │   ├── screen15_editPersonalInfo.dart
│   │   ├── screen16_helpCenter.dart
│   │   └── screen17_aboutAndaMove.dart
│   └── admin/
│       ├── admin_theme.dart
│       └── screens/
│           ├── adminScreen1_analyticsDashboard.dart
│           ├── adminScreen2_managePOI.dart
│           ├── adminScreen3_createPOI.dart
│           ├── adminScreen4_manageUsers.dart
│           ├── adminScreen5_profile.dart
│           └── adminScreen6_activityLogs.dart
├── assets/
│   ├── images/                    # POI photos and app logo
│   └── videos/                    # Explore vlog videos (excluded from git)
├── pubspec.yaml
└── README.md
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.x
- Dart SDK 3.x
- Android Studio or VS Code with Flutter extension
- An Android/iOS device or emulator

### Installation

```bash
# Clone the repository
git clone https://github.com/Nii229/AndaMove.git

# Navigate to the project directory
cd AndaMove

# Install dependencies
flutter pub get

# Run the app
flutter run
```

> **Note:** Video assets (`*.mov`, `*.mp4`) are excluded from the repository due to file size. Place your video files in `assets/videos/` locally.

---

## 🗺️ Roadmap

- [x] Tourist-facing screens (17 screens)
- [x] Admin panel (6 screens)
- [x] AppStore state management
- [x] Weather API integration
- [x] Explore vlogs with video playback
- [ ] Firebase Authentication
- [ ] Firestore database for POIs and users
- [ ] Firebase Storage for images and videos
- [ ] Google Maps API integration (real-time navigation)
- [ ] Edit POI functionality in admin panel
- [ ] Scale to other provinces in Southern Thailand

---

## 👩‍💻 Author

**Nur Fatini binti Mahamad Razali**
Matric Number: 301193
Universiti Malaysia Perlis (UniMAP)

**Supervisor:** Suwannit Chareen Chit A/L Sop Chit

---

## 📄 License

This project is developed for academic purposes as part of a Final Year Project (STIZK3993 Academic Project).