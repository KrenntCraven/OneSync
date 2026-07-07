# OneSync

OneSync is a **cashless canteen / food‑ordering platform** built with Flutter and Firebase. It replaces cash at school/campus food stalls with an **RFID card wallet**: students load money onto a card, and vendors accept payments by having the student tap the card on a reader at checkout.

The repository is a monorepo containing two Flutter applications that share the same Firebase backend:

| App | Audience | Purpose |
| --- | --- | --- |
| **OneSync (Vendor)** | Food‑stall owners / cashiers | Manage menu & stock, take orders, accept RFID payments, view history, forecast sales, and cash out earnings. |
| **OneSync (Customer)** | Students / cardholders | Register an RFID card, cash in (top up) the wallet, browse menus, and review transaction history. |

---

## Table of Contents

- [Features](#features)
- [Technology Stack](#technology-stack)
- [Repository Structure](#repository-structure)
- [Architecture](#architecture)
- [Backend & Data Model (Firebase "API")](#backend--data-model-firebase-api)
- [Core Flows](#core-flows)
- [RFID Hardware Bridge](#rfid-hardware-bridge)
- [Sales Forecasting (TensorFlow Lite)](#sales-forecasting-tensorflow-lite)
- [Getting Started](#getting-started)
- [Configuration](#configuration)
- [Testing](#testing)
- [Security Notes](#security-notes)

---

## Features

### Vendor app
- **Authentication** – email/password sign‑up & login (Firebase Auth), with store name stored on registration.
- **Menu management** – add products with image upload, price, stock, and category; edit product details.
- **Ordering** – searchable, category‑filtered product grid with an in‑memory cart.
- **RFID payment** – checkout listens to a Realtime Database node; when a card is tapped, the app validates the student's balance, atomically transfers funds, decrements stock, and records the transaction.
- **Inventory tracking** – view current stock levels.
- **Order history** – list of past transactions.
- **Sales forecasting** – on‑device TensorFlow Lite model predicts future sales, rendered with Syncfusion / fl_chart.
- **Cash out** – withdraw accumulated balance; each cash‑out is logged as a transaction.
- **Profile** – update store name, email (with verification steps), password, RFID, and profile image.

### Customer app
- **Authentication** – email/password sign‑up & login.
- **RFID registration** – link a physical card's reference number plus first/last name to the account.
- **Cash in** – top up the wallet balance, gated by a rotating 6‑digit code.
- **Dashboard & history** – view balance and detailed transaction history.
- **Ordering screens** – browse menus and view order/payment results.
- **Profile** – update password and account details.

---

## Technology Stack

- **Flutter** (Dart `>=3.3.1 <4.0.0`) – cross‑platform UI for Android, iOS, Web, Windows, macOS, and Linux.
- **Firebase**
  - **Firebase Auth** – user identity (email/password).
  - **Cloud Firestore** – primary application datastore (users, menus, transactions, metadata).
  - **Realtime Database** – live bridge between the app and the RFID reader hardware.
  - **Firebase Storage** – product and profile images.
- **TensorFlow Lite** (`tflite_flutter`) – on‑device sales prediction.
- **Charts** – `syncfusion_flutter_charts`, `fl_chart`.
- **State/UX** – `provider`, `image_picker`, `gallery_picker`, `flutter_svg`, `dotted_border`, `intl`, `uuid`, `csv`.

---

## Repository Structure

```
OneSync/
├─ README.md
├─ OneSync (Vendor)/
│  ├─ lib/
│  │  ├─ main.dart                 # App entry, Firebase init, routes, theme
│  │  ├─ navigation.dart           # Bottom navigation bar
│  │  ├─ firebase_options.dart     # Generated Firebase config
│  │  ├─ models/
│  │  │  ├─ models.dart            # MenuItem model
│  │  │  └─ transaction.dart       # Transaction model
│  │  └─ screens/
│  │     ├─ (Auth)/                # Welcome, login, sign up, auth wrapper
│  │     ├─ Home/                  # Home dashboard, inventory, cashout
│  │     ├─ MenuList/              # Menu list, add/edit product
│  │     ├─ Order/                 # Order, cart, payment (RFID), history
│  │     ├─ Forecast/             # Sales predictor + charts/tables
│  │     ├─ Profile/               # Profile & account editing
│  │     └─ utils.dart             # Firebase auth/storage helper functions
│  ├─ assets/                      # Images, .tflite model, sample CSV
│  ├─ fonts/                       # Poppins
│  └─ android/ ios/ web/ windows/ macos/ linux/
└─ OneSync (Customer)/
   ├─ lib/
   │  ├─ main.dart
   │  ├─ navigation.dart
   │  ├─ models/                   # MenuItem, Transaction
   │  └─ screens/
   │     ├─ (Auth)/                # Login, sign up, RFID input, registered
   │     ├─ Dashboard/             # Dashboard, cash in, history, detail
   │     ├─ Menu/                  # Menu browsing
   │     ├─ Order/                 # Order, cart, payment result
   │     └─ Profile/               # Profile, password update
   └─ android/ ios/ web/ windows/ macos/ linux/
```

---

## Architecture

Both apps follow a pragmatic layered Flutter structure. There is no dedicated server — **Firebase acts as the backend ("serverless")**, and the apps talk to it directly through the official Firebase SDKs.

```
┌──────────────────────────────────────────────────────────┐
│                     Flutter App (Vendor / Customer)        │
│                                                            │
│  UI Layer            lib/screens/**  (StatefulWidgets)     │
│      │                                                     │
│  Navigation          lib/navigation.dart, MaterialApp routes│
│      │                                                     │
│  Domain Models       lib/models/**  (MenuItem, Transaction)│
│      │                                                     │
│  Service Helpers     lib/screens/utils.dart                │
│                      (auth, storage, image helpers)        │
└───────────┬───────────────┬──────────────┬────────────────┘
            │               │              │
            ▼               ▼              ▼
   Firebase Auth     Cloud Firestore   Realtime DB + Storage
   (identity)        (app data)        (RFID bridge, files)
                                              │
                                              ▼
                                     RFID reader hardware
                                     (ESP/Arduino, etc.)
```

Key architectural points:

- **UI Layer** – screens are `StatefulWidget`s that call Firebase directly (no repository abstraction); loading/error states handled with `setState` and `SnackBar`s.
- **Auth gate** – `AuthenticationWrapper` uses `FirebaseAuth.authStateChanges()` to route between the login screen and the home screen.
- **Models** – `MenuItem` and `Transaction` provide `fromSnapshot` / `fromFirestore` factories to map Firestore documents into typed objects.
- **Multi‑tenant by UID** – each vendor's data is namespaced under their Firebase Auth `uid` (e.g. `Menu/{uid}/vendorProducts`), so vendors only see their own catalog.
- **Atomic money movement** – payments use a Firestore `runTransaction` so that student debit, vendor credit, stock decrement, and transaction record all commit together.

---

## Backend & Data Model (Firebase "API")

Because OneSync is serverless, the "API" is the set of Firebase collections/paths the apps read and write. The main entities are below.

### Cloud Firestore

**`Menu/{vendorUid}`** — vendor account / storefront
| Field | Type | Notes |
| --- | --- | --- |
| `email` | string | Vendor email |
| `Vendor Name` | string | Store display name |
| `Balance` | int | Vendor earnings (PHP) |
| `UID` | string | RFID/account identifier used in cash‑out records |

**`Menu/{vendorUid}/vendorProducts/{productId}`** — menu items (maps to `MenuItem`)
| Field | Type | Notes |
| --- | --- | --- |
| `name` | string | Product name |
| `price` | number | Unit price |
| `stock` | number | Available quantity |
| `imageUrl` | string | Storage/download URL |
| `category` | string | e.g. Main Dishes, Snacks, Beverages |

**`Student-Users/{studentUid}`** — customer wallet
| Field | Type | Notes |
| --- | --- | --- |
| `rfid` | string | Card reference number / UID |
| `firstName`, `lastName` | string | Cardholder name |
| `Balance` | int | Wallet balance (PHP) |

**`Transactions/{transactionId}`** — unified ledger (orders, cash‑in, cash‑out)
| Field | Type | Notes |
| --- | --- | --- |
| `type` | string | `order`, `cashout`, or `Cash In` |
| `totalPrice` | number | Amount |
| `date` | Timestamp | Server/local timestamp |
| `items` | array | `{ name, quantity }` (orders only) |
| `rfid` | string | Card UID involved |
| `currentUid` | string | Acting user's UID |
| `transactionId` | string | Random 8‑char id (or `Transaction{n}`) |

**`Meta/TransactionNumber`** — `{ number: int }` monotonically increasing counter for sequential order IDs.

**`Cash-In/6 Digit Code`** — `{ Code: string }` rotating 6‑digit code that authorizes a cash‑in; regenerated after each successful top‑up.

### Realtime Database

**`RFID`** — live channel shared with the physical reader
| Field | Type | Written by | Meaning |
| --- | --- | --- | --- |
| `Total` | int | App | Amount currently due at checkout |
| `Tapped` | int | App | `1` = waiting for a tap, `0` = idle |
| `UID` | string | Reader | UID of the tapped card (cleared after use) |
| `Status` | int | App | `0` idle · `1` insufficient balance · `2` RFID not found · `3` success |

### Firebase Storage

| Path | Contents |
| --- | --- |
| `{userId}/uploads/products/{timestamp}-{filename}` | Product images |
| `{userId}/profile/profile_image.jpg` | Profile picture |

---

## Core Flows

### 1. Vendor registration & login
`createAccountWithEmailPassword` creates the Auth user, sets the display name to the store name, and writes a `Menu/{uid}` document. `AuthenticationWrapper` then keeps the user on the home screen while signed in.

### 2. Placing & paying for an order (Vendor + RFID)
1. Vendor builds a cart on the **Order** screen; the running total is mirrored to `RFID/Total` in Realtime DB.
2. On **Pay Now**, the app sets `RFID/Tapped = 1` and listens on `RFID/UID`.
3. The student taps their card; the reader writes the card UID to `RFID/UID`.
4. The app looks up the student in `Student-Users` by `rfid` and validates the balance:
   - not found → `Status = 2`,
   - insufficient → `Status = 1`,
   - otherwise proceed.
5. A Firestore transaction atomically: debits the student, credits the vendor, decrements each product's `stock`, and writes a `Transactions` record; then `Status = 3`.
6. The RFID node is reset (`Status/Tapped/Total/UID → 0/empty`) and the success screen is shown.

### 3. Cash in (Customer)
The student enters an amount plus the current 6‑digit code (`Cash-In/6 Digit Code`). On success, `Student-Users/{uid}.Balance` is incremented, a `Cash In` transaction is logged, and a new 6‑digit code is generated.

### 4. Cash out (Vendor)
The vendor withdraws up to their `Menu/{uid}.Balance`. The balance is decremented and a `cashout` transaction is recorded.

---

## RFID Hardware Bridge

OneSync expects an external RFID reader (e.g. an ESP32/Arduino with an RC522 module) connected to the **same Firebase Realtime Database**. The contract:

- The **reader watches** `RFID/Tapped`; when it is `1`, it waits for a card and writes the scanned UID to `RFID/UID`.
- The **app watches** `RFID/UID`; when populated, it processes payment and writes back `RFID/Status`.
- After completion, the app clears the node so the next transaction starts clean.

> The Realtime DB node is effectively a small state machine (`Tapped` → `UID` → `Status` → reset). Any device that respects these fields can act as the reader.

---

## Sales Forecasting (TensorFlow Lite)

The vendor app ships an on‑device model at `assets/simple_model.tflite`, wrapped by `SalesPredictor`:

- **Input**: a `[1, 5, 7]` tensor (5 time steps × 7 normalized features derived from the date and past sales).
- **Output**: a single value, de‑normalized in `postProcess` back to a sales figure.
- `Meal_Orders_Transactions.csv` provides sample historical data used alongside the forecast charts.

The model is loaded via `Interpreter.fromAsset` and run entirely on the device (no network inference).

---

## Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel) with the bundled Dart SDK.
- Android Studio / Xcode for mobile builds; Chrome for web.
- A configured Firebase project (see [Configuration](#configuration)).

### Run the Vendor app
```bash
cd "OneSync (Vendor)"
flutter pub get
flutter run
```

### Run the Customer app
```bash
cd "OneSync (Customer)"
flutter pub get
flutter run
```

Select a target device with `flutter devices` / `flutter run -d <device>`.

---

## Configuration

Each app is configured independently:

1. **Firebase config** – `lib/firebase_options.dart` (and platform files such as `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`, `firebase.json`). Regenerate with the FlutterFire CLI if you point the apps at your own project:
   ```bash
   flutterfire configure
   ```
2. **Enable Firebase services** – Authentication (Email/Password), Cloud Firestore, Realtime Database, and Storage must all be enabled in the Firebase console.
3. **Realtime Database node** – create an `RFID` node with the fields described above and connect your reader hardware.
4. **Syncfusion license** – the vendor app registers a Syncfusion license key in `main.dart`. Replace it with your own key for production use.

> If the two apps use separate Firebase projects, keep their schemas in sync so orders, wallets, and the RFID bridge line up.

---

## Testing

Run tests from within each app folder:

```bash
flutter test
```

Static analysis (lints defined in `analysis_options.yaml`):

```bash
flutter analyze
```

---

## Security Notes

These reflect the current implementation and are worth hardening before production:

- **Secrets in source** – the Syncfusion license key is hard‑coded in `main.dart`; move secrets out of version control.
- **Firestore/RTDB rules** – ensure security rules restrict each vendor to their own `Menu/{uid}` subtree and each student to their own `Student-Users/{uid}` document, and lock down the shared `RFID` node.
- **Cash‑in code** – the 6‑digit code is stored in plaintext in Firestore; treat it as a shared secret and consider server‑side validation.
- **Client‑side money logic** – balance/stock changes happen client‑side within a Firestore transaction; consider Cloud Functions for authoritative, tamper‑resistant processing.
```
