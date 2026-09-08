# MagisStore

A Flutter prelim project for Ateneo de Davao campus essentials. The student journey replaces the bookstore paper slip and cashier trip with online ordering, payment confirmation, and one express pickup.

## Run

    flutter pub get
    flutter run -d chrome

## Verify

    flutter analyze
    flutter test
    flutter build web --no-web-resources-cdn

## Features

- Responsive two-column phone grid, three or more columns on tablets.
- Product categories, search, sorting, favorites, and an app-wide light/dark toggle.
- Seven campus products with clean, rotatable geometry, zoom controls, and front/back rendered galleries.
- Cart quantity controls and live subtotals.
- Reservations for unavailable variants, pickup points, time slots, and payment confirmation.
- Digital QR claim tickets and order history.
- Navigation 2.0 through go_router, centralized ThemeData, and reusable Stateless/Stateful widgets.

The default announcement is “New semester. Ready, set, Ateneo.” The app header uses the official Ateneo de Davao seal supplied by the user. The pin uses the supplied official seal as a front surface texture. No supplied photographs are displayed, used as model textures, or bundled in the release application. The staff section and camera scanner have been removed.

## Classroom implementation

This is a local academic prototype, not a live university store. Payment methods are simulated; no money moves and no credentials are collected. Prices, stock, pickup capacity, and restock timelines are fixtures. SharedPreferences persists state on the current device. The interface uses normal customer-facing wording; implementation limitations are documented here rather than repeated across screens.

Checkout defaults to a successful local payment. Automated tests inject pending/failed outcomes through Store(paymentOutcome: ...), without an outcome selector in the user interface. Order processing and restock currently require repository updates; no live bookstore feed, push service, or authentication backend is connected. Production use would require authenticated server-side payments, inventory, fulfillment, and claim validation.

The models are stylized reconstructions with approximate dimensions and simplified seal details. Update lib/reference_model.dart for geometry. Regenerate the catalog images with:

    flutter test --no-pub tool/render_models.dart

lib/product_viewer.dart owns the interactive viewer. lib/store.dart owns shared application state. main.dart defines routes. The source photos remain in the development folder only and are excluded from pubspec assets. Earlier illustration generators are legacy assets and are not the active model renderer.

## Submission

The exam requests the branch PrelimExam in your subject repository. Repository setup and submission remain your steps. Manrope is bundled under its SIL Open Font License in assets/fonts/OFL.txt.
