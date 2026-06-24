<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\SystemSetting;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Validation\Rule;

class AdminSystemSettingsController extends Controller
{
    /**
     * GET /api/v1/admin/settings
     * Returns all settings grouped by category, with metadata.
     */
    public function index(): JsonResponse
    {
        $settings = SystemSetting::orderBy('group')->orderBy('id')->get();

        $grouped = $settings->groupBy('group')->map(function ($items) {
            return $items->map(fn ($s) => [
                'key'         => $s->key,
                'value'       => $s->casted_value,
                'type'        => $s->type,
                'label'       => $s->label,
                'description' => $s->description,
            ])->values();
        });

        return response()->json([
            'data' => $grouped,
            'flat' => SystemSetting::allMap(),
        ]);
    }

    /**
     * PUT /api/v1/admin/settings
     * Bulk-update settings. Only existing keys are accepted.
     */
    public function update(Request $request): JsonResponse
    {
        $existingKeys = SystemSetting::pluck('type', 'key');

        $rules = [];
        foreach ($existingKeys as $key => $type) {
            $rules[$key] = match ($type) {
                'boolean' => 'boolean',
                'integer' => 'integer|min:0',
                'decimal' => 'numeric|min:0|max:1',
                default   => 'string|max:500',
            };
        }

        $validated = $request->validate($rules);

        foreach ($validated as $key => $value) {
            SystemSetting::set($key, $value);
        }

        // Flush cached values so changes take effect immediately.
        Cache::forget('sys:maintenance_mode');
        Cache::forget('sys:allow_registrations');

        return response()->json([
            'message' => 'Paramètres mis à jour.',
            'flat'    => SystemSetting::allMap(),
        ]);
    }
}
