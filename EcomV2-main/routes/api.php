<?php

use App\Http\Controllers\Api\V1\AddressController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\CartController;
use App\Http\Controllers\Api\V1\CatalogController;
use App\Http\Controllers\Api\V1\OrderController;
use App\Http\Controllers\Api\V1\RiderAssignmentController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->middleware('throttle:api')->group(function () {

    // ── Public ────────────────────────────────────────────
    Route::get('/categories', [CatalogController::class, 'categories']);
    Route::get('/products', [CatalogController::class, 'products']);

    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login', [AuthController::class, 'login']);

    // ── Authenticated ─────────────────────────────────────
    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/me', [AuthController::class, 'me']);
        Route::post('/logout', [AuthController::class, 'logout']);
        Route::put('/profile', [AuthController::class, 'updateProfile']);
        Route::post('/profile/avatar', [AuthController::class, 'updateAvatar']);
        Route::put('/password', [AuthController::class, 'changePassword']);

        // Buyer only
        Route::middleware(['role:buyer', 'approved'])->group(function () {
            // Cart
            Route::get('/cart', [CartController::class, 'show']);
            Route::post('/cart', [CartController::class, 'add']);
            Route::put('/cart/{item}', [CartController::class, 'update']);
            Route::delete('/cart/{item}', [CartController::class, 'remove']);

            // Orders
            Route::post('/orders', [OrderController::class, 'checkout']);
            Route::post('/orders/{orderNumber}/confirm', [OrderController::class, 'confirmReceived']);
            Route::post('/orders/{orderNumber}/rate', [OrderController::class, 'rate']);

            // Addresses
            Route::get('/addresses', [AddressController::class, 'index']);
            Route::post('/addresses', [AddressController::class, 'store']);
            Route::put('/addresses/{id}', [AddressController::class, 'update']);
            Route::delete('/addresses/{id}', [AddressController::class, 'destroy']);
        });

        // Approved accounts can read order history regardless of role.
        Route::middleware(['approved'])->group(function () {
            Route::get('/orders', [OrderController::class, 'index']);
            Route::get('/orders/{orderNumber}', [OrderController::class, 'show']);
        });

        Route::middleware(['role:courier', 'approved'])->prefix('rider')->group(function () {
            Route::get('/assignments', [RiderAssignmentController::class, 'index']);
            Route::post('/assignments/{assignmentKey}/{action}', [RiderAssignmentController::class, 'action'])
                ->where('assignmentKey', '(pickup|delivery)-[0-9]+')
                ->where('action', 'accept|scan|out-for-delivery|deliver|fail')
                ->middleware('throttle:30,1');
        });
    });
});
