<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('system_settings', function (Blueprint $table) {
            $table->id();
            $table->string('key', 100)->unique();
            $table->text('value')->nullable();
            $table->string('type', 20)->default('boolean'); // boolean | string | integer | decimal
            $table->string('label', 255);
            $table->text('description')->nullable();
            $table->string('group', 50)->default('platform'); // platform | ai | security
            $table->timestamps();
        });

        // Seed default settings
        $defaults = [
            [
                'key'         => 'maintenance_mode',
                'value'       => 'false',
                'type'        => 'boolean',
                'label'       => 'Mode maintenance',
                'description' => 'Désactive l\'accès public à la plateforme. Les admins restent connectés.',
                'group'       => 'platform',
            ],
            [
                'key'         => 'allow_registrations',
                'value'       => 'true',
                'type'        => 'boolean',
                'label'       => 'Nouvelles inscriptions',
                'description' => 'Autoriser la création de nouveaux comptes utilisateurs.',
                'group'       => 'platform',
            ],
            [
                'key'         => 'ai_enabled',
                'value'       => 'true',
                'type'        => 'boolean',
                'label'       => 'Réponses IA activées',
                'description' => 'Active le traitement automatique des messages par l\'IA (GPT-4).',
                'group'       => 'ai',
            ],
            [
                'key'         => 'escalation_confidence_threshold',
                'value'       => '0.75',
                'type'        => 'decimal',
                'label'       => 'Seuil d\'escalade IA',
                'description' => 'Score de confiance minimum (0.0–1.0). En dessous, la conversation est escaladée vers un médecin.',
                'group'       => 'ai',
            ],
            [
                'key'         => 'tts_enabled',
                'value'       => 'true',
                'type'        => 'boolean',
                'label'       => 'Synthèse vocale (TTS)',
                'description' => 'Génère une réponse audio via ElevenLabs après chaque réponse IA.',
                'group'       => 'ai',
            ],
            [
                'key'         => 'require_2fa',
                'value'       => 'false',
                'type'        => 'boolean',
                'label'       => '2FA obligatoire',
                'description' => 'Force l\'authentification à deux facteurs pour tous les utilisateurs.',
                'group'       => 'security',
            ],
            [
                'key'         => 'require_doctor_2fa',
                'value'       => 'false',
                'type'        => 'boolean',
                'label'       => '2FA obligatoire pour les médecins',
                'description' => 'Force le 2FA uniquement pour les comptes médecins.',
                'group'       => 'security',
            ],
        ];

        foreach ($defaults as $setting) {
            DB::table('system_settings')->insert(array_merge($setting, [
                'created_at' => now(),
                'updated_at' => now(),
            ]));
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('system_settings');
    }
};
