# Thandal – What Was Actually Tested

Being exact about this matters more than sounding finished. Here is precisely what
ran, what only lints, and what to check first when you run it yourself.

## Environment used to build this

This code was written in a sandbox with PHP 8.3 and a real MySQL/MariaDB server, but
**no internet access to Packagist, Composer, or the Flutter/Dart SDK download**. That
means:

- ✅ **Raw PHP and the database itself could be executed.**
- 🚫 **Laravel's own tooling (`composer install`, `php artisan migrate`, `php artisan test`) could not run**, because Laravel's dependencies live on Packagist and that host isn't reachable here.
- 🚫 **Flutter/Dart could not run at all** — no `flutter`, no `dart`, nothing to install them with.

Everything below follows from that.

## ✅ Actually executed and passing

| What | How | Result |
|---|---|---|
| The full MySQL schema (`schema.sql`) | Loaded into a real MariaDB 10.11 server | Created all 19 tables with no errors |
| 21 database safety rules | Real INSERT/UPDATE/DELETE statements run against that database (`database/tests/verify_schema.sh`) | **21 / 21 passed** — duplicate mobiles, wrong chit totals, over-paid installments, duplicate receipts/Razorpay ids/webhooks, double-submits, two current agents, blocked deletes, etc. |
| The money arithmetic itself (schedule dates, allocation order, reversal order) | A standalone PHP script with no framework (`database/tests/verify_money_math.php`), re-implementing the exact logic in `ScheduleService` and `AllocationService` | **21 / 21 passed** — including the day-31 monthly clamp (Jan 31 → Feb 28 → Mar 31, not chained), oldest-first partial allocation, and reversing the most recent allocation first on a correction |
| Every PHP file in the backend (91 files: models, services, controllers, requests, resources, middleware, policies, Livewire components, config, migrations) | `php -l` (syntax check) on each file | **All pass** — no syntax errors |
| `composer.json` | Parsed as JSON | Valid |

## 🚫 Written but not executed — run these yourself first

| What | Why it couldn't run here | What to do |
|---|---|---|
| `composer install` | Packagist unreachable from this sandbox | Run it once on your machine or CI. If any package version conflicts, tell me the error and I'll fix `composer.json`. |
| `php artisan migrate` | Needs Composer's autoloader and the real Laravel kernel, not just PHP | Run it after `composer install`. The generated migrations mirror `schema.sql` exactly (same generator), which *did* run successfully — but Laravel's own migration runner hasn't confirmed it. |
| The 17 PHPUnit feature tests (`tests/Feature/*.php`) | Needs Laravel's test kernel (`RefreshDatabase`, `app()`, factories) | Run `php artisan test` after migrating a `thandal_test` database. They cover the acceptance checklist items 1–10, 16–18, 28–30 in the functional spec. If one fails, send me the output — the logic they test is the same logic the standalone math script already verified, so a failure would most likely be a wiring issue (a binding, a route, a factory default), not the underlying money math. |
| The Livewire admin web pages and Blade views | Needs a running Laravel app + browser | Visual review once `composer install` + `php artisan serve` are done. The CSS is the exact `tokens.css` / `admin.css` from the approved prototype, so it should look right immediately. |
| The Razorpay integration | Needs real (test-mode) Razorpay keys, which weren't provided | Add `RAZORPAY_KEY` / `RAZORPAY_SECRET` / `RAZORPAY_WEBHOOK_SECRET` to `.env`, then test a payment end to end in Razorpay's test mode. |
| The entire Flutter app | No Flutter/Dart SDK available in this sandbox at all | Run `flutter pub get && flutter analyze` first. See `mobile/README.md` for exactly what's fully wired to the API versus scaffolded. |

## If something doesn't run

Send me the exact error text. Almost everything here was generated from a small
number of source-of-truth files (`database/schema_dsl.py` is not shipped, but the
migrations and `schema.sql` were both generated together and cross-checked), so a
mismatch is usually a one-line fix, not a redesign.
