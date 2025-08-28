<?php
// routes/api.php
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\FamilyController;
use App\Http\Controllers\Api\LocationController;
use App\Http\Controllers\Api\NotificationController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

Route::post('/auth/register', [AuthController::class, 'register']);
Route::post('/auth/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/auth/logout', [AuthController::class, 'logout']);
    Route::get('/auth/user', [AuthController::class, 'user']);

    // Family Management
    Route::post('/family/create', [FamilyController::class, 'create']);
    Route::post('/family/join', [FamilyController::class, 'join']);
    Route::get('/family/members', [FamilyController::class, 'members']);

    // Location Tracking
    Route::post('/location/update', [LocationController::class, 'update']);
    Route::get('/location/track/{childId}', [LocationController::class, 'track']);
    Route::get('/location/history/{childId}', [LocationController::class, 'history']);

    // Notifications
    Route::post('/notification/send', [NotificationController::class, 'send']);
    Route::get('/notification/list/{childId}', [NotificationController::class, 'list']);
    Route::post('/notification/mark-read', [NotificationController::class, 'markRead']);
});
