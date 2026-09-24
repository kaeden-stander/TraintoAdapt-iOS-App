# TrainToAdapt iOS App

Native iOS app for [traintoadapt.co.uk](https://traintoadapt.co.uk), built with SwiftUI. This is a working first pass: it opens and runs in Xcode with sample data, and the architecture is ready to swap in a real backend.

## Branding

The app icon and login screen use the TrainToAdapt logo mark, sampled directly for two brand colours (`Resources/Assets.xcassets`):

- `AccentColor` — the cyan from the swoosh (`#58C6E3`), used app-wide as the tint colour for buttons, links and highlights (`Color.brandPrimary` in `Views/Shared/Color+Brand.swift`).
- `BrandSecondary` — the warm grey from the "T" (`#AFABA2`), used for muted/secondary brand accents (`Color.brandSecondary`).

The login screen (`Views/Auth/LoginView.swift`) is the one place styled to match the logo's black background exactly (`Color.brandInk`, forced dark regardless of system appearance), since it's the app's main branding moment; the rest of the app uses standard adaptive light/dark backgrounds with the brand cyan as accent, so lists and forms stay readable in both appearances.

## Requirements

- Xcode 16 or later
- iOS 17+ deployment target
- An Apple Developer account only needed for running on a physical device or testing HealthKit (the Simulator has no real Health data, but HealthKit APIs still run)

## Getting started

1. Open `TraintoAdapt.xcodeproj` in Xcode.
2. Select the `TraintoAdapt` scheme and a simulator (e.g. iPhone 16).
3. Build and run (`Cmd+R`).
4. On the login screen, tap one of the three **Quick demo access** buttons (Client / Trainer / Admin) to sign in instantly with seeded sample data. Or sign in manually with any of:
   - `client@traintoadapt.co.uk`
   - `trainer@traintoadapt.co.uk`
   - `admin@traintoadapt.co.uk`
   - any password works in the mock auth layer

## What's built

Three role-based experiences behind a single login flow, routed by `RootTabView`:

- **Client**: home dashboard, book/cancel sessions, view meal plan and macros, browse and RSVP to events, account screen with membership info and Apple Health/Watch data.
- **Trainer**: dashboard with today's sessions, full schedule (complete/cancel bookings), client list with per-client detail, meal plan editor for each client.
- **Admin**: studio-wide dashboard, manage clients and trainers (change role, membership status, assign a trainer to a client, remove an account), create/delete studio events.

### Apple Watch / Health integration

`HealthKitManager` (`Services/HealthKitManager.swift`) requests read access to steps, active energy, heart rate, resting heart rate, exercise minutes and workouts. An Apple Watch paired to the client's iPhone already syncs this data into Apple Health automatically, so reading from HealthKit is the standard, low-friction way to bring Watch data into the app — no separate watch pairing step needed. This shows up in the client's Home tab and in **Account → Health & Activity Data**.

The HealthKit entitlement is already enabled (`TraintoAdapt/TraintoAdapt.entitlements`), and the required usage-description strings are set as build settings (`INFOPLIST_KEY_NSHealthShareUsageDescription` / `...UpdateUsageDescription`) rather than a static `Info.plist`, since this project uses Xcode's auto-generated Info.plist.

## Architecture

```
TraintoAdapt/
  App/            App entry point
  Models/         Plain value types: User, Booking, MealPlan/Meal, Event, HealthMetric
  Services/       Protocol-oriented data layer + in-memory mock implementations
  ViewModels/     @MainActor ObservableObject classes per screen/flow
  Views/
    Auth/         Login
    Root/         Role-based routing
    Client/       Client-only screens
    Trainer/      Trainer-only screens
    Admin/        Admin-only screens
    Shared/       Reusable rows, cards, badges, colours
  Resources/      Assets.xcassets
```

Every service (`AuthServiceProtocol`, `BookingServiceProtocol`, `MealPlanServiceProtocol`, `EventServiceProtocol`, `UserServiceProtocol`) is defined as a protocol with a `Mock...` implementation backed by an in-memory `MockDataStore` singleton, so all screens see consistent data (e.g. a session a client books shows up immediately on their trainer's schedule). View models depend on the protocols, not the concrete mock types, so a real backend can be dropped in later by writing new conformances — no view or view model code needs to change.

## Suggested next steps

- **Backend**: replace the `Mock*Service` types with implementations backed by a real API (Firebase, Supabase, a custom REST/GraphQL backend, etc.) and add a persisted session/token instead of the in-memory `AppState`.
- **Push notifications**: session reminders, trainer messages, event reminders.
- **Payments**: membership billing / pay-per-session (e.g. Stripe) for the admin and client flows.
- **watchOS companion app**: a dedicated watch target for starting/logging a booked session on-wrist, beyond the current HealthKit read integration.
- **Messaging**: in-app chat between client and trainer.
- **Automated tests**: a unit test target for the view models and services, and UI tests for the core booking flow.
- **Real auth**: replace mock sign-in with Sign in with Apple / OAuth and proper password handling.

## Development branch

This app is being developed on `claude/dazzling-wright-e8eh3t`.
