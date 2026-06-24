<?php

namespace App\Jobs;

use App\Models\User;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class SendPushNotificationJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public int $backoff = 30;

    /**
     * @param User   $user            Recipient
     * @param string $title           Notification title
     * @param string $body            Notification body
     * @param array  $data            Extra data payload (for deep linking)
     * @param bool   $highPriority    True for emergency / doctor assignment alerts
     */
    public function __construct(
        private User   $user,
        private string $title,
        private string $body,
        private array  $data = [],
        private bool   $highPriority = false,
    ) {}

    public function handle(): void
    {
        $token = $this->user->fcm_token;

        if (empty($token)) {
            // User hasn't registered a device token yet — skip silently
            return;
        }

        $serverKey = config('services.fcm.server_key');

        if (empty($serverKey)) {
            Log::warning('[FCM] FCM_SERVER_KEY not configured — push not sent.', [
                'user_id' => $this->user->id,
            ]);
            return;
        }

        $payload = [
            'to' => $token,

            // Visible notification (Android + iOS via APNs bridge)
            'notification' => [
                'title' => $this->title,
                'body'  => $this->body,
                'sound' => 'default',
                'badge' => 1,
            ],

            // Data payload — available even when app is in background/killed
            'data' => array_merge($this->data, [
                'title' => $this->title,
                'body'  => $this->body,
            ]),

            // Android-specific options
            'android' => [
                'priority' => $this->highPriority ? 'high' : 'normal',
                'notification' => [
                    'channel_id'    => $this->highPriority ? 'nexora_urgent' : 'nexora_default',
                    'click_action'  => 'FLUTTER_NOTIFICATION_CLICK',
                    'default_sound' => true,
                ],
            ],

            // iOS-specific options
            'apns' => [
                'headers' => [
                    'apns-priority' => $this->highPriority ? '10' : '5',
                ],
                'payload' => [
                    'aps' => [
                        'sound'             => 'default',
                        'content-available' => 1,
                    ],
                ],
            ],
        ];

        $response = Http::withHeaders([
            'Authorization' => 'key=' . $serverKey,
            'Content-Type'  => 'application/json',
        ])->post(config('services.fcm.endpoint'), $payload);

        if ($response->failed()) {
            Log::error('[FCM] Push failed', [
                'user_id' => $this->user->id,
                'status'  => $response->status(),
                'body'    => $response->body(),
            ]);

            // Re-queue on server errors (5xx); drop on client errors (4xx = bad token)
            if ($response->serverError()) {
                $this->release(60);
            }

            return;
        }

        $result = $response->json();

        // FCM returns success=0 when the token is invalid/expired
        if (isset($result['failure']) && $result['failure'] > 0) {
            $error = $result['results'][0]['error'] ?? 'unknown';

            Log::warning('[FCM] Token rejected', [
                'user_id' => $this->user->id,
                'error'   => $error,
            ]);

            // Stale token — clear it so we don't keep sending
            if (in_array($error, ['InvalidRegistration', 'NotRegistered', 'MismatchSenderId'])) {
                $this->user->updateQuietly(['fcm_token' => null]);
            }
        }
    }
}
