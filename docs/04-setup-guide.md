# Thandal – Setup Guide

## 1. Backend (Laravel API + Super Admin web)

```bash
cd backend
cp .env.example .env
composer install
php artisan key:generate
```

Edit `.env`: set `DB_*` to your MySQL, and `RAZORPAY_*` to your test-mode keys once you have them.

```bash
php artisan migrate
php artisan db:seed                 # optional: demo data matching the approved prototypes
php artisan thandal:create-super-admin "Your Name" 9000000000
php artisan storage:link
php artisan serve                   # http://127.0.0.1:8000
```

Log in to the web panel at `/login` with the mobile number and temporary PIN the
`create-super-admin` command printed. The app will ask you to set your own PIN.

### Run the tests

```bash
# Database rules (needs a MySQL/MariaDB server; no Laravel required)
bash database/tests/verify_schema.sh

# Money arithmetic (pure PHP, no server required)
php database/tests/verify_money_math.php

# Full Laravel test suite (after composer install + a thandal_test database)
php artisan test
```

### Background jobs

Two things need to run continuously, or on a schedule:

```bash
php artisan queue:work              # sends emails/notifications if you add any later
php artisan schedule:work           # runs thandal:reconcile-payments every 5 minutes
```

The `docker-compose.yml` already runs both as separate services — see below.

### Razorpay webhook

Point your Razorpay webhook at `https://your-domain/api/webhooks/razorpay` and set
the same secret in `.env` as `RAZORPAY_WEBHOOK_SECRET`. Subscribe to
`payment.captured` and `payment.failed`.

## 2. Deploy with Docker

```bash
cd backend
docker compose up -d --build
docker compose exec app php artisan migrate --force
docker compose exec app php artisan thandal:create-super-admin "Your Name" 9000000000
```

The web panel is then at `http://localhost:8080`. Put a real domain + HTTPS in front
of it in production (e.g. Caddy or an nginx reverse proxy with Let's Encrypt) — the
`nginx` service here is for the app itself, not for TLS termination.

### Backups

Add a daily cron/systemd timer on the host:

```bash
docker compose exec -T db mysqldump -u root -prootsecret thandal | gzip > /backups/thandal-$(date +%F).sql.gz
```

Keep at least 14 days of backups. Money data is never deleted by the application, so
a backup restore is also your audit-of-last-resort if something is ever in doubt.

## 3. Mobile app (Flutter)

```bash
cd mobile
flutter pub get
flutter analyze                     # do this first — see mobile/README.md
flutter run --dart-define=THANDAL_API_BASE_URL=https://your-domain/api
```

Build for release:

```bash
flutter build apk --release --dart-define=THANDAL_API_BASE_URL=https://your-domain/api
flutter build ios --release --dart-define=THANDAL_API_BASE_URL=https://your-domain/api
```

Razorpay Checkout needs no extra mobile-side configuration — the key id comes from
the server's `/chits/{id}/pay/start` response.

## 4. First things to check after setup

1. Log in to the web panel as the Super Admin, register a second admin from the login
   page, then approve it from **Admin users** — confirms the whole approval flow.
2. Create a customer with an ID proof photo, then a chit for them (try Daily, Weekly
   and Monthly) — confirms the Total to pay preview and the generated schedule.
3. Record a disbursement — the chit should flip to Active.
4. In the Flutter app, log in as that customer and make an online test payment; log
   in as an agent and collect cash from a different customer.
5. Request a correction as the agent, approve it as the admin, and check the audit
   log recorded every step.

If anything above doesn't behave as described, it's a bug — the logic was verified
standalone (see `docs/03-what-was-tested.md`) but the full wiring through Laravel and
Flutter was not run in the environment this was built in.
