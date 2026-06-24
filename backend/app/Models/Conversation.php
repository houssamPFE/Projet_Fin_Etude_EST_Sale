<?php

namespace App\Models;

use App\Enums\ConversationChannel;
use App\Enums\ConversationStatus;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\SoftDeletes;

class Conversation extends Model
{
    use HasFactory, SoftDeletes;
    protected $fillable = [
        'user_id',
        'expert_id',
        'category_id',
        'status',
        'channel',
        'title',
        'rating',
        'summary',
        'closed_at',
    ];

    protected function casts(): array
    {
        return [
            'status' => ConversationStatus::class,
            'channel' => ConversationChannel::class,
            'closed_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function expert(): BelongsTo
    {
        return $this->belongsTo(Expert::class);
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }

    public function messages(): HasMany
    {
        return $this->hasMany(Message::class);
    }

    public function review(): HasOne
    {
        return $this->hasOne(Review::class);
    }

    public function payment(): HasOne
    {
        return $this->hasOne(Payment::class);
    }

    public function aiLogs(): HasMany
    {
        return $this->hasMany(AiLog::class);
    }

    public function lastMessage(): HasOne
    {
        return $this->hasOne(Message::class)->latestOfMany();
    }

    public function unreadMessages(): HasMany
    {
        return $this->hasMany(Message::class)->whereNull('read_at');
    }

    public function scopeOpen($query)
    {
        return $query->whereNotIn('status', [ConversationStatus::Closed->value]);
    }

    /**
     * Scope to get conversations for a user (as owner or assigned expert).
     */
    public function scopeForUser($query, User $user)
    {
        return $query->where(function ($q) use ($user) {
            $q->where('user_id', $user->id);

            if ($user->expert) {
                $q->orWhere('expert_id', $user->expert->id);
            }
        });
    }
}
