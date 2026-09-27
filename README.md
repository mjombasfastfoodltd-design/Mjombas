# MJOMBAS Flutter

A Flutter conversion of the original MJOMBAS Android application, preserving the original business flow and Firebase data model.

## Implemented
- Firebase anonymous authentication
- Firebase menu and active branch loading
- Real GPS permission and current location
- Nearest active branch selection
- Original Haversine distance calculation
- Original delivery-fee algorithm
- OpenStreetMap map with customer and branch markers
- OSRM road route from branch to customer
- Reverse-geocoded delivery address
- Delivery time estimate
- Saved customer profile using SharedPreferences
- M-PESA Till 3429801 and transaction-code validation
- Order creation using original MJ-YYYYMMDD-#### order numbering
- Branch, distance, GPS and delivery fee stored with orders
- Customer-only order history
- Live order status tracking
- In-app persisted notifications
- Favorites and cart
- Customer care
- Staff admin payment review screen (requires Firebase admin custom claim)
- MJOMBAS launcher icon

## Run in VS Code

Open this folder in VS Code, then:

```powershell
flutter clean
flutter pub get
flutter run -d R9ZW609QK7V
```

## Firebase

The Android Firebase configuration is under `android/app/google-services.json`.
The included Firestore rules allow public reads for menu/branches and restrict orders to the customer UID or an `admin` custom claim.

## iOS

The Dart code is cross-platform. On macOS, create the iOS host with `flutter create .` and add the standard iOS location usage description to `ios/Runner/Info.plist` before building.
