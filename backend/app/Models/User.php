<?php

namespace App\Models;

use App\Enums\Role;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasFactory, Notifiable, HasApiTokens;

    protected $fillable = [
        'name',
        'email',
        'phone',
        'password',
        'role',
        'avatar_url',
        'language',
        'email_verified_at',
        'is_active',
        'google_id',
        'facebook_id',
        'two_factor_secret',
        'two_factor_confirmed_at',
        'require_2fa',
        'fcm_token',
        'last_seen_at',
        'is_online_visible',
        'last_activity_at',
        'last_activity_type',
        'plan',
        'consultation_credits',
        'plan_expires_at',
    ];

    protected $hidden = ['password', 'remember_token', 'two_factor_secret'];

    protected function casts(): array
    {
        return [
            'email_verified_at'      => 'datetime',
            'two_factor_confirmed_at'=> 'datetime',
            'last_seen_at'           => 'datetime',
            'last_activity_at'       => 'datetime',
            'password'               => 'hashed',
            'is_active'              => 'boolean',
            'is_online_visible'      => 'boolean',
            'role'                   => Role::class,
            'plan_expires_at'        => 'datetime',
            'consultation_credits'   => 'integer',
        ];
    }

    public function isPro(): bool
    {
        return $this->plan === 'pro' && $this->plan_expires_at?->isFuture();
    }

    public function isPremium(): bool
    {
        return $this->plan === 'premium' && $this->plan_expires_at?->isFuture();
    }

    public function hasPaidPlan(): bool
    {
        return $this->isPro() || $this->isPremium();
    }

    public function hasCredits(): bool
    {
        return $this->consultation_credits > 0;
    }

    public function canConsult(): bool
    {
        return $this->hasPaidPlan() && $this->hasCredits();
    }

    public function isAdmin(): bool
    {
        return $this->role === Role::Admin;
    }

    public function isExpert(): bool
    {
        return $this->role === Role::Expert;
    }

    public function hasRole(Role $role): bool
    {
        return $this->role === $role;
    }

    public function expert(): HasOne
    {
        return $this->hasOne(Expert::class);
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

    public function otpCodes(): HasMany
    {
        return $this->hasMany(OtpCode::class);
    }

    public function notifications(): HasMany
    {
        return $this->hasMany(Notification::class);
    }
}
