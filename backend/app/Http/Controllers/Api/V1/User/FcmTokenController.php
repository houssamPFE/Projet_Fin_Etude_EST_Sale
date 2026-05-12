<?php

namespace App\Http\Controllers\Api\V1\User;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class FcmTokenController
{
    public function __invoke(Request $request): JsonResponse
    {
        $request->validate(['fcm_token' => 'required|string|max:500']);

        $request->user()->update(['fcm_token' => $request->fcm_token]);

        return response()->json(['message' => 'FCM token registered.']);
    }
}
