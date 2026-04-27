<?php

use App\Http\Controllers\Api\V1\Auth\FacebookCallbackController;
use App\Http\Controllers\Api\V1\Auth\FacebookRedirectController;
use App\Http\Controllers\Api\V1\Auth\ForgotPasswordController;
use App\Http\Controllers\Api\V1\Auth\GoogleCallbackController;
use App\Http\Controllers\Api\V1\Auth\GoogleRedirectController;
use App\Http\Controllers\Api\V1\Auth\LoginController;
use App\Http\Controllers\Api\V1\Auth\LogoutController;
use App\Http\Controllers\Api\V1\Auth\MeController;
use App\Http\Controllers\Api\V1\Auth\RefreshTokenController;
use App\Http\Controllers\Api\V1\Auth\RegisterController;
use App\Http\Controllers\Api\V1\Auth\ResendOtpController;
use App\Http\Controllers\Api\V1\Auth\ResetPasswordController;
use App\Http\Controllers\Api\V1\Auth\SocialTokenController;
use App\Http\Controllers\Api\V1\Auth\TwoFactorConfirmController;
use App\Http\Controllers\Api\V1\Auth\TwoFactorDisableController;
use App\Http\Controllers\Api\V1\Auth\TwoFactorEnableController;
use App\Http\Controllers\Api\V1\Auth\TwoFactorVerifyController;
use App\Http\Controllers\Api\V1\Auth\VerifyEmailController;
use App\Http\Controllers\Api\V1\Conversation\ConversationCloseController;
use App\Http\Controllers\Api\V1\Conversation\ConversationCreateController;
use App\Http\Controllers\Api\V1\Conversation\ConversationEscalateController;
use App\Http\Controllers\Api\V1\Conversation\ConversationListController;
use App\Http\Controllers\Api\V1\Conversation\ConversationRateController;
use App\Http\Controllers\Api\V1\Conversation\ConversationShowController;
use App\Http\Controllers\Api\V1\Conversation\MessageAudioController;
use App\Http\Controllers\Api\V1\Conversation\MessageListController;
use App\Http\Controllers\Api\V1\Conversation\MessageReadController;
use App\Http\Controllers\Api\V1\Conversation\MessageSendController;
use App\Http\Controllers\Api\V1\Conversation\TypingController;
use App\Http\Controllers\Api\V1\Expert\ApplyController;
use App\Http\Controllers\Api\V1\Expert\AvailabilityController;
use App\Http\Controllers\Api\V1\Expert\ExpertDashboardController;
use App\Http\Controllers\Api\V1\Expert\ExpertDocumentController;
use App\Http\Controllers\Api\V1\Expert\ExpertProfileController;
use App\Http\Controllers\Api\V1\Expert\ExpertWalletController;
use App\Http\Controllers\Api\V1\CategoryListController;
use App\Http\Controllers\Api\V1\ExpertListController;
use App\Http\Controllers\Api\V1\ExpertReviewsController;
use App\Http\Controllers\Api\V1\ExpertShowController;
use App\Http\Controllers\Api\V1\NotificationController;
use App\Http\Controllers\Api\V1\Admin\AdminAiLogController;
use App\Http\Controllers\Api\V1\Admin\AdminCategoryController;
use App\Http\Controllers\Api\V1\Admin\AdminConversationController;
use App\Http\Controllers\Api\V1\Admin\AdminDashboardController;
use App\Http\Controllers\Api\V1\Admin\AdminExpertListController;
use App\Http\Controllers\Api\V1\Admin\AdminExpertValidateController;
use App\Http\Controllers\Api\V1\Admin\AdminExpertRejectController;
use App\Http\Controllers\Api\V1\Admin\AdminKnowledgeBaseController;
use App\Http\Controllers\Api\V1\Admin\AdminPaymentsController;
use App\Http\Controllers\Api\V1\Admin\AdminUserController;
use App\Http\Controllers\Api\V1\AI\AiCallbackController;
use App\Http\Controllers\Api\V1\AI\TranscriptionCompleteController;
use App\Http\Controllers\Api\V1\AI\TtsCompleteController;
use App\Http\Controllers\Api\V1\Payment\CmiCallbackController;
use App\Http\Controllers\Api\V1\Payment\CmiInitiateController;
use App\Http\Controllers\Api\V1\Payment\PaymentConfirmController;
use App\Http\Controllers\Api\V1\Payment\PaymentHistoryController;
use App\Http\Controllers\Api\V1\Payment\PaymentIntentController;
use App\Http\Controllers\Api\V1\Payment\StripeWebhookController;
use App\Http\Controllers\Api\V1\User\DeleteAccountController;
use App\Http\Controllers\Api\V1\User\UserAvatarController;
use App\Http\Controllers\Api\V1\User\UserProfileController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {

    // ================================================================
    // AUTH — public (rate limited: 10/min)
    // ================================================================
    Route::prefix('auth')->middleware('throttle:10,1')->group(function () {
        Route::post('register', RegisterController::class);
        Route::post('login', LoginController::class);
        Route::post('verify-email', VerifyEmailController::class);
        Route::post('resend-otp', ResendOtpController::class);
        Route::post('forgot-password', ForgotPasswordController::class);
        Route::post('reset-password', ResetPasswordController::class);
        Route::post('refresh', RefreshTokenController::class);

        // OAuth — web redirects
        Route::get('google/redirect', GoogleRedirectController::class);
        Route::get('google/callback', GoogleCallbackController::class);
        Route::get('facebook/redirect', FacebookRedirectController::class);
        Route::get('facebook/callback', FacebookCallbackController::class);

        // OAuth — mobile token exchange
        Route::post('social/token', SocialTokenController::class);

        // 2FA verify on login (uses 2fa_token, not auth:sanctum)
        Route::post('2fa/verify', TwoFactorVerifyController::class);
    });

    // AUTH — protected
    Route::prefix('auth')->middleware('auth:sanctum')->group(function () {
        Route::post('logout', LogoutController::class);
        Route::get('me', MeController::class);

        // 2FA management
        Route::post('2fa/enable', TwoFactorEnableController::class);
        Route::post('2fa/confirm', TwoFactorConfirmController::class);
        Route::post('2fa/disable', TwoFactorDisableController::class);
    });

    // ================================================================
    // PUBLIC — categories & experts
    // ================================================================
    Route::get('categories', CategoryListController::class);
    Route::get('experts', ExpertListController::class);
    Route::get('experts/{expert}', ExpertShowController::class);
    Route::get('experts/{expert}/reviews', ExpertReviewsController::class);

    // ================================================================
    // USER PROFILE — authenticated
    // ================================================================
    Route::prefix('users')->middleware('auth:sanctum')->group(function () {
        Route::get('profile', [UserProfileController::class, 'show']);
        Route::put('profile', [UserProfileController::class, 'update']);
        Route::post('avatar', UserAvatarController::class);
        Route::delete('account', DeleteAccountController::class);
    });

    // ================================================================
    // NOTIFICATIONS — authenticated
    // ================================================================
    Route::prefix('notifications')->middleware('auth:sanctum')->group(function () {
        Route::get('/', [NotificationController::class, 'index']);
        Route::put('{notification}/read', [NotificationController::class, 'markAsRead']);
        Route::put('read-all', [NotificationController::class, 'markAllAsRead']);
    });

    // ================================================================
    // EXPERT — authenticated expert endpoints
    // ================================================================
    Route::prefix('expert')->middleware('auth:sanctum')->group(function () {
        Route::post('apply', ApplyController::class);

        Route::get('profile', [ExpertProfileController::class, 'show']);
        Route::put('profile', [ExpertProfileController::class, 'update']);
        Route::put('availability', AvailabilityController::class);
        Route::get('dashboard', ExpertDashboardController::class);

        Route::get('documents', [ExpertDocumentController::class, 'index']);
        Route::post('documents', [ExpertDocumentController::class, 'store']);
        Route::delete('documents/{document}', [ExpertDocumentController::class, 'destroy']);

        Route::get('wallet', [ExpertWalletController::class, 'show']);
        Route::get('wallet/transactions', [ExpertWalletController::class, 'transactions']);
    });

    // ================================================================
    // CONVERSATIONS — authenticated
    // ================================================================
    Route::prefix('conversations')->middleware('auth:sanctum')->group(function () {
        Route::get('/', ConversationListController::class);
        Route::post('/', ConversationCreateController::class);
        Route::get('{conversation}', ConversationShowController::class);
        Route::post('{conversation}/escalate', ConversationEscalateController::class);
        Route::put('{conversation}/close', ConversationCloseController::class);
        Route::post('{conversation}/rate', ConversationRateController::class);

        // Messages
        Route::get('{conversation}/messages', MessageListController::class);
        Route::post('{conversation}/messages', MessageSendController::class);
        Route::post('{conversation}/messages/audio', MessageAudioController::class);
        Route::put('{conversation}/messages/{message}/read', [MessageReadController::class, 'markOne']);
        Route::put('{conversation}/messages/read-all', [MessageReadController::class, 'markAll']);

        // Typing indicator
        Route::post('{conversation}/typing', TypingController::class);
    });

    // ================================================================
    // ADMIN — admin-only endpoints
    // ================================================================
    Route::prefix('admin')->middleware(['auth:sanctum', 'role:admin'])->group(function () {
        Route::get('dashboard', AdminDashboardController::class);

        // Users
        Route::get('users', [AdminUserController::class, 'index']);
        Route::put('users/{user}/toggle', [AdminUserController::class, 'toggle']);

        // Experts
        Route::get('experts/pending', AdminExpertListController::class);
        Route::put('experts/{expert}/validate', AdminExpertValidateController::class);
        Route::put('experts/{expert}/reject', AdminExpertRejectController::class);

        // Conversations
        Route::get('conversations', AdminConversationController::class);

        // Payments
        Route::get('payments', AdminPaymentsController::class);

        // AI logs
        Route::get('ai-logs', [AdminAiLogController::class, 'index']);
        Route::get('ai-logs/stats', [AdminAiLogController::class, 'stats']);

        // Categories CRUD
        Route::get('categories', [AdminCategoryController::class, 'index']);
        Route::post('categories', [AdminCategoryController::class, 'store']);
        Route::put('categories/{category}', [AdminCategoryController::class, 'update']);
        Route::delete('categories/{category}', [AdminCategoryController::class, 'destroy']);

        // Knowledge base CRUD
        Route::get('knowledge', [AdminKnowledgeBaseController::class, 'index']);
        Route::post('knowledge', [AdminKnowledgeBaseController::class, 'store']);
        Route::put('knowledge/{knowledge}', [AdminKnowledgeBaseController::class, 'update']);
        Route::delete('knowledge/{knowledge}', [AdminKnowledgeBaseController::class, 'destroy']);
    });

    // ================================================================
    // AI CALLBACKS — called by n8n (validated by X-N8N-Secret header)
    // ================================================================
    Route::prefix('ai')->group(function () {
        Route::post('callback', AiCallbackController::class);
        Route::post('transcription-complete', TranscriptionCompleteController::class);
        Route::post('tts-complete', TtsCompleteController::class);
    });

    // ================================================================
    // PAYMENTS — authenticated + public webhooks
    // ================================================================
    Route::prefix('payments')->middleware('auth:sanctum')->group(function () {
        Route::post('stripe/intent', PaymentIntentController::class);
        Route::post('stripe/confirm', PaymentConfirmController::class);
        Route::post('cmi/initiate', CmiInitiateController::class);
        Route::get('history', PaymentHistoryController::class);
    });

    // CMI callback — public (server-to-server from CMI)
    Route::post('payments/cmi/callback', CmiCallbackController::class);

    // Stripe webhook — public (validated by signature)
    Route::post('webhooks/stripe', StripeWebhookController::class);
});
