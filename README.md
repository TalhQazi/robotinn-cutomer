# 📱 RobotInn Customer Mobile Application (Flutter)

Complete Flutter port of the **RobotInn Customer Application** with 100% exact feature parity, shared Firebase backend, real-time Firestore tracking, Google Maps GPS telemetry, and VoIP communication.

---

## 🚀 Key Features

- 🔐 **Unified Authentication**:
  - Email & Password with friendly error mapping
  - Google Sign-In with Account Chooser Modal
  - 2-Step OTP Password Reset via FormSubmit Email Dispatch
  - Real-time Ban / Suspension Gate
- 🛍️ **Smart Catalog & Ordering**:
  - Hero Brand Carousel with official 3D brand logos
  - Live Firestore Category Grid & Service Categories
  - Automatic keyword-based item categorization (Pharmacy, Grocery, Fresh Bazaar, Meat, Bakery, Cosmetics)
  - Custom runner orders from any local shop
- 🗺️ **Real-time Live Order Tracking**:
  - Live Google Maps GPS telemetry with moving rider marker and customer pin
  - Route polyline with dynamic ETA window countdown
  - Interactive status stepper: `Pending` ➔ `Accepted` ➔ `Rider at Store` ➔ `Bill Verified` ➔ `Out for Delivery` ➔ `Delivered`
  - In-app Call Rider and Real-time Chat with image attachments via Firebase Storage
  - Cancel active order with reason selection
  - 5-Star rating & review feedback submission
- 💳 **Verified Billing & Price Adjustment**:
  - Admin receipt verification & customer visibility gate
  - Price adjustment approval / counter-offer dispute workflow
  - Payment proof photo upload to Firebase Storage
- 📍 **Saved Addresses & Geofenced Sectors**:
  - Multi-address manager with GPS auto-detection (Home, Office, Other)
  - Sector switcher for Islamabad & Rawalpindi delivery zones
- 💬 **Live Messaging & Push Notifications**:
  - In-app chat threads with assigned riders
  - Foreground & background FCM push notifications with local notification banners

---

## 🛠️ Tech Stack & Packages

- **Framework**: Flutter 3.x / Dart 3.x
- **State Management**: `provider` (MultiProvider with ChangeNotifier)
- **Backend & Database**: Firebase Auth, Cloud Firestore, Firebase Storage, Firebase Cloud Messaging
- **Maps**: `google_maps_flutter`, `geolocator`, `geocoding`
- **Networking & Utilities**: `http`, `shared_preferences`, `intl`, `url_launcher`, `image_picker`, `cached_network_image`
- **UI & Typography**: `google_fonts`, `cupertino_icons`

---

## 📂 Project Structure

```
RobotInn-CustomerApp-Flutter/
├── android/                        # Native Android config & Google Services
│   └── app/
│       ├── build.gradle
│       ├── google-services.json
│       └── src/main/AndroidManifest.xml
├── assets/                         # Official brand logos & 3D category assets
│   └── images/
│       ├── 3d_brands/
│       └── 3d_categories/
├── lib/
│   ├── components/
│   │   ├── common/                 # Header, Drawer, CustomButton, CustomInput, ThemedAlert
│   │   └── order/                  # LiveTrackingMap, PaymentAdjustmentModal
│   ├── constants/                  # AppConstants, OrderStatus canonical mappings
│   ├── models/                     # User, Order, Address, Category, Store, Bill, Message, Notification
│   ├── providers/                  # Auth, UserProfile, Cart, Orders, NotificationUnread
│   ├── screens/
│   │   ├── auth/                   # Login, Signup, ForgotPassword, CreateNewPassword
│   │   └── main/                   # Dashboard, StoreOrder, StoreList, Cart, Chat, Details, etc.
│   ├── services/                   # ApiService, LocationService, CategoryDetectionService, MapsService
│   ├── theme/                      # AppColors, AppTypography, AppSpacing
│   ├── firebase_options.dart       # Firebase credentials configuration
│   └── main.dart                   # MultiProvider root & Route Generator
└── pubspec.yaml
```

---

## 🏃 Running the Application

1. Make sure Flutter SDK is installed and added to PATH.
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run on connected Android / iOS device:
   ```bash
   flutter run
   ```
4. Build Release APK:
   ```bash
   flutter build apk --release
   ```
