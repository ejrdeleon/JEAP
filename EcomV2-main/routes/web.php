<?php

use App\Http\Controllers\Admin\AnnouncementController;
use App\Http\Controllers\Admin\ContactMessageController as AdminContactMessageController;
use App\Http\Controllers\Admin\DashboardController as AdminDashboard;
use App\Http\Controllers\Admin\DisputeController;
use App\Http\Controllers\Admin\KycDocumentController;
use App\Http\Controllers\Admin\RegistrationReviewController;
use App\Http\Controllers\Admin\UserManagementController;
use App\Http\Controllers\Account\SettingsController;
use App\Http\Controllers\Auth\EmailVerificationController;
use App\Http\Controllers\Auth\GoogleAuthController;
use App\Http\Controllers\Auth\LoginController;
use App\Http\Controllers\Auth\RegisterController;
use App\Http\Controllers\Buyer\DashboardController as BuyerDashboard;
use App\Http\Controllers\ChatController;
use App\Http\Controllers\MediaController;
use App\Http\Controllers\NotificationInboxController;
use App\Http\Controllers\Buyer\WishlistController;
use App\Http\Controllers\Courier\DashboardController as CourierDashboard;
use App\Http\Controllers\Logistics\CourierReviewController;
use App\Http\Controllers\Logistics\RiderController as LogisticsRiderController;
use App\Http\Controllers\Logistics\ShipmentController as LogisticsShipmentController;
use App\Http\Controllers\PhilippineLocationController;
use App\Http\Controllers\Seller\DashboardController as SellerDashboard;
use App\Http\Controllers\Shipping\PageController as ShippingPage;
use App\Http\Controllers\Storefront\CartController;
use App\Http\Controllers\Storefront\ContactController;
use App\Http\Controllers\Storefront\HomeController;
use App\Http\Controllers\Storefront\PageController;
use App\Http\Controllers\Storefront\ProductController;
use App\Http\Controllers\Storefront\StoreController;
use App\Http\Controllers\SuperAdmin\DashboardController as SuperAdminDashboard;
use Illuminate\Support\Facades\Route;

Route::get('/', HomeController::class)->name('home');

Route::get('/login', [LoginController::class, 'create'])->name('login');
Route::post('/login', [LoginController::class, 'store'])->middleware('throttle:login');
Route::get('/auth/google/redirect', [GoogleAuthController::class, 'redirect'])->middleware('throttle:google')->name('google.redirect');
Route::get('/auth/google/callback', [GoogleAuthController::class, 'callback'])->middleware('throttle:google')->name('google.callback');
Route::get('/media/avatars/{user}', [MediaController::class, 'avatar'])->name('media.avatar');
Route::post('/logout', [LoginController::class, 'destroy'])->name('logout');
Route::get('/email/verify', [EmailVerificationController::class, 'show'])->name('email.verify.show');
Route::post('/email/verify', [EmailVerificationController::class, 'verify'])->middleware('throttle:10,1')->name('email.verify');
Route::post('/email/verify/resend', [EmailVerificationController::class, 'resend'])->middleware('throttle:3,1')->name('email.verify.resend');

Route::get('/register', [RegisterController::class, 'create'])->name('register');
Route::post('/register', [RegisterController::class, 'store'])->middleware('throttle:register');
Route::get('/register/seller', [RegisterController::class, 'createSeller'])->name('register.seller');
Route::post('/register/seller', [RegisterController::class, 'storeSeller'])->middleware('throttle:register');
Route::get('/register/rider', [RegisterController::class, 'createRider'])->name('register.rider');
Route::post('/register/rider', [RegisterController::class, 'storeRider'])->middleware('throttle:register');
Route::get('/register/logistics', [RegisterController::class, 'createLogistics'])->name('register.logistics');
Route::post('/register/logistics', [RegisterController::class, 'storeLogistics'])->middleware('throttle:register');
Route::get('/register/pending', [RegisterController::class, 'pending'])->name('register.pending');
Route::get('/rider/activate/{user}/{token}', [LogisticsRiderController::class, 'showActivation'])->name('rider.activate.show');
Route::post('/rider/activate/{user}/{token}', [LogisticsRiderController::class, 'activate'])->middleware('throttle:10,1')->name('rider.activate');

