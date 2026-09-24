# TrainToAdapt iOS App

Native iOS app for [traintoadapt.co.uk](https://traintoadapt.co.uk), built with SwiftUI. The **client** experience (booking, plans, billing, account) is wired to the real TrainToAdapt backend (Supabase + a REST API); **Trainer** and **Admin** are a separate Demo Mode built on sample data, since the current backend only exposes client-facing endpoints.

## Branding

The app icon and UI use the TrainToAdapt logo mark, sampled directly for the brand colours (`Resources/Assets.xcassets`):

- `AccentColor` — the cyan from the swoosh (`#58C6E3`), used app-wide as the tint colour for buttons, links and highlights (`Color.brandPrimary` in `Views/Shared/Color+Brand.swift`), and as the navigation bar colour on every tab (`brandedNavigationBar()` in `Live/Views/BrandedChrome.swift`, applied to both the live client experience and Demo Mode).
- `BrandSecondary` — the warm grey from the "T" (`#AFABA2`), used for muted/secondary brand accents (`Color.brandSecondary`).
- `Color.brandInk` — the near-black behind the logo mark, used as the app's base background everywhere: the whole app forces dark mode (`.preferredColorScheme(.dark)` in `App/TraintoAdaptApp.swift`) so backgrounds are always black with white text, rather than switching to a lighter background in system light mode.
- `Color.brandSurface` — a solid, slightly-raised dark grey for cards and rows (`SectionCard`, plan cards, list rows). Everything that used to sit on `.thinMaterial` now sits on this instead — a blurred material reads muddy on a pure black background, so cards are solid surfaces with the cyan/grey brand colours doing the contrast work.

Navigation uses the standard Apple large-title style throughout: tab roots (Home, Book, Plans, Events, Admin, Account, Dashboard, Schedule, Clients) show a large title with the cyan nav bar behind it; pushed detail screens and modal forms (confirm booking, new event, edit meal plan) use the compact inline title, matching how Apple's own apps distinguish a tab's home screen from a task inside it.

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

- **Home**: waiver-signing prompt if needed, credits remaining, current plan, next booked session, today's Apple Health activity and your last workout.
- **Book**: a day picker plus a grid of open time slots from `/slots` (this already reflects Adam's Google Calendar — see below), book a session, see and cancel upcoming sessions.
- **Plans**: the same four pricing tabs as the website (Monthly, Pay as you go, Online, At your home), pulled from `/plans`, with the popular plan highlighted and pay-as-you-go priced from your own account's rate; tapping a plan opens Stripe Checkout in Safari (Apple Pay shows up there automatically — see **Payments** below) and reloads your account afterwards.
- **Events**: create (admin) and RSVP to studio events. There's no backend events endpoint yet, so these are stored on-device for now — see **Events (local for now)** below.
- **Admin** (only shown when `/me` reports `isAdmin: true`): an exploratory schedule view — see **Admin view** below.
- **Account**: profile, membership/credits summary, "Manage billing" (Stripe customer portal), receipts, sign out, and a delete-account link (mailto, per Apple's App Store requirement).

Meal planning was removed from Demo Mode for now (still in the codebase, just not reachable from the tab bar/quick links) — ask if you want it back.

### Admin view

The backend guide only documents client-facing endpoints — there's no dedicated admin API. `LiveAdminView` calls the same `/bookings` endpoint every client uses and shows whatever comes back; if the backend's row-level security grants admin accounts a broader view (every client's bookings, not just their own), this becomes a real schedule for free. If not, it'll just show the admin's own bookings, and the screen says so. Worth confirming either way by signing in with a real admin account. `RemoteBooking` also decodes optional `client_name`/`client_email` fields in case an admin-scoped response includes them, even though they're not in the documented shape.

### Events (local for now)

`LiveEventsView` is a real, working events feature — admins can create/delete, everyone can RSVP — but since there's no backend endpoint for it yet, events are persisted as JSON on-device (`Live/Events/LocalEventStore.swift`). That means they won't sync across a client's other devices or show up for other clients until the backend adds a proper endpoint; the screen says this plainly. Once an endpoint exists, swap `LocalEventStore` for calls through `RemoteAPIClient`, the same way the mock `EventService` was replaced for bookings.

### Apple Watch / Health integration + in-app workout tracking

`HealthKitManager` (`Services/HealthKitManager.swift`) requests read access to steps, active energy, heart rate, resting heart rate, exercise minutes and workouts, and share access to log workouts. An Apple Watch paired to the client's iPhone already syncs its data into Apple Health automatically, so reading from HealthKit is the standard way to bring Watch data into the app — this is wired into both the demo Client's Home tab and the **live** Home tab (today's activity + last workout).

You don't need an Apple Watch to log a session, either: **Home → Track a Workout** (`Live/Views/LiveWorkoutTrackerView.swift`) is a simple start/pause/finish stopwatch that saves the completed workout to Apple Health via `HKWorkoutBuilder` when you finish, so it shows up in Health (and in this app) right alongside anything synced from a Watch.

### Session reminder notifications

Local notifications (no push/APNs setup needed) fire 1 hour and 30 minutes before each upcoming session. `Live/Notifications/SessionNotificationScheduler.swift` asks for permission once and reschedules everything from the current `/bookings` list whenever it's fetched, so cancelling or moving a session doesn't leave a stale reminder behind.

### Payments

Checkout happens through the web link the backend returns (`/checkout`), opened in Safari, per the backend guide's own instruction — not through Apple's in-app purchase. Apple's StoreKit/IAP is deliberately not used here: the guide relies on the "physical service" exception to Apple's in-app purchase requirement, and adding a native purchase button would put that at risk. The good news is **Apple Pay already works with zero extra code** — Stripe's hosted checkout page shows an Apple Pay button automatically on a supported device, so this is really just "open the link in Safari," already built.

## Real backend setup

The connection details (Supabase project URL/anon key, API base) are already in `Live/Config/AppConfig.swift` — that key is a publishable anon key, safe to ship; row-level security on the server means each signed-in client only ever sees their own data.

To turn on Apple/Google sign-in against your Supabase project, two one-time dashboard steps are needed (both are outside this repo):

1. **Supabase → Authentication → Sign In / Providers**
   - Enable **Apple**, and add the app's bundle ID (`uk.co.traintoadapt.app`) as an allowed audience. (This is required even though the app calls Apple's native sign-in itself — Supabase still verifies the token against a configured audience.)
   - Enable **Google**, with an OAuth Client ID/Secret from Google Cloud Console.
2. **Supabase → Authentication → URL Configuration**
   - Add `traintoadapt://auth-callback` to **Redirect URLs** — this is the custom URL scheme (already registered in `Info.plist`) that the Google sign-in browser flow redirects back to.

On the Apple side, **Sign in with Apple** needs to be enabled as a capability for the App ID in the Apple Developer portal, and you'll need to select your own team in Xcode's *Signing & Capabilities* tab (the project ships with automatic signing but no team, since that's tied to your Apple ID — see **Signing** below).

### Auto-login for website links

Opening the waiver or the client portal in Safari passes the app's current Supabase session along as a URL fragment (`SupabaseAuthService.authenticatedURL(_:)`), in the same `#access_token=...&refresh_token=...` shape Supabase's own auth redirects use. Most Supabase-backed web apps auto-detect and sign in from this on page load (it's the default behaviour of `detectSessionInUrl` in the Supabase JS client) — but this hasn't been verified against the actual website, so it's worth a quick check with whoever built it. If the site doesn't pick it up, the person just sees a normal login page instead, so this fails safe either way. Stripe checkout/billing-portal links are left untouched, since those already come back pre-authenticated from the backend.

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
    Events/       On-device event persistence (no backend endpoint yet)
    Notifications/ Local session-reminder scheduling
    ViewModels/   @MainActor ObservableObject classes for the live screens
    Views/        Real Home / Book / Plans / Events / Admin / Account screens,
                  workout tracker, Safari wrapper, branded nav bar helper
  Resources/      Assets.xcassets
```

`RootView` picks between three states: signed in for real (`authService.isSignedIn`, from `Live/Auth/SupabaseAuthService`) shows `LiveClientTabView`; signed in via Demo Mode (`appState.currentUser`) shows the original `RootTabView`; otherwise, `LoginView`.

The Demo Mode services (`AuthServiceProtocol`, `BookingServiceProtocol`, etc.) are still protocol-oriented with in-memory `Mock...` implementations, so if the backend adds Trainer/Admin endpoints later, those screens can be re-pointed the same way the client screens already were — new conformances, no view changes.

## Next steps

- **Admin/events APIs**: confirm what the `/bookings` endpoint actually returns for an admin account, and add a real events endpoint — see **Admin view** and **Events (local for now)** above.
- **Verify auto-login**: check that the website's Supabase client picks up the token-in-URL pattern described above; adjust the fragment shape if it expects something different.
- **Remote push notifications**: the current reminders are local-only (scheduled from data already on the device). Adding real push (waiver nudges, trainer messages, etc. sent from the backend) needs APNs setup — a Push Notifications capability, an aps-environment entitlement, and a server-side sender — none of which exists yet.
- **watchOS companion app**: a dedicated watch target for starting a booked session on-wrist, beyond the current phone-only workout tracker.
- **Sync in-app-tracked workouts to the backend**: they're saved to Apple Health, but the backend has no endpoint to also receive them directly.
- **Meal planning**: removed from Demo Mode navigation for now (code still present) — reinstate or rebuild against a real endpoint if wanted back.
- **Automated tests**: a unit test target for the live and demo view models, and UI tests for sign-in and booking.

## Development branch

This app is being developed on `claude/dazzling-wright-e8eh3t`.
