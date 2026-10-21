# What changed in this pass

This is a walkthrough of the marketplace rules that were locked in, then implemented. It is meant to be read instead of hunting through diffs.

## The rules, in plain language

1. **A product is for sale only if that SKU has at least 10 units in stock.** Below that, it stays in the seller catalog but disappears from the shop, home, store pages, and API catalog.
2. **A shopper can put at most 10 units of the same product in the cart.** Trying to go past 10 asks for confirmation, then caps at 10. The server rejects anything above that.
3. **Shipping is ₱50 flat**, charged on each seller order. It is not free, not worldwide, and not mixed into merchandise.
4. **Logistics keeps 20% of the merchandise subtotal.** Shipping is separate and also goes to logistics. Seller payout is `subtotal − 20%`, not `order total − commission`.
5. **Cash on Delivery is the only payment method.**
6. **Shopper sign-up is labeled Sign up**, not Register. Staff-facing roles stay Seller, Logistics, Admin, and Superadmin. Buyers stay on the web storefront.
7. **Prices and copy are PHP / ₱.** Fake 10% first-order bars, coupon teasers, and “free shipping” chips were removed.

## How checkout money now works

Example: two items at ₱6 each.

- Merchandise subtotal: ₱12.00
- Shipping: ₱50.00
- Buyer pays (COD): ₱62.00
- Logistics commission: 20% of ₱12.00 = ₱2.40
- Seller estimated payout: ₱9.60
- Logistics also collects the ₱50 shipping fee when the rider remits COD

The commission row in the database is still tied to the seller (who is charged) with `rate = 20` and `amount` based on **subtotal only**. Config lives in `config/jeap.php`:

- `commission_rate` = 20
- `commission_recipient` = logistics
- `shipping_fee` = 50
- `min_sellable_stock` = 10
- `max_qty_per_product` = 10

`App\Commerce\InventoryPolicy` is the single place PHP uses for those numbers. `CommissionService` reads the rate from config instead of a hardcoded 10%.

## Cart and listing behavior

- Adding or updating cart items checks sellable stock and the 10-unit cap (web and `/api/v1/cart`).
- Checkout (web and API) refuses the order if stock dropped below 10 or quantity is over 10.
- Catalog queries use `Product::listed()` / `ProductVariant::sellable()`.
- Sellers may save a **draft** with any stock. Publishing as **active** requires stock ≥ 10.
- Seller dashboard “below sellable stock” counts active SKUs under 10, not “5 or fewer.”

## Sign-up, Google, and profile photo

- Buyer sign-up now collects a Philippine delivery address through the same PSA/PSGC location picker used on checkout.
- Google sign-in still uses Socialite. **New Google shoppers are created as active buyers and signed in**, because Google already verified the email. Existing staff accounts that are pending stay pending.
- Users have an `avatar_path` column. Profile can upload a photo (JPG/PNG/WebP, 5 MB). Google sign-in stores the Google photo when the download works.
- Run the new migration: `php artisan migrate` (`2026_10_20_000001_add_avatar_path_to_users_table`).

Google still needs real `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` in `.env`. The button is on login and sign-up either way; a missing secret shows a clear error instead of a white screen.

## Categories

`CatalogSeeder` now seeds Shopee-style **parent** categories (apparel, mobiles, computers, home, groceries, pets, automotive, and so on). The old electronics names (Mobiles, Kitchen, Gaming, …) remain as **children** so demo products and old URLs still work.

The header and home “Popular Categories” show parents only. Opening a parent (for example Mobile & Gadgets) also lists products in its children.

Re-seed if you want the new tree on an existing database:

```bash
php artisan db:seed --class=Database\\Seeders\\CatalogSeeder
```

That updates categories and demo products. It does not wipe orders.

## Logistics and admin screens

- Shipments are **grouped by destination city/region**, with a destination filter.
- Each shipment shows the address and the logistics cut for that order.
- Admin overview and reports show accrued logistics commission (20% of merchandise).
- Dashboard chrome uses the JEAP logo instead of leftover Figma frame names.

## Copy that was cleaned up

Removed or rewritten because it did not match the live product:

- “Get 10% DISCOUNT for first order”
- “Register Now” (now Sign up)
- “Worldwide Standard Shipping Free”
- “Have a coupon?” on checkout
- Hardcoded `JEAP10` 10% voucher on API checkout
- Fake home countdown and generic gadget banners
- Footer “free shipping over ₱99 / ₱199”
- Seller “Commission (10%)” (now logistics 20%, payout from subtotal)

## Files worth reading first

| Area | Where |
| --- | --- |
| Rules | `config/jeap.php`, `app/Commerce/InventoryPolicy.php`, `app/Commerce/CommissionService.php` |
| Cart / checkout | `app/Http/Controllers/Storefront/CartController.php`, `PageController.php` |
| API | `app/Http/Controllers/Api/V1/CartController.php`, `OrderController.php` |
| Listing | `app/Models/Product.php` (`scopeListed`), `ProductVariant.php` (`scopeSellable`) |
| Seller stock | `app/Http/Controllers/Seller/DashboardController.php` |
| Sign-up address | `app/Http/Controllers/Auth/RegisterController.php`, `resources/views/auth/register.blade.php` |
| Google | `app/Http/Controllers/Auth/GoogleAuthController.php` |
| Categories | `database/seeders/CatalogSeeder.php` |
| Logistics board | `app/Http/Controllers/Logistics/ShipmentController.php`, `resources/views/logistics/dashboard.blade.php` |

## What this did not change

- Flutter / `jeap_mobile` mock catalog
- Importing `schema-export` SQL (do not import that dump)
- Real Google OAuth credentials (still your `.env`)
- Git commit / push (not done unless you ask)
- Other payment gateways (still COD only)

## After pulling this onto a machine

1. `php artisan migrate` (already run on this machine for `avatar_path`)
2. Optionally re-run `CatalogSeeder` for the category tree
3. `php artisan storage:link` if avatars 404
4. `npm run dev` or `npm run build` so the cart quantity cap and CSS pick up
5. Put Google OAuth secrets in `.env` when you are ready for live Google login