Route::get('/products', [ProductController::class, 'index'])->name('products.index');
Route::get('/products/{slug}', [ProductController::class, 'show'])->name('products.show');
Route::get('/products/{slug}/pay', [ProductController::class, 'pay'])->name('products.pay');
Route::get('/stores/{seller}', [StoreController::class, 'show'])->name('stores.show');

Route::get('/cart', [CartController::class, 'index'])->name('cart.index');
Route::post('/cart', [CartController::class, 'add'])->name('cart.add')->middleware('throttle:60,1');
Route::patch('/cart/{item}', [CartController::class, 'update'])->name('cart.update');
Route::delete('/cart/{item}', [CartController::class, 'remove'])->name('cart.remove');

Route::get('/about', [PageController::class, 'about'])->name('about');
Route::get('/contact', [PageController::class, 'contact'])->name('contact');
Route::post('/contact', [ContactController::class, 'store'])->middleware('throttle:5,1')->name('contact.submit');
Route::get('/help', [PageController::class, 'help'])->name('help');
Route::get('/philippines/locations/{level}', [PhilippineLocationController::class, 'index'])
    ->middleware('throttle:60,1')
    ->whereIn('level', ['countries', 'regions', 'provinces', 'municipalities', 'barangays', 'postal-codes'])
    ->name('philippines.locations');

