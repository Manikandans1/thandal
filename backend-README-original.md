# Thandal

Chit collection and repayment system. One Flutter app for Customer, Agent and Admin;
a Laravel API + Super Admin web panel; MySQL; Razorpay.

**Read `docs/03-what-was-tested.md` first** — it says exactly what was run for real
versus written-and-linted-only, and what to check first.

```
thandal/
  docs/
    01-functional-spec.md      every business rule + decision log + 31-item test checklist
    02-database-design.md      tables, relationships, indexes, ER diagram
    03-what-was-tested.md      what actually ran vs what to verify yourself
    04-setup-guide.md          step-by-step: backend, Docker, mobile
    er-diagram.mmd             ER diagram source (Mermaid)
  backend/                     Laravel 11 API + Livewire admin web
    app/Models/                17 Eloquent models
    app/Services/              the money engine (schedules, allocation, corrections, ...)
    app/Http/Controllers/Api/  the mobile API
    app/Livewire/Admin/        the Super Admin web panel
    app/Console/Commands/      thandal:create-super-admin, thandal:reconcile-payments
    database/schema.sql        full MySQL schema (DB-tested, 21/21 rule checks pass)
    database/migrations/       the same schema as 19 Laravel migrations
    database/schema-generator/ the single source of truth both are generated from
    database/tests/            runnable verification scripts (see below)
    resources/views/           Blade views using the approved design tokens
    tests/Feature/             17 PHPUnit tests covering the acceptance checklist
  mobile/                      Flutter app (Customer + Agent + Admin, one login)
    lib/core/                  theme (locked palette), API client, router
    lib/models/ lib/services/ lib/providers/
    lib/features/auth|customer|agent|admin/
    lib/widgets/               PillBadge, HeroBalanceCard, AllChitsSummaryCard, TallyGrid
```

## What's real and verified right now, without installing anything

```bash
# Database: loads real MySQL/MariaDB and enforces 21 money-safety rules
bash backend/database/tests/verify_schema.sh

# Money arithmetic: schedule dates (incl. the day-31 monthly clamp), oldest-first
# allocation, partial payments, correction reversals — pure PHP, no framework
php backend/database/tests/verify_money_math.php
```

Both currently print **21/21 passed**. Every PHP file in the backend (91 files)
passes `php -l`. See `docs/03-what-was-tested.md` for what still needs `composer
install` / `flutter pub get` to confirm.

## Development order followed

1. Functional spec + decision log
2. Database: schema + migrations
3. API design (routes, requests, resources)
4. Login, roles, admin self-registration + approval
5. Money engine: schedules, allocation, ledger, corrections, agent transfers
6. Razorpay (test mode, server-side verification, webhook idempotency)
7. Admin backend + Livewire web panel
8. Flutter app: theme + router + login, then Customer, Agent, Admin screens
9. Tests, security notes, Docker deployment

## Quick start

See `docs/04-setup-guide.md`. Short version:

```bash
cd backend && cp .env.example .env && composer install && php artisan key:generate
php artisan migrate && php artisan db:seed
php artisan thandal:create-super-admin "Your Name" 9000000000
php artisan serve
```
