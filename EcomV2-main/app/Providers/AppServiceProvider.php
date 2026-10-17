<?php

namespace App\Providers;

use App\Models\Cart;
use App\Models\Category;
use App\Payments\CodGateway;
use App\Payments\PaymentGateway;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Facades\URL;
use Illuminate\Support\Facades\View;
use Illuminate\Support\ServiceProvider;
use Illuminate\Validation\Rules\Password;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(PaymentGateway::class, CodGateway::class);
    }

    public function boot(): void
    {
        if (! $this->app->runningInConsole() && str_starts_with((string) config('app.url'), 'https://')) {
            URL::forceScheme('https');
        }

        Password::defaults(fn () => Password::min(8)->max(72)->letters()->mixedCase()->numbers());

        RateLimiter::for('login', function (Request $request) {
            $email = strtolower((string) $request->input('email'));

            return Limit::perMinute(5)->by($email.'|'.$request->ip());
        });

        RateLimiter::for('register', function (Request $request) {
            return [
                Limit::perMinute(5)->by($request->ip()),
                Limit::perHour(20)->by($request->ip()),
            ];
        });

        RateLimiter::for('api', function (Request $request) {
            return Limit::perMinute(60)->by((string) ($request->user()?->id ?: $request->ip()));
        });

        View::composer(['layouts.storefront', 'layouts.storefront-inner'], function ($view) {
            $view->with('navCategories', Category::query()->where('is_active', true)->orderBy('sort_order')->get());

            $cart = null;
            if (Auth::check()) {
                $cart = Cart::query()->where('user_id', Auth::id())->with('items')->first();
            } elseif (session()->isStarted()) {
                $cart = Cart::query()->where('session_id', session()->getId())->with('items')->first();
            }

            $items = $cart?->items ?? collect();
            $view->with('cartCount', $items->sum('quantity'));
            $view->with('cartTotal', $items->sum(fn ($i) => $i->unit_price * $i->quantity));
        });
    }
}
