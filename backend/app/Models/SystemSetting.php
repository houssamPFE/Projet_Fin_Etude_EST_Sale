<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SystemSetting extends Model
{
    protected $fillable = ['key', 'value', 'type', 'label', 'description', 'group'];

    /**
     * Cast the stored string value to its proper PHP type.
     */
    public function getCastedValueAttribute(): mixed
    {
        return match ($this->type) {
            'boolean' => filter_var($this->value, FILTER_VALIDATE_BOOLEAN),
            'integer' => (int) $this->value,
            'decimal' => (float) $this->value,
            default   => $this->value,
        };
    }

    /**
     * Get a setting value by key, with an optional default.
     */
    public static function get(string $key, mixed $default = null): mixed
    {
        $setting = static::where('key', $key)->first();

        return $setting ? $setting->casted_value : $default;
    }

    /**
     * Set a setting value by key.
     */
    public static function set(string $key, mixed $value): void
    {
        static::where('key', $key)->update([
            'value'      => is_bool($value) ? ($value ? 'true' : 'false') : (string) $value,
            'updated_at' => now(),
        ]);
    }

    /**
     * Return all settings as a flat key → casted-value map.
     */
    public static function allMap(): array
    {
        return static::all()->mapWithKeys(
            fn ($s) => [$s->key => $s->casted_value]
        )->toArray();
    }
}
