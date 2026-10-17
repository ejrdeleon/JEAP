# JEAP

Philippine multi-vendor marketplace with in-house logistics. Laravel 12, Sanctum, Spatie roles, Blade storefront.

Do not commit `.env`, API keys, or personal seed data. Copy `.env.example` to `.env` locally.

## Run locally

1. PHP 8.2+ (8.3+ recommended), Composer, Node, MySQL 8 / MariaDB.
2. Copy `.env.example` to `.env` and set `DB_*`.
3. Install and migrate:

```
composer install
php artisan key:generate
php artisan migrate --seed
php artisan storage:link
npm install
npm run build
php artisan serve --port=8080
```

Open http://127.0.0.1:8080

After `php artisan migrate --seed`, the demo accounts use `SEED_USER_PASSWORD` from your local `.env` (the seeder's default is only for local development). Rerunning the seeders resets these accounts to that password. Do not use demo accounts or passwords on a public domain.

| Role | Demo login | Dashboard |
| --- | --- | --- |
| Buyer | `buyer@jeap.test` | `/buyer` |
| Seller | `seller@jeap.test` | `/seller` |
| Rider (courier) | `rider@jeap.test` | `/courier` |
| Logistics | `hub@jeap.test` | `/logistics` |
| Admin | `admin@jeap.test` | `/admin` |

Pending users cannot log in. Couriers are approved by logistics; everyone else by admin.

## Google Maps delivery locations

Set `GOOGLE_MAPS_BROWSER_KEY` in your local `.env`. Apply the address-coordinate migration with `php artisan migrate`. Without a key, checkout and saved-address forms remain usable for manual address entry; map selection and address suggestions are disabled.

In Google Cloud, enable billing and the **Maps JavaScript API** for the project. To enable address suggestions, also enable **Places API (New)**. Restrict the key as a website/referrer key, and restrict its API access to only the Maps JavaScript API and Places API (New). Suggested HTTP referrers:

- Local: `http://localhost:8080/*`, `http://127.0.0.1:8080/*` (also add port `8000` if using Laravel's default port).
- Production: `https://jeap.store/*` and `https://www.jeap.store/*` if both hostnames serve the app.

The browser key is necessarily visible to browsers; keep it restricted to the application referrers and required APIs. Places autocomplete requests are made only when a visitor uses address search. The map pin can be selected or moved without granting browser location permission; geolocation is an optional user action.

## Philippine address locations

Checkout and saved delivery addresses provide cascading country, region, province, city/municipality, barangay, and available postal-code choices. The country list and postal-code suggestions are loaded server-side and cached. PSGC codes and location names are saved to the address and copied into the order snapshot. Postal codes are optional; where a locality has no postal-code suggestion, the form allows manual entry.

The location service uses the official PSA [Philippine Standard Geographic Code (PSGC) API](https://psa.gov.ph/classifications-api/psgc) when a token is configured. Request a PSA API token and add it to the local `.env`:

```dotenv
PSGC_API_TOKEN=your-psa-psgc-api-token
PSGC_API_VERSION=Q2_2026
```

Use a PSGC version available to your token if the current version differs. Do not put the PSA token in frontend code or share it publicly. When the token is absent, the app uses the public [PSGC GitLab API mirror](https://psgc.gitlab.io/api/) so the dropdowns still load without requiring additional configuration. If the location services are unavailable, forms allow manual entry. ZIP/postal code suggestions are queried from PSGC Cloud; treat them as suggestions and manually enter the code if your locality's code is not listed.

## Admin roles

The seeded demo account `admin@jeap.test` has the `admin` role. After updating an existing installation, seed the new role with `php artisan db:seed --class=RoleSeeder`. Then grant a trusted account super-admin access from `php artisan tinker`:

```
$user = App\Models\User::where('email', 'trusted@example.com')->firstOrFail();
$user->assignRole('super-admin');
```

Super admins can create and deactivate administrator accounts and edit platform policies. Admins manage marketplace registrations, users, announcements, disputes, and reports. Keep super-admin access limited to trusted operators.

## Queues

Redis is preferred. This machine uses `QUEUE_CONNECTION=database` because Redis/phpredis is not installed. Switch later with `QUEUE_CONNECTION=redis`.

## Payments

Only `CodGateway` is implemented. Other providers must be extra `PaymentGateway` classes.

## Flutter

Not started. Reuse `/api/v1`.
