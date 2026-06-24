<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'postmark' => [
        'key' => env('POSTMARK_API_KEY'),
    ],

    'resend' => [
        'key' => env('RESEND_API_KEY'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env('SLACK_BOT_USER_OAUTH_TOKEN'),
            'channel' => env('SLACK_BOT_USER_DEFAULT_CHANNEL'),
        ],
    ],

    'google' => [
        'client_id'     => env('GOOGLE_CLIENT_ID'),
        'client_secret' => env('GOOGLE_CLIENT_SECRET'),
        'redirect'      => env('GOOGLE_REDIRECT_URL'),
    ],

    'facebook' => [
        'client_id'     => env('FACEBOOK_CLIENT_ID'),
        'client_secret' => env('FACEBOOK_CLIENT_SECRET'),
        'redirect'      => env('FACEBOOK_REDIRECT_URL'),
    ],

    'n8n' => [
        'base_url'  => env('N8N_BASE_URL'),
        'secret'    => env('N8N_SECRET'),
        'webhooks'  => [
            'analyze'    => env('N8N_WEBHOOK_ANALYZE'),
            'moderate'   => env('N8N_WEBHOOK_MODERATE'),
            'summarize'  => env('N8N_WEBHOOK_SUMMARIZE'),
            'transcribe' => env('N8N_WEBHOOK_TRANSCRIBE', '/webhook/transcribe-audio'),
            'tts'        => env('N8N_WEBHOOK_TTS', '/webhook/text-to-speech'),
        ],
    ],

    'openai' => [
        'api_key'         => env('OPENAI_API_KEY'),
        'model'           => env('OPENAI_MODEL', 'gpt-4o'),
        'whisper_model'   => env('OPENAI_WHISPER_MODEL', 'whisper-1'),
        'embedding_model' => env('OPENAI_EMBEDDING_MODEL', 'text-embedding-3-small'),
    ],

    'qdrant' => [
        'host'        => env('QDRANT_HOST', 'http://qdrant:6333'),
        'collection'  => env('QDRANT_COLLECTION', 'nexora_knowledge'),
        'vector_size' => 1536,
    ],

    'elevenlabs' => [
        'api_key'     => env('ELEVENLABS_API_KEY'),
        'voice_id_fr' => env('ELEVENLABS_VOICE_ID_FR'),
        'voice_id_ar' => env('ELEVENLABS_VOICE_ID_AR'),
    ],

    'stripe' => [
        'key'            => env('STRIPE_KEY'),
        'secret'         => env('STRIPE_SECRET'),
        'webhook_secret' => env('STRIPE_WEBHOOK_SECRET'),
    ],

    'cmi' => [
        'merchant_id' => env('CMI_MERCHANT_ID'),
        'store_key'   => env('CMI_STORE_KEY'),
        'base_url'    => env('CMI_BASE_URL'),
    ],

    'fcm' => [
        'server_key' => env('FCM_SERVER_KEY'),
        'endpoint'   => 'https://fcm.googleapis.com/fcm/send',
    ],

];
