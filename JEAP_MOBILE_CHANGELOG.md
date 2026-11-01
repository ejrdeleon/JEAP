# JEAP Mobile — Complete Development Changelog & Architecture Guide

> **Current Version:** `1.0.0+1` (Targeting Android, Flutter SDK 3.6+)  
> **Backend:** Laravel 11 REST API with Laravel Sanctum Authentication  
> **Database:** MySQL (managed via Laravel migrations, seeders, and Eloquent models)  
> **Target Branch:** [`MobileCommits`](https://github.com/ejrdeleon/JEAP/tree/MobileCommits)  
> **Documentation Last Updated:** 2026-11-01  

---

## Table of Contents

1. [Executive Summary & System Architecture](#1-executive-summary--system-architecture)
2. [Priority 1 — Philippine Address Selection System (PSGC)](#2-priority-1--philippine-address-selection-system-psgc)
3. [Priority 2 — Dedicated Logistics Mobile Role & Scanning Module](#3-priority-2--dedicated-logistics-mobile-role--scanning-module)
4. [Priority 3 — Courier & Rider Operational Features](#4-priority-3--courier--rider-operational-features)
5. [Priority 4 — Shopee-Inspired Restricted Guest Mode](#5-priority-4--shopee-inspired-restricted-guest-mode)
6. [Priority 5 — Core UI/UX, Layout Bug Fixes & Responsive Design](#6-priority-5--core-uiux-layout-bug-fixes--responsive-design)
7. [Priority 6 — Authentication, Password Recovery & Account Features](#7-priority-6--authentication-password-recovery--account-features)
8. [Backend Integration & Laravel API Enhancements](#8-backend-integration--laravel-api-enhancements)
9. [Automated Test Suite & Verification Results](#9-automated-test-suite--verification-results)
10. [Local Utilities, Deployment & Server Tooling](#10-local-utilities-deployment--server-tooling)
11. [Complete File Manifest (Created & Modified)](#11-complete-file-manifest-created--modified)

---

## 1. Executive Summary & System Architecture

JEAP (Joint E-Commerce & Automated Parcel Logistics) is a multi-role e-commerce ecosystem. The mobile client is engineered exclusively in Flutter & Dart, connecting to a centralized Laravel REST API. 

### Role Separation Matrix

| Role | Interface Type | Dashboard Screen | Key Capabilities |
|---|---|---|---|
| **Buyer** | Mobile App | `BuyerHomeScreen` | Browse products, guest/buyer cart, order placement, order tracking, address management, rating, wishlist. |
| **Seller** | Mobile App | `SellerDashboardScreen` | Product listing, order fulfillment, delivery handovers. |
| **Courier / Rider** | Mobile App | `RiderHomeScreen` | Assigned deliveries, route navigation, fleet view, daily vehicle safety check, proof of delivery upload. |
| **Logistics Hub** | Mobile App | `LogisticsDashboardScreen` | Central hub operations, barcode/QR camera scanning, manual tracking lookup, bay sorting, manifest dispatch. |
| **Administrator** | Web-Only | Web Console (`/admin`) | Platform supervision, user verification, system-wide management. (Restricted from mobile dashboard). |

---

## 2. Priority 1 — Philippine Address Selection System (PSGC)

### Diagnosis & Root Causes Resolved
* **Endpoint Inconsistency**: The Flutter application previously queried `/api/v1/locations/provinces/{code}/cities-municipalities`, while the backend routes only responded to `/cities`.
* **Database Disconnect**: Location codes in earlier iterations were arbitrary strings that did not match the official 9-digit Philippine Standard Geographic Code (PSGC).
* **NCR Special Handling**: The National Capital Region (NCR) contains no provincial tier, requiring direct cascading from Region to City/Municipality.

### Completed Implementation
* **Dataset Standards**: Integrated the official Philippine Statistics Authority (PSA) PSGC 2024 dataset.
  * **Region IV-A (CALABARZON)**: PSGC Code `040000000`
  * **Laguna Province**: PSGC Code `043400000` (All 30 Component Cities and Municipalities: *Santa Cruz, Calamba, Biñan, San Pedro, Santa Rosa, Cabuyao, Los Baños, Bay, Pagsanjan, Victoria, Magdalena, Majayjay, Liliw, Nagcarlan, etc.*)
  * **Santa Cruz (Provincial Capital)**: PSGC Code `043426000`, Postal Code `4009` (All 26 Official Barangays: *Poblacion I-V, Gatid, Bubukal, Bagumbayan, Labuin, Oogong, Santisimo Rosario, etc.*)
  * **NCR Metro Manila**: Direct region-to-city mapping for all 17 LGUs (Manila, Quezon City, Makati, Taguig, Pasig, etc.).
* **Cascading Selection Logic**:
  * Selecting Region resets incompatible Province, City, and Barangay.
  * Selecting Province loads associated Cities/Municipalities.
  * Selecting City loads valid Barangays and automatically sets the standard Postal Code.
* **Network Reliability & Caching**:
  * Added in-memory caching in `LocationService` (`location_service.dart`).
  * Embedded local fallback datasets so users can select valid Laguna/NCR addresses even during intermittent network disconnects.

---

## 3. Priority 2 — Dedicated Logistics Mobile Role & Scanning Module

### Role-Based Authentication & Redirection
* Upon logging in via `login_screen.dart`, the authenticated user's role is checked against `role == 'logistics'` or `roles.contains('logistics')`.
* Logistics operators are automatically routed directly to `LogisticsDashboardScreen`.

### Warehouse Hub Dashboard (`LogisticsDashboardScreen`)
* **Real Database Integration**: Connected to Laravel's `OrderStatus` PHP Enum (`READY_FOR_PICKUP`, `PICKED_UP`, `AT_SORTING_CENTER`, `SORTED`, `ASSIGNED_TO_RIDER`, `OUT_FOR_DELIVERY`).
* **Live Metric Cards**:
  * **Incoming**: Parcels pending pickup or heading to the hub.
  * **Received**: Parcels verified at the inbound dock (`AT_SORTING_CENTER`).
  * **Sorting**: Parcels currently being sorted by destination zone.
  * **Ready Dispatch**: Parcels sorted and staged for delivery (`SORTED`).
  * **Outgoing Fleet**: Parcels dispatched to active riders (`ASSIGNED_TO_RIDER` / `OUT_FOR_DELIVERY`).
* **Interactive Modals**: Tapping on any metric tile opens a bottom sheet listing all parcels currently in that operational stage.
* **Clickable Scan Activity**: Tapping any scan event in the Recent Hub Activity list immediately navigates to `ScanResultScreen` for that parcel.

### Barcode & QR Scanner (`LogisticsScannerScreen`)
* **Hardware Camera Integration**: Connected Flutter's `camera` package via `CameraController` with back-camera lens auto-selection, torch/flashlight toggle (`setFlashMode`), and real-time `CameraPreview` inside the scanning viewfinder.
* **Visual Viewfinder Overlay**: High-contrast scanner boundary with gold corner brackets and pulsing scan guides.
* **Single-Line Lookup Button**: Solved button width constraints (`width: 110px`, `maxLines: 1`, `softWrap: false`) to permanently eliminate awkward `"Looku / p"` word wrapping.
* **1-Tap Quick Test Chips**: Embedded instant test chips (`JEPLGN1001IN`, `JEPLGN1002SRT`, `JEPLGN1003DSP`, `JEPLGN1006DSP`) directly above the manual input bar for rapid testing without physical barcodes.

### Parcel Details & Live Operations (`ScanResultScreen`)
* Decodes tracking numbers (e.g., `JEPLGN1001IN`) and queries `/api/v1/logistics/parcels/{id}`.
* Displays recipient name, phone, full destination address, origin hub, parcel total amount, payment method, and allowed actions.
* **Real Backend State Transitions**:
  * `receive` (`PICKED_UP` → `AT_SORTING_CENTER`)
  * `sort` (`AT_SORTING_CENTER` → `SORTED`)
  * `dispatch` (`SORTED` → `ASSIGNED_TO_RIDER`)
  * `transfer` (`AT_SORTING_CENTER` → Intra-hub transfer)
* Automatically writes audit events into the MySQL `parcel_scans` table and triggers immediate dashboard UI refresh upon completion.

---

## 4. Priority 3 — Courier & Rider Operational Features

### Rider Logistics Fleet (`RiderFleetScreen`)
* Connected to `GET /api/v1/rider/fleet`.
* Displays assigned delivery vehicle (e.g., *Honda Click 125i*), plate number (`LAG-8492`), fleet zone (*Laguna Sector 1 Central Hub*), and active status badge.

### Vehicle Details & Safety Checklist (`RiderVehicleScreen`)
* Connected to `GET/PUT /api/v1/rider/vehicle`.
* Features an interactive **5-Point Daily Safety Checklist**:
  1. Brake System (Front & Rear)
  2. Tire Condition & Pressure
  3. Headlights, Tail Lights & Turn Signals
  4. Rearview Mirrors & Horn
  5. Fuel Level & Engine Oil
* Allows riders to complete and submit vehicle safety readiness prior to commencing daily delivery shifts.

### Rider KYC Documents (`RiderDocumentsScreen`)
* Connected to `GET/POST /api/v1/rider/documents`.
* Provides verification tracking and upload capabilities for:
  * Professional Driver's License
  * Land Transportation Office (LTO) Official Receipt & Certificate of Registration (OR/CR)
  * Barangay / Police Clearance
* Visual status pills: `Approved` (Green), `Pending Review` (Amber), `Needs Resubmission` (Red).

---

## 5. Priority 4 — Shopee-Inspired Restricted Guest Mode

### Public Browsing Capabilities
* Unauthenticated visitors can tap **"Continue as Guest"** to access:
  * Full Storefront Home Tab with promotional banners, categories, flash deals, and bestsellers.
  * Category product grids with sorting and keyword search.
  * Public Product Detail screens with full specs, price, descriptions, and stock status.

### Local Encrypted Guest Cart (`GuestCartManager`)
* Implemented using `FlutterSecureStorage` (eliminating the need for temporary dummy database users).
* Guests can add items to cart, adjust quantities, toggle selection checkboxes, and delete items.
* Cart contents persist across app launches.

### Protected Feature Gating & Checkout Transition
* Restricted account features (Orders, Profile, Notifications, Delivery Addresses) prompt for login.
* Tapping **Checkout** from the Guest Cart triggers `_showGuestCheckoutGate()`, presenting clear options to **Sign In** or **Register**.
* **Seamless Cart Merge**: Once the guest signs in or registers, `GuestCartManager.instance.mergeIntoAccount(CartService())` transfers all local cart items directly to the authenticated buyer's server cart and clears the local cache.

---

## 6. Priority 5 — Core UI/UX, Layout Bug Fixes & Responsive Design

### 8.6px RenderFlex Bottom Overflow Resolved
* **Root Cause**: Product names spanning 2 lines (such as *"Durotan Manual Espresso Machine"*, *"Sona QLED Ultra HD 4K Smart TV"*, and *"iPad mini 2023 Wi-Fi 256GB"*) exceeded the fixed height allotted by grid delegates, causing an `8.6px bottom overflow`.
* **Architectural Fix**:
  * Rewrote `ProductCard` (`lib/core/widgets/product_card.dart`) with `LayoutBuilder`.
  * Wrapped the top image in `Expanded(child: imageStack)` under bounded constraints, allowing the image to flex dynamically and absorb varying title heights without overflowing.
  * Tuned `childAspectRatio` across `home_tab_screen.dart`, `category_products_screen.dart`, and `search_screen.dart` (values tuned between `0.58` and `0.65` depending on screen width).
  * Verified passing with zero errors across compact, standard, and large device widths and font scaling multipliers up to `1.5x`.

### Instant Image Synchronization (`JeapNetworkImage` & `JeapAvatar`)
* Implemented zero-delay image updates using cache-busting timestamping and resilient image placeholders.
* When a user updates their profile picture or a product image changes, it immediately updates across drawers, app bars, and detail views.

### Global Sidebar Navigation (`BuyerDrawer`)
* Consistent drawer navigation accessible across all main Buyer navigation tabs (Home, Categories, Cart, Orders, Account).
* Includes quick links to Wishlist, Order History, Address Book, Help & Support, and Server Configuration.

---

## 7. Priority 6 — Authentication, Password Recovery & Account Features

### Forgot Password Flow
* **Mobile Flow**:
  1. User taps "Forgot Password?" on `LoginScreen`.
  2. Enters registered email in `ForgotPasswordScreen`.
  3. Receives OTP/Verification Code via `EmailOtpScreen`.
  4. Enters new secure password in `ResetPasswordScreen`.
  5. Account is updated and user is returned to sign-in.
* **Backend API**: Connected to `/api/v1/auth/forgot-password` and `/api/v1/auth/reset-password`.

### Dynamic Server Settings Sheet (`ServerSettingsSheet`)
* Accessible via gear icon on the login screen to allow on-the-fly switching between backend endpoints without recompiling:
  * **Localhost / USB ADB Reverse**: `http://127.0.0.1:8080/api/v1`
  * **Android Emulator Default**: `http://10.0.2.2:8080/api/v1`
  * **Local Wi-Fi LAN**: `http://<LAN_IP>:8080/api/v1`
  * **Custom Server URL**

---

## 8. Backend Integration & Laravel API Enhancements

### New & Enhanced Controllers (`EcomV2-main/app/Http/Controllers/Api/V1/`)
* **`LocationController.php`**:
  * `GET /api/v1/locations/regions`
  * `GET /api/v1/locations/regions/{code}/provinces`
  * `GET /api/v1/locations/provinces/{code}/cities` (with `/cities-municipalities` alias)
  * `GET /api/v1/locations/cities-municipalities/{code}/barangays`
  * `GET /api/v1/locations/search`
* **`LogisticsController.php`**:
  * `GET /api/v1/logistics/dashboard` (Live hub operational statistics and recent activity)
  * `GET /api/v1/logistics/parcels/{identifier}` (Lookup by tracking number or order number)
  * `POST /api/v1/logistics/scan` (Process hub scan operations: `receive`, `sort`, `dispatch`, `transfer`)
  * `GET /api/v1/logistics/audit-log` (Audit trail of hub scans)
* **`RiderProfileController.php`**:
  * `GET /api/v1/rider/fleet`
  * `GET /api/v1/rider/vehicle`
  * `PUT /api/v1/rider/vehicle` (Updates 5-point checklist status)
  * `GET /api/v1/rider/documents`
  * `POST /api/v1/rider/documents` (KYC file upload)
* **`NotificationController.php`**:
  * `GET /api/v1/notifications`
  * `POST /api/v1/notifications/{id}/read`
  * `POST /api/v1/notifications/read-all`

### Model Enhancements
* **`Order.php`**:
  * Added `shippingAddress(): BelongsTo` and `address(): BelongsTo` relationship aliases targeting `App\Models\Address`.
  * Status cast cleanly to `App\Enums\OrderStatus` Enum.

---

## 9. Automated Test Suite & Verification Results

### Test Execution Commands & Status

```bash
# Static analysis check
cd jeap_mobile
flutter analyze lib/
# Result: No issues found! (0 errors, 0 warnings)

# Run full priority test suite
flutter test test/product_card_overflow_fix_test.dart test/location_psgc_test.dart test/global_sidebar_navigation_test.dart test/comprehensive_four_priorities_test.dart
# Result: All 25 tests passed! (100% success rate)
```

### Verified Test Suites
1. **`product_card_overflow_fix_test.dart`** (4/4 passed): Validates that 2-line product titles and large font scalers render without RenderFlex overflow.
2. **`location_psgc_test.dart`** (2/2 passed): Validates Laguna LGUs, Santa Cruz barangays, and cascading address selection modal.
3. **`global_sidebar_navigation_test.dart`** (6/6 passed): Validates drawer accessibility across all Buyer tabs and back-stack integrity.
4. **`comprehensive_four_priorities_test.dart`** (13/13 passed): Comprehensive end-to-end testing of PSGC Address, Logistics Dashboard, Scanner, Scan Result, Rider Fleet, Vehicle Checklist, Documents, and Guest Mode.

---

## 10. Local Utilities, Deployment & Server Tooling

### Local Executables & Scripts

| File Name | Location | Purpose |
|---|---|---|
| `deploy_to_phone.bat` | Root (`/`) | Automatically checks ADB connection, sets up `tcp:8080` port reverse forwarding, and installs `app-debug.apk` to a connected Samsung Galaxy S25. |
| `start_backend.bat` | Root (`/`) | Auto-detects local Wi-Fi IP, configures port forwarding, and starts the Laravel backend on `http://0.0.0.0:8080`. |
| `start.exe` / `stop.exe` | Root (`/`) | Standalone desktop launchers to start and stop background services with a double click. |
| `Start JEAP.bat` / `Stop JEAP.bat` | `EcomV2-main/` | Quick batch launchers located inside the Laravel project root. |

> **Note**: All `.bat` and `.exe` local tooling files are registered in `.gitignore` to prevent polluting Git commits while remaining permanently available on your local workstation.

---

## 11. Complete File Manifest (Created & Modified)

### Flutter Client (`jeap_mobile/`)

#### Core Architecture & Widgets
* `lib/core/widgets/product_card.dart` — Responsive product card with flex layout.
* `lib/core/storage/guest_cart_manager.dart` — Encrypted local guest cart storage.
* `lib/core/storage/wishlist_manager.dart` — Local wishlist persistence.
* `lib/core/widgets/jeap_network_image.dart` — Network image widget with instant fallback.
* `lib/core/widgets/jeap_avatar.dart` — User profile avatar with real-time sync.
* `lib/core/widgets/server_settings_sheet.dart` — Dynamic API host configuration modal.
* `lib/core/theme/rider_theme.dart` — High-contrast dark theme for rider interface.
* `lib/core/widgets/guest_prompt_view.dart` — Reusable login gate view.

#### Logistics Module
* `lib/features/logistics/models/logistics_parcel.dart` — Models for parcels, hub statistics, and scan activities.
* `lib/features/logistics/services/logistics_service.dart` — API client for logistics hub and scanning endpoints.
* `lib/features/logistics/presentation/screens/logistics_dashboard_screen.dart` — Warehouse operational hub dashboard.
* `lib/features/logistics/presentation/screens/logistics_scanner_screen.dart` — Camera scanner with flash toggle and quick test barcodes.
* `lib/features/logistics/presentation/screens/scan_result_screen.dart` — Parcel scan details and live dispatch action processing.

#### Courier / Rider Module
* `lib/features/tasks/presentation/screens/rider_fleet_screen.dart` — Assigned vehicle and fleet sector.
* `lib/features/tasks/presentation/screens/rider_vehicle_screen.dart` — Vehicle specifications & 5-point safety checklist.
* `lib/features/tasks/presentation/screens/rider_documents_screen.dart` — KYC document submission and status tracking.
* `lib/features/tasks/presentation/widgets/proof_of_delivery_sheet.dart` — Camera capture for delivery confirmation proof.

#### Location & Philippine Address
* `lib/features/location/services/location_service.dart` — PSA PSGC dataset integration, caching, and fallback.
* `lib/features/location/widgets/philippine_address_selector.dart` — Cascading Region → Province → City → Barangay selector.

#### Authentication & Guest Mode
* `lib/features/auth/presentation/screens/login_screen.dart` — Multi-role navigation router and guest cart merging.
* `lib/features/auth/presentation/screens/forgot_password_screen.dart` — Password reset email submission.
* `lib/features/auth/presentation/screens/email_otp_screen.dart` — OTP verification input.
* `lib/features/auth/presentation/screens/reset_password_screen.dart` — New password creation screen.
* `lib/features/cart/presentation/screens/cart_screen.dart` — Guest cart display with checkout gating.

### Laravel Backend (`EcomV2-main/`)
* `app/Http/Controllers/Api/V1/LocationController.php` — PSGC location endpoints.
* `app/Http/Controllers/Api/V1/LogisticsController.php` — Logistics hub dashboard, parcel lookup, and scan handler.
* `app/Http/Controllers/Api/V1/RiderProfileController.php` — Fleet, vehicle safety check, and document APIs.
* `app/Http/Controllers/Api/V1/NotificationController.php` — In-app notification management.
* `app/Models/Order.php` — Added `shippingAddress` and `address` Eloquent relations.
* `routes/api.php` — Route registration for location, logistics, rider, and notifications.

---

### GitHub Publication Confirmation

All latest changes are pushed and live on the repository:
* **Branch**: [`MobileCommits`](https://github.com/ejrdeleon/JEAP/tree/MobileCommits)
* **Latest Hash**: `eb4d619`
* **Main Branch**: Left completely untouched.
