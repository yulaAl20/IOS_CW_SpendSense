# SpendSense 

A smart personal finance tracker for iOS that helps you spend mindfully, stay on budget, and spot impulse buys before they happen.

---

## Features

- **Expense Tracking** — Log transactions by category with notes and dates. Nine categories supported: Food & Dining, Transport, Entertainment, Shopping, Health, Utilities, Education, Income, and Other.
- **Budget Management** — Set your monthly income and savings goal. SpendSense automatically derives your monthly and daily spending limits. Add category-specific budgets with daily, weekly, or monthly periods.
- **Impulse Buy Detection** — Every transaction is scored by a CoreML model (with a heuristic fallback) across factors like amount vs. your average spend, category, time of day, and how many purchases you've made today.
- **Spending Insights** — Weekly bar charts, hourly heat maps, monthly calendar views, and a category breakdown give you a clear picture of where your money goes.
- **Location Alerts** — Geofence monitoring around high-spending zones (malls, food courts) in Colombo fires a push notification showing your remaining daily budget the moment you walk in.
- **Spending Zones Map** — An interactive MapKit view displays all monitored zones, shows which one you're currently in, and lets you open any location in Apple Maps.
- **Live Activity** — A Lock Screen and Dynamic Island widget shows your remaining budget, amount spent, and risk level in real time, updating after every transaction.
- **Siri Shortcuts** — Log a transaction by voice. Siri presents spending categories, saves the transaction, and reads back an impulse risk assessment.
- **Home Screen Widget** — A WidgetKit extension shows your daily budget progress at a glance without opening the app.
- **Wishlist** — Add items you want to buy, set a waiting period, and track daily savings progress toward each one before committing to the purchase.
- **Alerts Panel** — In-app notification feed for budget warnings, location alerts, impulse checks, and spending milestones.
- **Cloud Sync** — Firebase Firestore syncs your profile and transactions across devices. Sign in with email/password, Google, or Apple.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Swift 5.9 |
| UI Framework | SwiftUI |
| Architecture | MVVM |
| Local Persistence | Core Data |
| Cloud Backend | Firebase Auth + Firestore |
| Machine Learning | Core ML (ImpulseClassifier) |
| Location | Core Location (CLCircularRegion geofencing) |
| Maps | MapKit |
| Notifications | UserNotifications |
| Widgets | WidgetKit |
| Live Activities | ActivityKit |
| Siri Integration | AppIntents |
| Keychain | Security framework |

---

## Requirements

- iOS 17.0 or later
- Xcode 15 or later
- An active Firebase project (see setup below)
- A device or simulator with location services enabled for geofencing features

---

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/your-username/SpendSense.git
cd SpendSense
```

### 2. Install dependencies

The project uses the Swift Package Manager. Open `SpendSense.xcodeproj` in Xcode and it will resolve packages automatically. Required packages:

- Firebase iOS SDK (`FirebaseAuth`, `FirebaseFirestore`)
- Google Sign-In for iOS

### 3. Add your Firebase configuration

1. Create a project at [console.firebase.google.com](https://console.firebase.google.com).
2. Add an iOS app with bundle ID `com.yourname.SpendSense`.
3. Download `GoogleService-Info.plist` and replace the existing placeholder file at the root of the `SpendSense/` folder.
4. Enable **Email/Password**, **Google**, and **Apple** sign-in methods in the Firebase Authentication console.
5. Create a Firestore database in test mode.

### 4. Configure App Groups

The main app and the widget extension share data via an App Group. In Xcode:

1. Select the `SpendSense` target → Signing & Capabilities → add App Groups.
2. Create a group named `group.com.yourname.SpendSense`.
3. Repeat for the `SpendSenseWidget` target using the same group name.
4. Update the `suiteName` in `WidgetDataStore.swift` to match.

### 5. Build and run

Select the `SpendSense` scheme, choose a simulator or device, and press **Run**.

---

## Project Structure

```
SpendSense/
├── App/
│   └── SpendSenseApp.swift          # Entry point, AppDelegate, notification setup
├── Core/
│   ├── Data/
│   │   ├── PersistenceController.swift
│   │   └── SpendSenseModel.xcdatamodeld/
│   ├── Models/
│   │   └── Models.swift             # TransactionModel, BudgetModel, UserProfileModel, etc.
│   └── ImpulseClassifier.mlmodel
├── Resources/
│   └── Theme.swift                  # Design tokens, colours, fonts
├── Services/
│   ├── CoreDataStore.swift
│   ├── FirebaseService.swift
│   ├── ImpulseRiskPredictor.swift
│   ├── LiveActivityManager.swift
│   ├── LocationNotificationService.swift
│   ├── LogTransactionIntent.swift   # Siri / AppIntents
│   ├── SpendSenseNotificationService.swift
│   └── WidgetDataStore.swift
├── ViewModels/
│   ├── SpendSenseViewModel.swift    # Main view model
│   ├── AddTransactionViewModel.swift
│   ├── AppStateViewModel.swift
│   └── OnboardingViewModel.swift
└── Views/
    ├── Alerts/
    ├── Auth/
    ├── Budget/
    ├── Home/
    ├── Insights/
    │   └── SpendingZonesMapView.swift
    ├── Onboarding/
    ├── Settings/
    ├── Transactions/
    ├── MainTabView.swift
    └── RootView.swift

