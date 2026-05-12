<?php

namespace App\Models;

use App\Enums\ExpertStatus;
use App\Enums\Role;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Expert extends Model
{
    use HasFactory;
    protected $fillable = [
        'user_id',
        'category_id',
        'bio',
        'certifications',
        'hourly_rate',
        'rating_avg',
        'total_reviews',
        'is_available',
        'status',
        'validated_at',
        'validated_by',
    ];

    protected function casts(): array
    {
        return [
            'certifications' => 'array',
            'hourly_rate' => 'decimal:2',
            'rating_avg' => 'decimal:2',
            'is_available' => 'boolean',
            'status' => ExpertStatus::class,
            'validated_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }

    public function validatedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'validated_by');
    }

    public function documents(): HasMany
    {
        return $this->hasMany(ExpertDocument::class);
    }

    public function conversations(): HasMany
    {
        return $this->hasMany(Conversation::class);
    }

    public function reviews(): HasMany
    {
        return $this->hasMany(Review::class);
    }

    public function payments(): HasMany
    {
        return $this->hasMany(Payment::class);
    }

    public function wallet(): HasOne
    {
        return $this->hasOne(Wallet::class);
    }

    public function scopeValidated($query)
    {
        return $query->where('status', ExpertStatus::Validated->value)
                     ->whereHas('user', function ($q) {
                         $q->where('role', Role::Expert->value);
                     });
    }

    public function scopeAvailable($query)
    {
        return $query->where('is_available', true);
    }
}
