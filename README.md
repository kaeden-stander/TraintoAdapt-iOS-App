# TrainToAdapt iOS App

Native iOS app for [traintoadapt.co.uk](https://traintoadapt.co.uk), built with SwiftUI. The **client** experience (booking, plans, billing, account) is wired to the real TrainToAdapt backend (Supabase + a REST API); **Trainer** and **Admin** are a separate Demo Mode built on sample data, since the current backend only exposes client-facing endpoints.

## Branding

The app icon and login screen use the TrainToAdapt logo mark, sampled directly for two brand colours (`Resources/Assets.xcassets`):

- `AccentColor` — the cyan from the swoosh (`#58C6E3`), used app-wide as the tint colour for buttons, links and highlights (`Color.brandPrimary` in `Views/Shared/Color+Brand.swift`).
- `BrandSecondary` — the warm grey from the "T" (`#AFABA2`), used for muted/secondary brand accents (`Color.brandSecondary`).

The login screen (`Views/Auth/LoginView.swift`) is the one place styled to match the logo's black background exactly (`Color.brandInk`, forced dark regardless of system appearance), since it's the app's main branding moment; the rest of the app uses standard adaptive light/dark backgrounds with the brand cyan as accent, so lists and forms stay readable in both appearances.

## Requirements

- Xcode 16 or later
- iOS 17+ deployment target
- An Apple Developer account to run Sign in with Apple, HealthKit, or anything on a physical device (the Simulator can run everything else without one — see **Signing** below)

## Getting started

1. Open `TraintoAdapt.xcodeproj` in Xcode.
2. Select the `TraintoAdapt` scheme and a simulator (e.g. iPhone 16).
3. Build and run (`Cmd+R`).
4. On the login screen you can either:
   - **Sign in for real** with email/password, Sign in with Apple, or Sign in with Google — this talks to the live TrainToAdapt backend. You'll need a real client account (or use "Create Account" to make one). See **Real backend setup** below for the one-time dashboard configuration this needs.
   - Tap **Explore in demo mode** to reveal the old Client / Trainer / Admin quick-access buttons, which sign in instantly with local sample data and don't touch the network at all.

## What's built

### Live client experience (real backend)

Signing in for real (`Live/`) gets you:

- **Home**: waiver-signing prompt if needed, credits remaining, current plan, next booked session.
- **Book**: real availability from `/slots` (this already reflects Adam's Google Calendar — see below), book a session, see upcoming sessions, cancel.
- **Plans**: the same four pricing tabs as the website (Monthly, Pay as you go, Online, At your home), pulled from `/plans`; tapping a plan opens Stripe Checkout in Safari, and reloads your account afterwards.
- **Account**: profile, membership/credits summary, "Manage billing" (Stripe customer portal), receipts, sign out, and a delete-account link (mailto, per Apple's App Store requirement).

### Demo Mode (Trainer / Admin / sample Client)

Three role-based mock screens, routed by `RootTabView`, unchanged from local sample data — useful for seeing what a future Trainer/Admin experience could look like once the backend supports it:

- **Client**: home dashboard, book/cancel sessions, meal plan and macros, browse and RSVP to events, account with Apple Health/Watch data.
- **Trainer**: dashboard, schedule, client list and detail, meal plan editor.
- **Admin**: studio dashboard, manage clients/trainers, create/delete studio events.

### Apple Watch / Health integration

`HealthKitManager` (`Services/HealthKitManager.swift`) requests read access to steps, active energy, heart rate, resting heart rate, exercise minutes and workouts. An Apple Watch paired to the client's iPhone already syncs this data into Apple Health automatically, so reading from HealthKit is the standard, low-friction way to bring Watch data into the app. This shows up in the demo Client's Home tab and **Account → Health & Activity Data**. (It isn't wired into the live client experience yet, since the backend has no endpoint to receive it — see **Next steps**.)

## Real backend setup

The connection details (Supabase project URL/anon key, API base) are already in `Live/Config/AppConfig.swift` — that key is a publishable anon key, safe to ship; row-level security on the server means each signed-in client only ever sees their own data.

To turn on Apple/Google sign-in against your Supabase project, two one-time dashboard steps are needed (both are outside this repo):

1. **Supabase → Authentication → Sign In / Providers**
   - Enable **Apple**, and add the app's bundle ID (`uk.co.traintoadapt.app`) as an allowed audience. (This is required even though the app calls Apple's native sign-in itself — Supabase still verifies the token against a configured audience.)
   - Enable **Google**, with an OAuth Client ID/Secret from Google Cloud Console.
2. **Supabase → Authentication → URL Configuration**
   - Add `traintoadapt://auth-callback` to **Redirect URLs** — this is the custom URL scheme (already registered in `Info.plist`) that the Google sign-in browser flow redirects back to.

On the Apple side, **Sign in with Apple** needs to be enabled as a capability for the App ID in the Apple Developer portal, and you'll need to select your own team in Xcode's *Signing & Capabilities* tab (the project ships with automatic signing but no team, since that's tied to your Apple ID — see **Signing** below).

### How Google Calendar fits in

The app never talks to the Google Calendar API directly. Adam's calendar is already synced server-side: anything on it (and every other client's booking) shows up as `"status": "booked"` in the `/slots` response, so the booking screen just reads `/slots` and `/bookings` like any other endpoint. There's nothing to configure in the app for this.

### Auth implementation notes

`Live/Auth/SupabaseAuthService.swift` talks to Supabase's GoTrue REST API directly (no Supabase SDK dependency, to avoid adding a Swift Package dependency to the hand-written `.pbxproj`):

- Email/password and sign-up use the standard `password` and `signup` grants.
- **Sign in with Apple** uses the native `ASAuthorizationAppleIDProvider` (required by Apple when another social login is offered) and exchanges the identity token via GoTrue's `id_token` grant.
- **Sign in with Google** drives Supabase's `/authorize` endpoint through `ASWebAuthenticationSession` using PKCE, and exchanges the returned code via the `pkce` grant (falling back to parsing tokens from the redirect fragment if the project isn't using PKCE).
- Sessions are persisted in the Keychain (`Live/Auth/KeychainTokenStore.swift`), and access tokens are refreshed automatically shortly before they expire.

## Signing

`CODE_SIGNING_ALLOWED`/`REQUIRED` are turned off for the Simulator SDK only, so you can build and run in the Simulator with zero setup. Building for a physical device (needed for Sign in with Apple to work fully, and for real HealthKit data) requires selecting your own team in *Signing & Capabilities*.

## Architecture

```
TraintoAdapt/
  App/            App entry point
  Models/         Plain value types for the demo/mock layer
  Services/       Protocol-oriented mock data layer (Demo Mode)
  ViewModels/     @MainActor ObservableObject classes for Demo Mode screens
  Views/
    Auth/         Login (real sign-in + Demo Mode disclosure)
    Root/         Routes between live session / demo session / login
    Client/       Demo Mode client screens
    Trainer/      Demo Mode trainer screens
    Admin/        Demo Mode admin screens
    Shared/       Reusable rows, cards, badges, colours (shared by both)
  Live/
    Config/       Backend connection details
    Auth/         Keychain session store, Supabase REST auth, crypto helpers
    Networking/   Typed API client + response models for the real backend
    ViewModels/   @MainActor ObservableObject classes for the live screens
    Views/        Real Home / Book / Plans / Account screens, Safari wrapper
  Resources/      Assets.xcassets
```

`RootView` picks between three states: signed in for real (`authService.isSignedIn`, from `Live/Auth/SupabaseAuthService`) shows `LiveClientTabView`; signed in via Demo Mode (`appState.currentUser`) shows the original `RootTabView`; otherwise, `LoginView`.

The Demo Mode services (`AuthServiceProtocol`, `BookingServiceProtocol`, etc.) are still protocol-oriented with in-memory `Mock...` implementations, so if the backend adds Trainer/Admin endpoints later, those screens can be re-pointed the same way the client screens already were — new conformances, no view changes.

## Next steps

- **Trainer/Admin API**: once the backend exposes management endpoints, the same `Live/` pattern used for the client can be extended to replace those Demo Mode screens.
- **Push notifications**: session reminders, waiver nudges.
- **watchOS companion app**: a dedicated watch target, beyond the current HealthKit read integration.
- **Sync HealthKit workouts to the backend**: there's no endpoint for this yet; `HealthKitManager` currently only feeds the demo Client's Home tab.
- **Automated tests**: a unit test target for the live and demo view models, and UI tests for sign-in and booking.

## Development branch

This app is being developed on `claude/dazzling-wright-e8eh3t`.
