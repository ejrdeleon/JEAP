# JEAP Mobile App

A Flutter client for the Buyer and Rider roles. It shares the Laravel `/api` contract with the Vue web application.

## Features

## Buyer scope

- Login and registration
- Product browsing, search, and product details
- Cart and checkout
- Address selection and order history
- Order tracking, notifications, and ratings

## Rider scope

- Login and assigned deliveries
- Delivery details, pickup confirmation, and status updates
- Navigation and contact actions
- Proof of delivery using parcel/recipient photos
- Delivery history and earnings summary

## API and failure states

The client uses the Laravel API at `/api` with bearer-token authentication. Its default base URL is `https://jeap.store/api/v1`; override it at build time with `--dart-define=API_BASE_URL=https://your-api-host/api/v1`. Screens must show loading, empty, offline, expired-session, validation, and retry states. Cached catalog/order data may be read offline; mutations remain queued or visibly unavailable until connectivity returns.

## Setup Instructions

1. Ensure Flutter SDK (>=3.6.0) is installed.
2. Run `flutter pub get`.
3. Run `flutter run` on an iOS/Android device or emulator.

## Google sign-in setup

The app uses Google Sign-In to obtain a Google credential, exchanges it through Firebase Authentication for a Firebase ID token, and sends that token to the JEAP API. The backend must verify the Firebase token and return a Sanctum token plus the trusted JEAP user before Google login can succeed. Google identity does not create or approve JEAP roles.

Before running Google sign-in:

1. Register the Android application (`com.example.jeap_mobile`) and the iOS application/bundle ID in a Firebase project. Enable Google under Firebase Authentication providers.
2. Add the Android app's SHA-1 and SHA-256 signing fingerprints in Firebase and download the matching OAuth client configuration. Register the iOS URL scheme from `GoogleService-Info.plist` in the iOS Runner target.
3. Build with the Firebase client values and Google Web OAuth client ID (used as the server client ID): `FIREBASE_API_KEY`, `FIREBASE_PROJECT_ID`, `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_ANDROID_APP_ID` or `FIREBASE_IOS_APP_ID`, `FIREBASE_IOS_BUNDLE_ID` for iOS, and `GOOGLE_SERVER_CLIENT_ID`.
4. Set `API_BASE_URL` to the HTTPS Laravel API URL. Google token exchange is intentionally blocked for non-HTTPS URLs.
5. Implement `POST /api/auth/google` in Laravel. It must verify the Firebase ID token server-side, link only to an existing JEAP account under a safe verified-identity policy, enforce active account status, issue a Sanctum token, and return `{ "token": "…", "user": { …trusted fields… } }`. Do not accept a client-provided email or role as identity or authorization. Keep Firebase Admin credentials in the server environment.

The provided Rider.svg contains the JEAP logo only. Rider.png is the page reference for the courier dashboard, pickup and delivery lists/details, history, earnings, chat, account, profile editing, and login. Assignment lists read the rider API. The Laravel rider assignment index currently returns an empty placeholder and its assignment/status actions return HTTP 501; chat and earnings routes are also absent. Those screens show unavailable/empty states until the API workflows are implemented and cannot report successful delivery actions without backend support.
