<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PaymentResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'                       => $this->id,
            'amount'                   => $this->amount,
            'currency'                 => $this->currency,
            'status'                   => $this->status->value,
            'provider'                 => $this->provider->value,
            'payment_type'             => $this->resolvePaymentType(),
            'stripe_payment_intent_id' => $this->stripe_payment_intent_id,
            'cmi_order_id'             => $this->cmi_order_id,
            'paid_at'                  => $this->paid_at?->toISOString(),
            'created_at'               => $this->created_at?->toISOString(),
            'user'                     => $this->whenLoaded('user', fn () => [
                'id'    => $this->user->id,
                'name'  => $this->user->name,
                'email' => $this->user->email,
                'plan'  => $this->user->plan ?? 'free',
            ]),
            'expert'                   => $this->whenLoaded('expert', fn () => [
                'id'   => $this->expert->id,
                'name' => $this->expert->user?->name,
            ]),
            'conversation_id'          => $this->conversation_id,
        ];
    }

    private function resolvePaymentType(): string
    {
        $amount = (float) $this->amount;
        return match (true) {
            $amount == 249.00 => 'pro',
            $amount == 449.00 => 'premium',
            $amount == 89.00  => 'extra',
            $amount == 70.00  => 'doctor_payout',
            default           => 'other',
        };
    }
}
