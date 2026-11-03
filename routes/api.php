<?php

use App\Http\Controllers\Api\Dash\ShipmentCheckpointController as DashShipmentCheckpointController;
use App\Http\Controllers\Api\V1\AddressController;
use App\Http\Controllers\Api\V1\AdminUserController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\CartController;
use App\Http\Controllers\Api\V1\CatalogController;
use App\Http\Controllers\Api\V1\CodRemittanceController;
use App\Http\Controllers\Api\V1\ConversationController;
use App\Http\Controllers\Api\V1\LocationController;
use App\Http\Controllers\Api\V1\LogisticsHubController;
use App\Http\Controllers\Api\V1\LogisticsShipmentController;
use App\Http\Controllers\Api\V1\NotificationController;
use App\Http\Controllers\Api\V1\OrderController;
use App\Http\Controllers\Api\V1\ReturnRequestController;
use App\Http\Controllers\Api\V1\RiderAssignmentController;
use App\Http\Controllers\Api\V1\RiderProfileController;
use App\Http\Controllers\Api\V1\VoucherController;
use App\Http\Controllers\Api\V1\WishlistController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->middleware('throttle:api')->group(function () {

    // ── Public ────────────────────────────────────────────
    Route::get('/categories', [CatalogController::class, 'categories']);
    Route::get('/products', [CatalogController::class, 'products']);
    Route::get('/brands', [CatalogController::class, 'brands']);
    Route::get('/home', [CatalogController::class, 'home']);
    Route::get('/products/{slug}', [CatalogController::class, 'show']);

    Route::get('/locations/regions', [LocationController::class, 'regions']);
    Route::get('/locations/regions/{regionCode}/provinces', [LocationController::class, 'provinces']);
    Route::get('/locations/regions/{regionCode}/cities-municipalities', [LocationController::class, 'regionCities']);
    Route::get('/locations/provinces/{provinceCode}/cities-municipalities', [LocationController::class, 'provinceCities']);
    Route::get('/locations/cities-municipalities/{localityCode}/barangays', [LocationController::class, 'barangays']);
    Route::get('/locations/cities-municipalities/{localityCode}/postal-code', [LocationController::class, 'postalCode']);
    Route::get('/locations/search', [LocationController::class, 'search']);

    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login', [AuthController::class, 'login'])->middleware('throttle:5,1');
    Route::post('/auth/google', [AuthController::class, 'googleSignIn']);
    Route::post('/email/verify', [AuthController::class, 'verifyEmail'])->middleware('throttle:10,1');
    Route::post('/email/resend', [AuthController::class, 'resendEmailVerification'])->middleware('throttle:3,1');
    Route::post('/forgot-password', [AuthController::class, 'forgotPassword'])->middleware('throttle:5,1');
    Route::post('/reset-password', [AuthController::class, 'resetPassword'])->middleware('throttle:10,1');

    // ── Authenticated ─────────────────────────────────────
    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/me', [AuthController::class, 'me']);
        Route::post('/logout', [AuthController::class, 'logout']);
        Route::put('/profile', [AuthController::class, 'updateProfile']);
        Route::post('/profile/avatar', [AuthController::class, 'updateAvatar']);
        Route::put('/password', [AuthController::class, 'changePassword']);

        Route::get('/notifications', [NotificationController::class, 'index']);
        Route::post('/notifications/read-all', [NotificationController::class, 'markAllAsRead']);
        Route::post('/notifications/{id}/read', [NotificationController::class, 'markAsRead']);
        Route::get('/notification-preferences', [NotificationController::class, 'preferences']);
        Route::put('/notification-preferences', [NotificationController::class, 'updatePreferences']);

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
            Route::post('/orders/{orderNumber}/cancel', [OrderController::class, 'cancel']);
            Route::post('/orders/{orderNumber}/rate', [OrderController::class, 'rate']);
            Route::post('/vouchers/validate', [VoucherController::class, 'validate']);
            Route::get('/returns', [ReturnRequestController::class, 'index']);
            Route::post('/returns', [ReturnRequestController::class, 'store']);

            Route::get('/wishlist', [WishlistController::class, 'index']);
            Route::post('/wishlist/{product}', [WishlistController::class, 'store']);
            Route::delete('/wishlist/{product}', [WishlistController::class, 'destroy']);

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
            Route::get('/conversations', [ConversationController::class, 'index']);
            Route::post('/conversations', [ConversationController::class, 'start']);
            Route::get('/conversations/{conversationId}/messages', [ConversationController::class, 'messages']);
            Route::post('/conversations/{conversationId}/messages', [ConversationController::class, 'send']);
        });

        Route::middleware(['role:seller', 'approved'])->prefix('seller')->group(function () {
            Route::get('/products', [CatalogController::class, 'sellerProducts']);
            Route::post('/orders/{orderNumber}/status', [OrderController::class, 'sellerUpdateStatus']);
            Route::get('/vouchers', [VoucherController::class, 'index']);
            Route::post('/vouchers', [VoucherController::class, 'store']);
            Route::post('/vouchers/{voucher}/toggle', [VoucherController::class, 'toggle']);
            Route::delete('/vouchers/{voucher}', [VoucherController::class, 'destroy']);
        });

        Route::middleware(['role:courier', 'approved'])->prefix('rider')->group(function () {
            Route::get('/assignments', [RiderAssignmentController::class, 'index']);
            Route::post('/assignments/{assignmentKey}/{action}', [RiderAssignmentController::class, 'action'])
                ->where('assignmentKey', '(pickup|delivery)-[0-9]+')
                ->where('action', 'accept|scan|out-for-delivery|deliver|fail')
                ->middleware('throttle:30,1');
            Route::get('/remittances/pending', [CodRemittanceController::class, 'pending']);
            Route::post('/remittances', [CodRemittanceController::class, 'store']);
            Route::get('/fleet', [RiderProfileController::class, 'fleet']);
            Route::get('/vehicle', [RiderProfileController::class, 'getVehicle']);
            Route::put('/vehicle', [RiderProfileController::class, 'updateVehicle']);
            Route::get('/documents', [RiderProfileController::class, 'getDocuments']);
            Route::post('/documents', [RiderProfileController::class, 'uploadDocument']);
        });

        Route::middleware(['role:admin|super-admin', 'approved'])->prefix('admin')->group(function () {
            Route::patch('/users/{user}/status', [AdminUserController::class, 'updateStatus']);
            Route::post('/verifications/{user}', [AdminUserController::class, 'decide']);
            Route::post('/returns/{returnRequest}/decide', [ReturnRequestController::class, 'decide']);
        });

        Route::middleware(['role:logistics|admin|super-admin', 'approved'])->prefix('logistics')->group(function () {
            Route::get('/dashboard', [LogisticsHubController::class, 'dashboard']);
            Route::get('/parcels/{identifier}', [LogisticsHubController::class, 'show']);
            Route::post('/scan', [LogisticsHubController::class, 'scan'])->middleware('throttle:30,1');
            Route::get('/audit-log', [LogisticsHubController::class, 'auditLog']);
            Route::get('/remittances', [CodRemittanceController::class, 'index']);
            Route::post('/remittances/{remittance}/confirm', [CodRemittanceController::class, 'confirm']);
            Route::post('/parcels/{parcel}/pickup-assignment', [LogisticsShipmentController::class, 'assignPickup'])
                ->middleware('throttle:30,1');
            Route::post('/parcels/{parcel}/delivery-assignment', [LogisticsShipmentController::class, 'assignDelivery'])
                ->middleware('throttle:30,1');
        });
    });
});

Route::middleware(['auth:sanctum', 'approved', 'role:courier|logistics|admin|super-admin', 'throttle:30,1'])
    ->post('/dash/shipments/{tracking_number}/checkpoint', [DashShipmentCheckpointController::class, 'store']);
