<?php

namespace App\Services;

use App\Enums\PaymentProvider;
use App\Enums\PaymentStatus;
use App\Enums\TransactionType;
use App\Jobs\GenerateInvoiceJob;
use App\Models\Expert;
use App\Models\Payment;
use App\Models\User;
use App\Models\Wallet;
use App\Models\WalletTransaction;
use Illuminate\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Stripe\StripeClient;

class PaymentService
{
    /**
     * Fixed payout to doctor per completed consultation.
     */
    public const DOCTOR_PAYOUT = 70.00; // MAD

    /**
     * Subscription plans.
     */
    public const PLANS = [
        'pro' => [
            'price'   => 249.00,
            'credits' => 3,
            'label'   => 'Pro',
        ],
        'premium' => [
            'price'   => 449.00,
            'credits' => 6,
            'label'   => 'Premium',
        ],
    ];

    /**
     * Extra consultation (one-time purchase).
     */
    public const EXTRA_CREDIT_PRICE = 89.00;

    private StripeClient $stripe;

    public function __construct()
    {
        $this->stripe = new StripeClient(config('services.stripe.secret'));
    }

    // ─────────────────────────────────────────────────────────────────────────
    // STRIPE
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Create a Stripe PaymentIntent for a plan or extra credit.
     * $type: 'pro' | 'premium' | 'extra'
     */
    public function createSubscriptionIntent(User $user, string $type): array
    {
        $amount = $this->getPriceForType($type);

        $intent = $this->stripe->paymentIntents->create([
            'amount'   => (int) ($amount * 100),
            'currency' => 'mad',
            'metadata' => [
                'user_id'      => $user->id,
                'payment_type' => $type,
            ],
        ]);

        Payment::create([
            'user_id'                  => $user->id,
            'expert_id'                => null,
            'conversation_id'          => null,
            'amount'                   => $amount,
            'currency'                 => 'MAD',
            'status'                   => PaymentStatus::Pending,
            'provider'                 => PaymentProvider::Stripe,
            'stripe_payment_intent_id' => $intent->id,
        ]);

        return [
            'client_secret' => $intent->client_secret,
            'amount'        => $amount,
            'type'          => $type,
        ];
    }

    /**
     * Confirm a Stripe payment and activate the plan.
     */
    public function confirmSubscription(string $paymentIntentId): Payment
    {
        $intent  = $this->stripe->paymentIntents->retrieve($paymentIntentId);
        $payment = Payment::where('stripe_payment_intent_id', $paymentIntentId)->firstOrFail();
        $type    = $intent->metadata->payment_type;

        if ($intent->status === 'succeeded') {
            $payment->update([
                'status'           => PaymentStatus::Completed,
                'stripe_charge_id' => $intent->latest_charge,
                'paid_at'          => now(),
            ]);

            $this->activatePlan($payment->user, $type);
            GenerateInvoiceJob::dispatch($payment);
        } else {
            $payment->update(['status' => PaymentStatus::Failed]);
        }

        return $payment->fresh();
    }

    /**
     * Handle Stripe webhook events.
     */
    public function handleWebhook(string $payload, string $signature): void
    {
        $event = \Stripe\Webhook::constructEvent(
            $payload,
            $signature,
            config('services.stripe.webhook_secret')
        );

        match ($event->type) {
            'payment_intent.succeeded'      => $this->confirmSubscription($event->data->object->id),
            'payment_intent.payment_failed' => $this->markFailed($event->data->object->id),
            default                         => null,
        };
    }

    // ─────────────────────────────────────────────────────────────────────────
    // CMI
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Initiate a CMI payment for a plan or extra credit.
     */
    public function initiateCmiSubscription(User $user, string $type): array
    {
        $amount  = $this->getPriceForType($type);
        $orderId = 'NX-' . strtoupper(substr(uniqid(), -8));

        Payment::create([
            'user_id'         => $user->id,
            'expert_id'       => null,
            'conversation_id' => null,
            'amount'          => $amount,
            'currency'        => 'MAD',
            'status'          => PaymentStatus::Pending,
            'provider'        => PaymentProvider::Cmi,
            'cmi_order_id'    => $orderId,
        ]);

        $params = [
            'clientid'    => config('services.cmi.merchant_id'),
            'amount'      => number_format($amount, 2, '.', ''),
            'oid'         => $orderId,
            'okUrl'       => config('app.frontend_url') . '/payment/success?type=' . $type,
            'failUrl'     => config('app.frontend_url') . '/payment/fail',
            'callbackUrl' => config('app.url') . '/api/v1/payments/cmi/callback',
            'currency'    => '504',
            'lang'        => 'fr',
            'rnd'         => time(),
            'storetype'   => '3D_PAY_HOSTING',
            'BillToName'  => $user->name,
        ];

        $hashStr        = implode('|', array_values($params));
        $params['hash'] = base64_encode(hash_hmac('sha512', $hashStr, config('services.cmi.store_key'), true));

        return [
            'cmi_url' => config('services.cmi.base_url'),
            'params'  => $params,
        ];
    }