Route::middleware(['auth', 'approved'])->group(function () {
    Route::middleware('role:buyer|super-admin')->group(function () {
        Route::get('/checkout', [PageController::class, 'checkout'])->name('checkout');
        Route::post('/checkout', [PageController::class, 'place'])->name('checkout.place')->middleware('throttle:10,1');
    });

    Route::get('/search', [BuyerDashboard::class, 'search'])->name('search');
    Route::get('/profile', [PageController::class, 'profile'])->name('profile');
    Route::post('/profile', [PageController::class, 'updateProfile'])->name('profile.update')->middleware('throttle:20,1');
    Route::get('/account/password', [SettingsController::class, 'password'])->name('account.password');
    Route::post('/account/password', [SettingsController::class, 'updatePassword'])->name('account.password.update')->middleware('throttle:10,1');
    Route::get('/account/notifications', [SettingsController::class, 'notifications'])->name('account.notification-settings');
    Route::post('/account/notifications', [SettingsController::class, 'updateNotifications'])->name('account.notification-settings.update');
    Route::get('/inbox', [ChatController::class, 'index'])->name('chat.index');
    Route::post('/inbox/start', [ChatController::class, 'start'])->middleware('throttle:chat')->name('chat.start');
    Route::get('/inbox/{conversation}', [ChatController::class, 'show'])->name('chat.show');
    Route::post('/inbox/{conversation}', [ChatController::class, 'send'])->middleware('throttle:chat')->name('chat.send');
    Route::get('/inbox/{conversation}/messages', [ChatController::class, 'messages'])->name('chat.messages');
    Route::get('/notifications', [NotificationInboxController::class, 'index'])->name('notifications.index');
    Route::post('/notifications/read', [NotificationInboxController::class, 'read'])->name('notifications.read');

    Route::prefix('buyer')->name('buyer.')->group(function () {
        Route::get('/', [BuyerDashboard::class, 'home'])->name('home');
        Route::middleware('role:buyer|super-admin')->group(function () {
            Route::get('/wishlist', [WishlistController::class, 'index'])->name('wishlist');
            Route::post('/wishlist/{product}', [WishlistController::class, 'saveProduct'])->name('wishlist.save');
            Route::delete('/wishlist/{product}', [WishlistController::class, 'removeProduct'])->name('wishlist.remove');
            Route::post('/sellers/{seller}/follow', [WishlistController::class, 'followSeller'])->name('sellers.follow');
            Route::delete('/sellers/{seller}/follow', [WishlistController::class, 'unfollowSeller'])->name('sellers.unfollow');
            Route::post('/orders/{order}/cancel', [BuyerDashboard::class, 'cancelOrder'])->middleware('throttle:10,1')->name('orders.cancel');
            Route::get('/addresses', [BuyerDashboard::class, 'addresses'])->name('addresses');
            Route::post('/addresses', [BuyerDashboard::class, 'storeAddress'])->name('addresses.store');
            Route::put('/addresses/{address}', [BuyerDashboard::class, 'updateAddress'])->name('addresses.update');
            Route::delete('/addresses/{address}', [BuyerDashboard::class, 'deleteAddress'])->name('addresses.delete');
        });
        Route::get('/cart', [BuyerDashboard::class, 'cart'])->name('cart');
        Route::get('/checkout', [BuyerDashboard::class, 'checkout'])->name('checkout');
        Route::get('/orders/{order}', [BuyerDashboard::class, 'track'])->name('orders.track');
        Route::post('/orders/{order}/confirm-received', [BuyerDashboard::class, 'confirmReceived'])->middleware('throttle:10,1')->name('orders.confirm-received');
    });

    Route::middleware('role:seller|super-admin')->prefix('seller')->name('seller.')->group(function () {
        Route::get('/', [SellerDashboard::class, 'index'])->name('dashboard');
        Route::get('/catalog', [SellerDashboard::class, 'catalog'])->name('catalog');
        Route::post('/catalog', [SellerDashboard::class, 'storeProduct'])->name('catalog.store');
        Route::get('/catalog/{product}/edit', [SellerDashboard::class, 'editProduct'])->name('catalog.edit');
        Route::put('/catalog/{product}', [SellerDashboard::class, 'updateProduct'])->name('catalog.update');
        Route::delete('/catalog/{product}', [SellerDashboard::class, 'archiveProduct'])->name('catalog.archive');
        Route::get('/orders', [SellerDashboard::class, 'orders'])->name('orders');
        Route::patch('/orders/{order}/status', [SellerDashboard::class, 'updateOrderStatus'])->middleware('throttle:30,1')->name('orders.status');
        Route::get('/promos', [SellerDashboard::class, 'promos'])->name('promos');
        Route::post('/promos', [SellerDashboard::class, 'storePromo'])->middleware('throttle:20,1')->name('promos.store');
        Route::patch('/promos/{voucher}', [SellerDashboard::class, 'togglePromo'])->name('promos.toggle');
        Route::delete('/promos/{voucher}', [SellerDashboard::class, 'destroyPromo'])->name('promos.destroy');
        Route::get('/shipments', [SellerDashboard::class, 'shipments'])->name('shipments');
    });

    Route::middleware('role:courier')->prefix('courier')->name('courier.')->group(function () {
        Route::get('/', [CourierDashboard::class, 'index'])->name('dashboard');
        Route::patch('/availability', [CourierDashboard::class, 'updateAvailability'])->name('availability');
        Route::put('/profile', [CourierDashboard::class, 'updateProfile'])->name('profile.update');
    });

    Route::middleware('role:logistics|admin|super-admin')->prefix('logistics')->name('logistics.')->group(function () {
        Route::get('/', [LogisticsShipmentController::class, 'index'])->name('dashboard');
        Route::get('/shipments', [LogisticsShipmentController::class, 'index'])->name('shipments');
        Route::post('/shipments/{parcel}/pickup-assignment', [LogisticsShipmentController::class, 'assignPickup'])->middleware('throttle:30,1')->name('shipments.assign-pickup');
        Route::post('/shipments/{parcel}/progress', [LogisticsShipmentController::class, 'progress'])->middleware('throttle:30,1')->name('shipments.progress');
        Route::post('/shipments/{parcel}/delivery-assignment', [LogisticsShipmentController::class, 'assignDelivery'])->middleware('throttle:30,1')->name('shipments.assign-delivery');
        Route::get('/couriers', [CourierReviewController::class, 'index'])->name('couriers');
        Route::post('/couriers/{user}', [CourierReviewController::class, 'decide'])
            ->middleware('throttle:30,1')
            ->name('couriers.decide');
        Route::middleware('role:logistics|super-admin')->group(function (): void {
            Route::get('/riders', [LogisticsRiderController::class, 'index'])->name('riders');
            Route::post('/riders', [LogisticsRiderController::class, 'store'])->middleware('throttle:10,1')->name('riders.store');
            Route::post('/riders/{user}/resend-activation', [LogisticsRiderController::class, 'resend'])->middleware('throttle:3,1')->name('riders.resend');
        });
    });

    Route::middleware('role:admin|super-admin')->prefix('admin')->name('admin.')->group(function () {
        Route::get('/', [AdminDashboard::class, 'index'])->name('dashboard');
        Route::get('/verifications', [RegistrationReviewController::class, 'index'])->name('verifications');
        Route::post('/verifications/{user}', [RegistrationReviewController::class, 'decide'])
            ->middleware('throttle:30,1')
            ->name('verifications.decide');
        Route::get('/documents/{document}', [KycDocumentController::class, 'download'])->name('documents.download');
        Route::get('/cms', [AdminDashboard::class, 'cms'])->name('cms');
        Route::post('/cms', [AnnouncementController::class, 'store'])->name('cms.store');
        Route::put('/cms/{announcement}', [AnnouncementController::class, 'update'])->name('cms.update');
        Route::patch('/cms/{announcement}/publish', [AnnouncementController::class, 'togglePublished'])->name('cms.publish');
        Route::get('/users', [AdminDashboard::class, 'users'])->name('users');
        Route::patch('/users/{user}/status', [UserManagementController::class, 'updateStatus'])->name('users.status');
        Route::get('/disputes', [AdminDashboard::class, 'disputes'])->name('disputes');
        Route::patch('/disputes/{complaint}', [DisputeController::class, 'update'])->name('disputes.update');
        Route::get('/contact-messages', [AdminContactMessageController::class, 'index'])->name('contact-messages');
        Route::get('/reports', [AdminDashboard::class, 'reports'])->name('reports');
    });

    Route::middleware('role:super-admin')->prefix('super-admin')->name('super-admin.')->group(function () {
        Route::get('/', [SuperAdminDashboard::class, 'index'])->name('dashboard');
        Route::get('/admins', [SuperAdminDashboard::class, 'admins'])->name('admins');
        Route::post('/admins', [SuperAdminDashboard::class, 'storeAdmin'])->middleware('throttle:10,1')->name('admins.store');
        Route::patch('/admins/{user}/status', [SuperAdminDashboard::class, 'updateAdminStatus'])->name('admins.status');
        Route::get('/settings', [SuperAdminDashboard::class, 'settings'])->name('settings');
        Route::post('/settings/policies', [SuperAdminDashboard::class, 'storePolicy'])->name('settings.policies.store');
        Route::put('/settings/policies/{policy}', [SuperAdminDashboard::class, 'updatePolicy'])->name('settings.policies.update');
    });
});

Route::prefix('shipping')->name('shipping.')->group(function () {
    Route::get('/', [ShippingPage::class, 'home'])->name('home');
    Route::get('/track', [ShippingPage::class, 'track'])->name('track');
    Route::get('/services', [ShippingPage::class, 'services'])->name('services');
    Route::get('/pricing', [ShippingPage::class, 'pricing'])->name('pricing');

    Route::middleware(['auth', 'approved'])->group(function () {
        Route::get('/ship', [ShippingPage::class, 'ship'])->name('ship');
        Route::get('/shipments', [ShippingPage::class, 'shipments'])->name('shipments');
        Route::get('/shipments/{parcel}', [ShippingPage::class, 'details'])->name('details');
        Route::get('/account', [ShippingPage::class, 'account'])->name('account');
    });
});