SpendSenseWidget/
├── SpendSenseWidget.swift           # Home screen widget
├── SpendSenseWidgetLiveActivity.swift
└── WidgetDataStore.swift

SpendSenseTests/
└── SpendSenseTests.swift            # XCTest unit tests
```

---

## Spending Categories

| Category | Icon |
|---|---|
| Food & Dining | fork.knife |
| Transport | car.fill |
| Entertainment | popcorn.fill |
| Shopping | bag.fill |
| Health | heart.fill |
| Utilities | bolt.fill |
| Education | book.fill |
| Income | banknote.fill |
| Other | ellipsis.circle.fill |

---

## Impulse Risk Scoring

Each transaction receives a risk score from the `ImpulseRiskPredictor`:

1. **CoreML path** — The bundled `ImpulseClassifier.mlmodel` receives features including `amount`, `avgRecentAmount`, `amountRatio`, `hourOfDay`, `todayPurchaseCount`, `isHighRiskCategory`, and `isLateNight`.
2. **Heuristic fallback** — Used if the model is unavailable. Scoring factors:

| Signal | Score Added |
|---|---|
| Amount > 2× personal average | +0.35 |
| Amount > 1.3× personal average | +0.15 |
| Shopping or Entertainment category | +0.20 |
| Late-night purchase (22:00–04:59) | +0.20 |
| Evening purchase (20:00–21:59) | +0.10 |
| 5+ purchases already today | +0.15 |
| 3–4 purchases today | +0.08 |

Risk levels: **Low** (< 0.4) · **Moderate** (0.4–0.7) · **High** (≥ 0.7)

---

## Monitored Spending Zones (Colombo)

| Zone | Radius |
|---|---|
| One Galle Face Mall | 250 m |
| Majestic City | 180 m |
| Liberty Plaza | 180 m |
| Odel | 180 m |
| Food Street Area | 250 m |
| Crescat Boulevard | 180 m |
| WTC Food Court | 200 m |

An **Always** location permission is required for background geofence monitoring. The Spending Zones map screen includes a **Simulate zone entry** button to demonstrate the alert flow without physically visiting a location.

---

## Running Tests

Open the `SpendSense` scheme in Xcode and press **Cmd + U**. Tests run against an in-memory Core Data stack and cover:

- Monthly and daily budget derivation
- Transaction recording and balance updates
- Simulated transactions excluded from real totals
- Risk level thresholds (Low / Moderate / High)
- Budget creation and retrieval
- Wishlist item persistence

---

## License

This project was developed as a coursework submission. All rights reserved.

---

*Built with SwiftUI · Firebase · CoreML · ActivityKit · AppIntents*
