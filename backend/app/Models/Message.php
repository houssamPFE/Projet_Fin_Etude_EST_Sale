<?php

namespace App\Models;

use App\Enums\MessageSenderType;
use App\Enums\MessageType;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class Message extends Model
{
    use HasFactory, SoftDeletes;
    protected $fillable = [
        'conversation_id',
        'sender_type',
        'sender_id',
        'type',
        'content',
        'media_url',
        'transcription',
        'metadata',
        'read_at',
    ];

    protected function casts(): array
    {
        return [
            'sender_type' => MessageSenderType::class,
            'type' => MessageType::class,
            'metadata' => 'array',
            'read_at' => 'datetime',
        ];
    }

    public function conversation(): BelongsTo
    {
        return $this->belongsTo(Conversation::class);
    }

    public function scopeUnread($query)
    {
        return $query->whereNull('read_at');
    }
}