    /**
     * Handle CMI server-to-server callback.
     */
    public function handleCmiCallback(array $data): string
    {
        $payment = Payment::where('cmi_order_id', $data['oid'] ?? '')->first();

        if (! $payment) {
            return 'ACTION=FAILURE';
        }

        $expectedHash = base64_encode(hash_hmac(
            'sha512',
            implode('|', [
                $data['clientid']       ?? '',
                $data['oid']            ?? '',
                $data['AuthCode']       ?? '',
                $data['ProcReturnCode'] ?? '',
                $data['Response']       ?? '',
                $data['mdStatus']       ?? '',
            ]),
            config('services.cmi.store_key'),
            true
        ));

        if (($data['HASH'] ?? '') !== $expectedHash) {
            Log::warning('[CMI] Hash mismatch', ['oid' => $data['oid']]);
            return 'ACTION=FAILURE';
        }

        if (($data['ProcReturnCode'] ?? '') === '00') {
            $payment->update([
                'status'  => PaymentStatus::Completed,
                'paid_at' => now(),
            ]);

            $type = $this->resolveTypeFromAmount((float) $payment->amount);
            $this->activatePlan($payment->user, $type);
            GenerateInvoiceJob::dispatch($payment);

            return 'ACTION=POSTAUTH';
        }

        $payment->update(['status' => PaymentStatus::Failed]);
        return 'ACTION=FAILURE';
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PLAN MANAGEMENT
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Activate or renew a plan for a user.
     */
    public function activatePlan(User $user, string $type): void
    {
        DB::transaction(function () use ($user, $type) {
            if ($type === 'extra') {
                $user->increment('consultation_credits');
                Log::info('[Payment] Extra credit added', ['user_id' => $user->id]);
                return;
            }

            $credits    = self::PLANS[$type]['credits'];
            $isRenewal  = $user->plan === $type && $user->plan_expires_at?->isFuture();

            // On renewal: stack credits. On new/upgrade: reset to plan credits.
            $newCredits = $isRenewal
                ? $user->consultation_credits + $credits
                : $credits;

            $user->update([
                'plan'                 => $type,
                'consultation_credits' => $newCredits,
                'plan_expires_at'      => now()->addDays(30),
            ]);

            Log::info('[Payment] Plan activated', [
                'user_id' => $user->id,
                'plan'    => $type,
                'credits' => $newCredits,
            ]);
        });
    }

    /**
     * Deduct 1 credit when a doctor consultation starts.
     * Returns false if user has no credits or no active plan.
     */
    public function consumeCredit(User $user): bool
    {
        if (! $user->canConsult()) {
            return false;
        }

        $user->decrement('consultation_credits');

        Log::info('[Payment] Credit consumed', [
            'user_id'           => $user->id,
            'credits_remaining' => $user->fresh()->consultation_credits,
        ]);

        return true;
    }

    /**
     * Credit 70 MAD to the doctor's wallet after a consultation completes.
     */
    public function creditDoctorWallet(Expert $expert, int $conversationId): void
    {
        DB::transaction(function () use ($expert, $conversationId) {
            $wallet = Wallet::firstOrCreate(
                ['expert_id' => $expert->id],
                ['balance' => 0, 'total_earned' => 0, 'total_withdrawn' => 0]
            );

            $wallet->increment('balance', self::DOCTOR_PAYOUT);
            $wallet->increment('total_earned', self::DOCTOR_PAYOUT);

            WalletTransaction::create([
                'wallet_id'   => $wallet->id,
                'type'        => TransactionType::Credit,
                'amount'      => self::DOCTOR_PAYOUT,
                'description' => "Consultation #{$conversationId}",
                'reference'   => "conv_{$conversationId}",
            ]);
        });
    }

    /**
     * Get paginated payment history for a user.
     */
    public function history(User $user): LengthAwarePaginator
    {
        return Payment::where('user_id', $user->id)
            ->with(['expert.user', 'conversation'])
            ->orderBy('created_at', 'desc')
            ->paginate(15);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // HELPERS
    // ─────────────────────────────────────────────────────────────────────────

    private function getPriceForType(string $type): float
    {
        return match ($type) {
            'pro'     => self::PLANS['pro']['price'],
            'premium' => self::PLANS['premium']['price'],
            'extra'   => self::EXTRA_CREDIT_PRICE,
            default   => throw new \InvalidArgumentException("Unknown plan type: {$type}"),
        };
    }

    private function resolveTypeFromAmount(float $amount): string
    {
        return match (true) {
            $amount == self::PLANS['pro']['price']     => 'pro',
            $amount == self::PLANS['premium']['price'] => 'premium',
            default                                    => 'extra',
        };
    }

    private function markFailed(string $paymentIntentId): void
    {
        Payment::where('stripe_payment_intent_id', $paymentIntentId)
            ->update(['status' => PaymentStatus::Failed]);
    }
}
