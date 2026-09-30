<?php

use App\Http\Controllers\Api\AdminRegistrationController;
use App\Http\Controllers\Api\AgentController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ChitController;
use App\Http\Controllers\Api\CorrectionController;
use App\Http\Controllers\Api\CustomerController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\FeedController;
use App\Http\Controllers\Api\PaymentController;
use App\Http\Controllers\Api\RazorpayWebhookController;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\DB;

/*
|--------------------------------------------------------------------------
| API routes (mobile app: Customer / Agent / Admin)
|--------------------------------------------------------------------------
| One login for everyone (functional spec §3.1). Every route below auth:sanctum
| is additionally guarded by role:... and, inside the controller, by ownership
| checks (an agent can only ever touch their own customers).
*/

Route::post('/auth/login', [AuthController::class, 'login'])->middleware('throttle:10,1');
Route::post('/auth/set-new-pin', [AuthController::class, 'setNewPin'])->middleware('throttle:10,1');
Route::post('/auth/register-admin', [AuthController::class, 'registerAdmin'])->middleware('throttle:5,1');

// Razorpay calls this directly — no Sanctum auth, protected by webhook signature instead.
Route::post('/webhooks/razorpay', [RazorpayWebhookController::class, 'handle']);

Route::get('/debug/db', function () {
    try {
        DB::connection()->getPdo();

        return response()->json([
            'status' => 'success',
            'database' => DB::connection()->getDatabaseName(),
            'message' => 'Database connection successful',
        ]);
    } catch (\Throwable $e) {
        return response()->json([
            'status' => 'error',
            'message' => $e->getMessage(),
        ], 500);
    }
});

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/auth/logout', [AuthController::class, 'logout']);
    Route::post('/auth/change-pin', [AuthController::class, 'changePin']);
    Route::get('/me', [AuthController::class, 'me']);

    // ---- Customer side ----
    Route::middleware('role:customer')->prefix('customer')->group(function () {
        Route::get('/dashboard', [DashboardController::class, 'customer']);
        Route::get('/chits', [CustomerController::class, 'myChits']);
        Route::get('/chits/{chit}', [ChitController::class, 'show']);
        Route::get('/chits/{chit}/schedule', [ChitController::class, 'schedule']);
        Route::get('/chits/{chit}/payments', [FeedController::class, 'customerChitPayments']);
        Route::post('/chits/{chit}/pay/start', [PaymentController::class, 'startOnline']);
        Route::post('/payments/verify', [PaymentController::class, 'verifyOnline']);
    });

    // ---- Agent side ----
    Route::middleware('role:agent')->prefix('agent')->group(function () {
        Route::get('/dashboard', [DashboardController::class, 'agent']);
        Route::get('/portfolio', [FeedController::class, 'portfolio']);
        Route::get('/payments', [FeedController::class, 'agentPayments']);
        Route::get('/customers', [CustomerController::class, 'index']);
        Route::post('/customers', [CustomerController::class, 'store']);
        Route::get('/customers/{customer}', [CustomerController::class, 'show']);
        Route::post('/chits', [ChitController::class, 'store']);
        Route::get('/chits/{chit}', [ChitController::class, 'show']);
        Route::get('/chits/{chit}/schedule', [ChitController::class, 'schedule']);
        Route::post('/chits/{chit}/collect-cash', [PaymentController::class, 'collectCash']);
        Route::post('/payments/{payment}/correction', [CorrectionController::class, 'store']);
    });

    // ---- Admin + Super Admin side (also used by the Livewire web panel via the same services) ----
    Route::middleware('role:admin')->prefix('admin')->group(function () {
        Route::get('/dashboard', [DashboardController::class, 'admin']);
        Route::apiResource('customers', CustomerController::class)->only(['index', 'store', 'show']);
        Route::apiResource('agents', AgentController::class)->only(['index', 'store']);
        Route::post('/customers/{customer}/transfer', [AgentController::class, 'transfer']);
        Route::post('/customers/{customer}/reset-pin', [AgentController::class, 'resetCustomerPin']);
        Route::post('/customers/{customer}/active', [AgentController::class, 'setCustomerActive']);
        Route::post('/agents/{agent}/active', [AgentController::class, 'setAgentActive']);
        Route::post('/agents/{agent}/reset-pin', [AgentController::class, 'resetAgentPin']);
        Route::get('/portfolio', [FeedController::class, 'portfolio']);
        Route::get('/chits', [FeedController::class, 'adminChits']);
        Route::get('/payments', [FeedController::class, 'adminPayments']);
        Route::get('/audit-logs', [FeedController::class, 'auditLogs']);
        Route::post('/agents/{agent}/deactivate', [AgentController::class, 'deactivate']);
        Route::post('/chits', [ChitController::class, 'store']);
        Route::get('/chits/{chit}', [ChitController::class, 'show']);
        Route::get('/chits/{chit}/schedule', [ChitController::class, 'schedule']);
        Route::post('/chits/{chit}/disburse', [ChitController::class, 'disburse']);
        Route::post('/chits/{chit}/cancel', [ChitController::class, 'cancel']);
        Route::get('/corrections', [CorrectionController::class, 'index']);
        Route::post('/corrections/{correction}/approve', [CorrectionController::class, 'approve']);
        Route::post('/corrections/{correction}/reject', [CorrectionController::class, 'reject']);
        Route::get('/payments/{payment}', [PaymentController::class, 'show']);

        // Super Admin only (checked again inside the controller)
        Route::get('/admin-users', [AdminRegistrationController::class, 'index']);
        Route::post('/admin-users/{pending}/approve', [AdminRegistrationController::class, 'approve']);
        Route::post('/admin-users/{pending}/reject', [AdminRegistrationController::class, 'reject']);
        Route::post('/admin-users/{admin}/active', [AdminRegistrationController::class, 'setActive']);
    });
});
