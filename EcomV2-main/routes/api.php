<?php

use App\Http\Controllers\Api\V1\AddressController;
use App\Http\Controllers\Api\V1\AdminReportController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\CartController;
use App\Http\Controllers\Api\V1\CatalogController;
use App\Http\Controllers\Api\V1\CodRemittanceController;
use App\Http\Controllers\Api\V1\ConversationController;
use App\Http\Controllers\Api\V1\OrderController;
use App\Http\Controllers\Api\V1\ReturnRequestController;
use App\Http\Controllers\Api\V1\RiderAssignmentController;
use App\Http\Controllers\Api\V1\VoucherController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->middleware('throttle:api')->group(function () {

    // ── Public ────────────────────────────────────────────
    Route::get('/categories', [CatalogController::class, 'categories']);
    Route::get('/products', [CatalogController::class, 'products']);
    Route::get('/products/{slug}', [CatalogController::class, 'product']);

    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login', [AuthController::class, 'login']);

    // ── Authenticated ─────────────────────────────────────
    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/me', [AuthController::class, 'me']);
        Route::post('/logout', [AuthController::class, 'logout']);
        Route::put('/profile', [AuthController::class, 'updateProfile']);
        Route::put('/password', [AuthController::class, 'changePassword']);

        // Messaging (all authenticated roles)
        Route::get('/conversations', [ConversationController::class, 'index']);
        Route::post('/conversations', [ConversationController::class, 'start'])->middleware('throttle:20,1');
        Route::get('/conversations/{id}/messages', [ConversationController::class, 'messages']);
        Route::post('/conversations/{id}/messages', [ConversationController::class, 'send'])->middleware('throttle:60,1');

        // ── Buyer ─────────────────────────────────────────
        Route::middleware(['role:buyer', 'approved'])->group(function () {
            // Cart
            Route::get('/cart', [CartController::class, 'show']);
            Route::post('/cart', [CartController::class, 'add']);
            Route::put('/cart/{item}', [CartController::class, 'update']);
            Route::delete('/cart/{item}', [CartController::class, 'remove']);

            // Voucher validation
            Route::post('/vouchers/validate', [VoucherController::class, 'validate']);

            // Orders
            Route::post('/orders', [OrderController::class, 'checkout']);
            Route::post('/orders/{orderNumber}/confirm', [OrderController::class, 'confirmReceived']);
            Route::post('/orders/{orderNumber}/rate', [OrderController::class, 'rate']);
            Route::post('/orders/{orderNumber}/cancel', [OrderController::class, 'cancel']);

            // Returns
            Route::get('/returns', [ReturnRequestController::class, 'index']);
            Route::post('/returns', [ReturnRequestController::class, 'store']);

            // Addresses
            Route::get('/addresses', [AddressController::class, 'index']);
            Route::post('/addresses', [AddressController::class, 'store']);
            Route::put('/addresses/{id}', [AddressController::class, 'update']);
            Route::delete('/addresses/{id}', [AddressController::class, 'destroy']);
        });

        // Orders readable by all approved roles
        Route::middleware(['approved'])->group(function () {
            Route::get('/orders', [OrderController::class, 'index']);
            Route::get('/orders/{orderNumber}', [OrderController::class, 'show']);
        });

        // ── Seller ────────────────────────────────────────
        Route::middleware(['role:seller', 'approved'])->prefix('seller')->group(function () {
            Route::get('/vouchers', [VoucherController::class, 'index']);
            Route::post('/vouchers', [VoucherController::class, 'store'])->middleware('throttle:20,1');
            Route::patch('/vouchers/{voucher}/toggle', [VoucherController::class, 'toggle']);
            Route::delete('/vouchers/{voucher}', [VoucherController::class, 'destroy']);
            Route::get('/returns', [ReturnRequestController::class, 'index']);
        });

        // ── Rider ─────────────────────────────────────────
        Route::middleware(['role:courier', 'approved'])->prefix('rider')->group(function () {
            Route::get('/assignments', [RiderAssignmentController::class, 'index']);
            Route::post('/assignments/{assignmentKey}/{action}', [RiderAssignmentController::class, 'action'])
                ->where('assignmentKey', '(pickup|delivery)-[0-9]+')
                ->where('action', 'accept|scan|out-for-delivery|deliver|fail')
                ->middleware('throttle:30,1');
            // COD remittance
            Route::get('/remittances/pending', [CodRemittanceController::class, 'pending']);
            Route::post('/remittances', [CodRemittanceController::class, 'store'])->middleware('throttle:10,1');
        });

        // ── Logistics / Admin ─────────────────────────────
        Route::middleware(['role:logistics|admin|super-admin', 'approved'])->group(function () {
            Route::get('/remittances', [CodRemittanceController::class, 'index']);
            Route::post('/remittances/{remittance}/confirm', [CodRemittanceController::class, 'confirm'])->middleware('throttle:30,1');
        });

        // ── Admin ─────────────────────────────────────────
        Route::middleware(['role:admin|super-admin', 'approved'])->prefix('admin')->group(function () {
            Route::get('/reports', [AdminReportController::class, 'index']);
            Route::get('/returns', [ReturnRequestController::class, 'index']);
            Route::post('/returns/{returnRequest}/decide', [ReturnRequestController::class, 'decide'])->middleware('throttle:30,1');
        });
    });
});
