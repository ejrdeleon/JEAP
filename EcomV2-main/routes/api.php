<?php

use App\Http\Controllers\Api\V1\AddressController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\CartController;
use App\Http\Controllers\Api\V1\CatalogController;
use App\Http\Controllers\Api\V1\CodRemittanceController;
use App\Http\Controllers\Api\V1\ConversationController;
use App\Http\Controllers\Api\V1\LocationController;
use App\Http\Controllers\Api\V1\LogisticsController;
use App\Http\Controllers\Api\V1\NotificationController;
use App\Http\Controllers\Api\V1\OrderController;
use App\Http\Controllers\Api\V1\ReturnRequestController;
use App\Http\Controllers\Api\V1\RiderAssignmentController;
use App\Http\Controllers\Api\V1\RiderProfileController;
use App\Http\Controllers\Api\V1\VoucherController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->middleware('throttle:api')->group(function () {

    // ── Public ────────────────────────────────────────────
    Route::get('/categories', [CatalogController::class, 'categories']);
    Route::get('/products', [CatalogController::class, 'products']);
    Route::get('/products/{id}', [CatalogController::class, 'show'])->whereNumber('id');

    // Locations (PSGC)
    Route::get('/locations/regions', [LocationController::class, 'regions']);
    Route::get('/locations/regions/{regionCode}/provinces', [LocationController::class, 'provinces']);
    Route::get('/locations/regions/{regionCode}/cities', [LocationController::class, 'regionCities']);
    Route::get('/locations/regions/{regionCode}/cities-municipalities', [LocationController::class, 'regionCities']);
    Route::get('/locations/provinces/{provinceCode}/cities', [LocationController::class, 'provinceCities']);
    Route::get('/locations/provinces/{provinceCode}/cities-municipalities', [LocationController::class, 'provinceCities']);
    Route::get('/locations/cities/{localityCode}/barangays', [LocationController::class, 'barangays']);
    Route::get('/locations/cities-municipalities/{localityCode}/barangays', [LocationController::class, 'barangays']);
    Route::get('/locations/cities/{localityCode}/postal-code', [LocationController::class, 'postalCode']);
    Route::get('/locations/cities-municipalities/{localityCode}/postal-code', [LocationController::class, 'postalCode']);
    Route::get('/locations/search', [LocationController::class, 'search']);

    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login', [AuthController::class, 'login']);
    Route::post('/email/verify', [AuthController::class, 'verifyEmail']);
    Route::post('/email/resend', [AuthController::class, 'resendEmailVerification']);
    Route::post('/forgot-password', [AuthController::class, 'forgotPassword'])->middleware('throttle:6,1');
    Route::post('/reset-password', [AuthController::class, 'resetPassword'])->middleware('throttle:10,1');
    Route::post('/auth/forgot-password', [AuthController::class, 'forgotPassword'])->middleware('throttle:6,1');
    Route::post('/auth/reset-password', [AuthController::class, 'resetPassword'])->middleware('throttle:10,1');

    // ── Authenticated ─────────────────────────────────────
    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/me', [AuthController::class, 'me']);
        Route::post('/logout', [AuthController::class, 'logout']);
        Route::put('/profile', [AuthController::class, 'updateProfile']);
        Route::post('/profile/avatar', [AuthController::class, 'updateAvatar']);
        Route::put('/password', [AuthController::class, 'changePassword']);

        // Notifications
        Route::get('/notifications', [NotificationController::class, 'index']);
        Route::post('/notifications/read-all', [NotificationController::class, 'markAllAsRead']);
        Route::post('/notifications/{id}/read', [NotificationController::class, 'markAsRead']);

        // Vouchers
        Route::post('/vouchers/validate', [VoucherController::class, 'validate']);
        Route::get('/vouchers', [VoucherController::class, 'index']);

        // Conversations / In-app Chat
        Route::get('/conversations', [ConversationController::class, 'index']);
        Route::post('/conversations/start', [ConversationController::class, 'start']);
        Route::get('/conversations/{conversationId}/messages', [ConversationController::class, 'messages'])->whereNumber('conversationId');
        Route::post('/conversations/{conversationId}/messages', [ConversationController::class, 'send'])->whereNumber('conversationId');

        // Returns & Refunds
        Route::get('/returns', [ReturnRequestController::class, 'index']);
        Route::post('/returns', [ReturnRequestController::class, 'store']);

        // Buyer only
        Route::middleware(['role:buyer', 'approved'])->group(function () {
            // Cart
            Route::get('/cart', [CartController::class, 'show']);
            Route::post('/cart', [CartController::class, 'add']);
            Route::put('/cart/{item}', [CartController::class, 'update']);
            Route::delete('/cart/{item}', [CartController::class, 'remove']);

            // Orders
            Route::post('/orders', [OrderController::class, 'checkout']);
            Route::post('/orders/{orderNumber}/cancel', [OrderController::class, 'cancel']);
            Route::post('/orders/{orderNumber}/confirm', [OrderController::class, 'confirmReceived']);
            Route::post('/orders/{orderNumber}/rate', [OrderController::class, 'rate']);
            Route::post('/seller/orders/{orderNumber}/status', [OrderController::class, 'updateStatusBySeller']);

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
            Route::get('/remittances/pending', [CodRemittanceController::class, 'pending']);
            Route::post('/remittances', [CodRemittanceController::class, 'store']);

            // Rider Fleet, Vehicle, and Documents
            Route::get('/fleet', [RiderProfileController::class, 'fleet']);
            Route::get('/vehicle', [RiderProfileController::class, 'getVehicle']);
            Route::put('/vehicle', [RiderProfileController::class, 'updateVehicle']);
            Route::get('/documents', [RiderProfileController::class, 'getDocuments']);
            Route::post('/documents', [RiderProfileController::class, 'uploadDocument']);
        });



                Route::middleware(['role:logistics|admin', 'approved'])->prefix('logistics')->group(function () {
            Route::get('/dashboard', [LogisticsController::class, 'dashboard']);
            Route::get('/parcels/{identifier}', [LogisticsController::class, 'show']);
            Route::post('/scan', [LogisticsController::class, 'scan']);
            Route::get('/audit-log', [LogisticsController::class, 'auditLog']);
        });

        Route::middleware(['role:logistics|admin', 'approved'])->group(function () {
            Route::get('/remittances', [CodRemittanceController::class, 'index']);
            Route::post('/remittances/{remittance}/confirm', [CodRemittanceController::class, 'confirm']);
        });
    });
});
