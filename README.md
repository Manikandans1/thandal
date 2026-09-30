# Thandal — backend + mobile app, integrated

This package contains:

- **`backend/`** — the Laravel API (unchanged in every way except the fixes and additions
  listed below, all needed to serve the mobile app).
- **`mobile_app/`** — the single Flutter app (customer + agent + admin) from the previous
  step, now wired to call this backend for everything: login, chit data, payments,
  corrections, customer/agent management, dashboards.
- **`docs/`** — the original functional spec and setup guides, unchanged.

## 1. Run the backend

```
cd backend
cp .env.example .env      # or edit the existing .env — see note below
php artisan key:generate  # only if you made a fresh .env
composer install          # only needed if vendor/ isn't already there
php artisan migrate --seed
php artisan serve --host=0.0.0.0 --port=8000
```

The included `.env` already has local MySQL settings and **test-mode Razorpay keys**.
Before using this anywhere but your own machine, change `DB_PASSWORD`, generate a new
`APP_KEY`, and put in your own Razorpay keys.

`php artisan serve --host=0.0.0.0` (not `127.0.0.1`) so a phone on the same Wi-Fi, or an
Android emulator, can reach it.

### Verifying the backend on its own

```
cd backend
php vendor/bin/phpunit --testsuite Feature
```

All 26 tests should pass (18 original + 8 covering the mobile API: role scoping, the
agent/customer/admin feeds, PIN reset, activate/deactivate, double-submit protection).

## 2. Point the app at the backend

The app reads the API address from one build-time value, so nothing in the code needs to
change:

```
flutter run --dart-define=THANDAL_API_BASE_URL=http://YOUR_BACKEND:8000/api
```

Without that flag it defaults to `http://10.0.2.2:8000/api`, which is the special address
an **Android emulator** uses to reach `localhost` on your computer.

| Where you're running the app | `THANDAL_API_BASE_URL` |
|---|---|
| Android emulator | `http://10.0.2.2:8000/api` (default, no flag needed) |
| iOS simulator | `http://127.0.0.1:8000/api` |
| A real phone (same Wi-Fi as your computer) | `http://YOUR_COMPUTER_LAN_IP:8000/api` |
| A deployed backend | `https://your-domain.com/api` |

```
cd mobile_app
flutter pub get
flutter run --dart-define=THANDAL_API_BASE_URL=http://192.168.1.20:8000/api
```

To bake the address in for a release build (so nobody needs to pass the flag):

```
flutter build apk --dart-define=THANDAL_API_BASE_URL=https://your-domain.com/api
```

## 3. Log in

There's still one login screen for all three apps — the server decides which app opens,
based on the account's role. Use whatever customers/agents/admins exist in your database
(the seeder creates a few — see `backend/database/seeders/DatabaseSeeder.php`), or create
new ones from the admin app once you're signed in as an admin.

If a login says "waiting for approval" or "not approved", that account is an admin
registration still pending a Super Admin's approval (see the functional spec, section 3).

## What changed to connect the two

**Mobile app** — every screen that used to read fake, hard-coded data now calls the
backend instead:

- The shared login screen calls `POST /auth/login`; the account's role (sent by the
  server) decides whether the customer, agent, or admin app opens.
- Customer: chits, schedules and payment history load from the server; online payment
  opens a real Razorpay Checkout backed by a server-created order, and the payment is
  only ever confirmed after the server re-verifies it with Razorpay.
- Agent: dashboard numbers, customer portfolio, cash collection, new customer/chit
  creation (with a real camera/gallery photo for the ID proof), and correction requests
  are all real server calls. Cash collection sends a unique request id so a double tap or
  a dropped connection can never charge twice.
- Admin: dashboard, agent/customer/chit/payment/correction/audit-log lists, creating
  agents and customers, recording disbursements, cancelling chits, transferring
  customers, resetting PINs, activating/deactivating accounts, and
  approving/rejecting corrections are all real server calls.
- PIN reset flow (admin resets a PIN → temporary PIN shown once → person sets their own
  PIN before the app lets them in) is fully wired end to end.
- Logging out revokes the token on the server; if the server ever rejects a saved token
  (expired, revoked, reset elsewhere), the app returns to the login screen automatically.

**Backend** — small, additive changes only; nothing already working was changed:

- Fixed a data-scoping bug: an agent's customer search could return another agent's
  customers because of an unparenthesised `OR` in the query.
- Added the list endpoints the app needs that didn't exist yet: an agent's full customer
  portfolio (with schedules) in one call, payment history for each role, the admin's
  full chit list, and the audit log feed.
- Added PIN reset (`POST /admin/agents/{id}/reset-pin`, `.../customers/{id}/reset-pin`)
  and activate/deactivate (`POST .../agents/{id}/active`, `.../customers/{id}/active`) —
  both described in the functional spec but not yet implemented.
- Extended a few JSON responses with fields the app needs for its receipts and lists
  (a payment's per-installment allocations, a chit's customer/agent/disbursement info),
  without removing or renaming anything already there.
- Fixed the dashboard's "expected today" figure to match the functional spec's
  definition (pending installments + what's already been collected toward due
  installments), and added the cash/online split, pending-online-payment count and
  pending-disbursement count the admin home screen shows.
- Fixed a test-factory bug (`customers.created_by` wasn't set by the factory, which made
  `php artisan db:seed` fail against a fresh database in this project).

Everything else in the backend — every route, every rule, every calculation not listed
above — is exactly as it was given to me.
