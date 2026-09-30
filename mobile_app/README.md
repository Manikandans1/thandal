# Thandal – one app (Customer + Agent + Admin)

This project merges the three separate Thandal apps into a single Flutter app.
There is **one splash screen and one login screen**. The mobile number + PIN you
enter decides which app opens.

## Demo logins

| Role     | Mobile        | PIN  | Opens                  |
|----------|---------------|------|------------------------|
| Customer | 98765 43210   | 1234 | Customer app (Ravi Kumar) |
| Agent    | 98410 22017   | 1234 | Agent app (Karthik R)     |
| Admin    | 98400 00001   | 4321 | Admin app                 |

Wrong mobile/PIN shows the normal "Mobile number or PIN is incorrect" message.
Logging out from any app returns to the same login screen.

## Project layout

```
lib/
  main.dart                     single entry point, picks the theme per role
  core/auth/
    session.dart                roles + registered demo accounts (edit here)
    login_screen.dart           the ONE shared login screen
  apps/
    customer/   original customer app code (unchanged)
    agent/      original agent app code    (unchanged)
    admin/      original admin app code    (unchanged)
```

Each app keeps its own screens, widgets, models, mock data and theme, so nothing
in one app can clash with another. Inside each app, `screens/auth/login_screen.dart`
now just re-exports the shared login so existing logout / "set new PIN"
navigation keeps working.

## Run

```
flutter pub get
flutter run
```

Android / iOS app id: `com.example.thandal`, display name "Thandal".

## Adding real accounts later

Replace `Session.authenticate(...)` in `lib/core/auth/session.dart` with a call
to your backend that returns the user's role (`customer`, `agent` or `admin`).
Nothing else needs to change.
