<?php

namespace App\Jobs;

use App\Models\Expert;
use App\Models\Review;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class UpdateExpertRatingJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 5;
    public int $backoff = 10;

    public function __construct(
        private int $expertId,
    ) {}

    public function handle(): void
    {
        $expert = Expert::find($this->expertId);

        if (! $expert) {
            Log::warning('[UpdateExpertRatingJob] Expert not found', ['expert_id' => $this->expertId]);
            return;
        }

        $stats = Review::where('expert_id', $this->expertId)
            ->selectRaw('ROUND(AVG(rating), 2) as avg_rating, COUNT(*) as total')
            ->first();

        $expert->update([
            'rating_avg'    => $stats->avg_rating ?? 0,
            'total_reviews' => $stats->total      ?? 0,
        ]);

        Log::info('[UpdateExpertRatingJob] Rating updated', [
            'expert_id'     => $this->expertId,
            'rating_avg'    => $stats->avg_rating ?? 0,
            'total_reviews' => $stats->total      ?? 0,
        ]);
    }

    public function failed(\Throwable $e): void
    {
        Log::error('[UpdateExpertRatingJob] Failed', [
            'expert_id' => $this->expertId,
            'error'     => $e->getMessage(),
        ]);
    }
}
