<?php

namespace App\Http\Middleware;

use App\Models\SystemSetting;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Symfony\Component\HttpFoundation\Response;

class CheckMaintenanceMode
{
    /**
     * Routes that must always stay reachable so admins can still log in.
     */
    private const EXEMPT = [
        'api/v1/auth/login',
        'api/v1/auth/refresh',
        'api/v1/auth/logout',
    ];

    public function handle(Request $request, Closure $next): Response
    {
        // Cache setting for 60 s to avoid a DB hit on every request.
        $inMaintenance = Cache::remember('sys:maintenance_mode', 60, function () {
            return SystemSetting::get('maintenance_mode', false);
        });

        if (! $inMaintenance) {
            return $next($request);
        }

        // Exempt critical auth endpoints.
        foreach (self::EXEMPT as $uri) {
            if ($request->is($uri)) {
                return $next($request);
            }
        }

        // Authenticated admins always bypass maintenance mode.
        $user = $request->user();
        if ($user && $user->role->value === 'admin') {
            return $next($request);
        }

        return response()->json([
            'message'     => 'La plateforme est en cours de maintenance. Veuillez réessayer dans quelques instants.',
            'maintenance' => true,
        ], 503);
    }
}
