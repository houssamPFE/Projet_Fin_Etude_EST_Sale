<?php

namespace App\Services;

use App\Enums\ExpertStatus;
use App\Enums\Role;
use App\Events\ExpertStatusChanged;
use App\Models\Expert;
use App\Models\ExpertDocument;
use App\Models\User;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class ExpertService
{
    public function __construct(
        private NotificationService $notificationService,
    ) {}
    /**
     * Process an expert application.
     * Creates the expert profile, uploads documents, and updates user role.
     */
    public function apply(User $user, array $data, array $documents = []): Expert
    {
        return DB::transaction(function () use ($user, $data, $documents) {
            $expert = Expert::create([
                'user_id'        => $user->id,
                'category_id'    => $data['category_id'],
                'bio'            => $data['bio'] ?? null,
                'city'           => $data['city'] ?? null,
                'certifications' => $data['certifications'] ?? null,
                'status'         => ExpertStatus::Pending,
            ]);

            // Upload documents
            foreach ($documents as $doc) {
                $this->uploadDocument($expert, $doc['file'], $doc['type']);
            }

            // Notify admins
            $admins = User::where('role', Role::Admin)->get();
            foreach ($admins as $admin) {
                $this->notificationService->newExpertApplication($admin, $user);
            }

            // Role upgrade is deferred until an admin validates the application.

            return $expert->load(['category', 'documents', 'user']);
        });
    }

    /**
     * Upload a single document for an expert.
     */
    public function uploadDocument(Expert $expert, UploadedFile $file, string $type): ExpertDocument
    {
        $path = $file->store(
            "experts/{$expert->id}/documents",
            's3'
        );

        return ExpertDocument::create([
            'expert_id'     => $expert->id,
            'type'          => $type,
            'file_url'      => $path,
            'original_name' => $file->getClientOriginalName(),
        ]);
    }

    /**
     * Delete an expert document from storage and database.
     */
    public function deleteDocument(ExpertDocument $document): void
    {
        Storage::disk('s3')->delete($document->file_url);
        $document->delete();
    }

    /**
     * Update expert profile information.
     */
    public function updateProfile(Expert $expert, array $data): Expert
    {
        $expert->update(array_filter([
            'bio'            => $data['bio'] ?? null,
            'city'           => $data['city'] ?? null,
            'certifications' => $data['certifications'] ?? null,
            'category_id'    => $data['category_id'] ?? null,
        ], fn ($value) => $value !== null));

        return $expert->fresh(['category', 'documents', 'user']);
    }

    /**
     * Toggle expert availability.
     */
    public function toggleAvailability(Expert $expert, bool $available): Expert
    {
        $expert->update(['is_available' => $available]);

        event(new ExpertStatusChanged($expert, $available));

        return $expert;
    }

    /**
     * Validate (approve) an expert application.
     */
    public function validate(Expert $expert, User $admin): Expert
    {
        $expert->update([
            'status'           => ExpertStatus::Validated,
            'validated_at'     => now(),
            'validated_by'     => $admin->id,
            'rejection_reason' => null,
        ]);

        $expert->documents()->update(['verified' => true]);

        $expert->user->update(['role' => Role::Expert]);

        $this->notificationService->expertValidated($expert->user);

        return $expert->fresh(['category', 'documents', 'user']);
    }

    /**
     * Reject an expert application.
     */
    public function reject(Expert $expert, User $admin, ?string $reason = null): Expert
    {
        $expert->update([
            'status'           => ExpertStatus::Rejected,
            'validated_at'     => now(),
            'validated_by'     => $admin->id,
            'rejection_reason' => $reason,
        ]);

        $expert->user->update(['role' => Role::User]);

        $this->notificationService->expertRejected($expert->user, $reason);

        return $expert->fresh(['category', 'documents', 'user']);
    }

    /**
     * Get expert dashboard statistics.
     */
    public function getDashboardStats(Expert $expert): array
    {
        return [
            'total_conversations' => $expert->conversations()->count(),
            'active_conversations' => $expert->conversations()->whereNull('closed_at')->count(),
            'total_reviews' => $expert->total_reviews,
            'rating_avg' => $expert->rating_avg,
            'wallet_balance' => $expert->wallet?->balance ?? '0.00',
            'total_earned' => $expert->wallet?->total_earned ?? '0.00',
            'is_available' => $expert->is_available,
            'status' => $expert->status->value,
        ];
    }
}
