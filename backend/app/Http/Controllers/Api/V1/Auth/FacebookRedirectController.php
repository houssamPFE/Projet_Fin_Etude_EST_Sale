<?php

namespace App\Http\Controllers\Api\V1\Auth;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Laravel\Socialite\Facades\Socialite;

class FacebookRedirectController extends Controller
{
    /**
     * Return the Facebook OAuth redirect URL.
     *
     * GET /api/v1/auth/facebook/redirect
     */
    public function __invoke(): JsonResponse
    {
        $url = Socialite::driver('facebook')
            ->stateless()
            ->scopes(['public_profile', 'email'])
            ->redirect()
            ->getTargetUrl();

        return response()->json(['url' => $url]);
    }
}
