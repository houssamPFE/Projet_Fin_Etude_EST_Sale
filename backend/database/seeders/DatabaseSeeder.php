<?php

namespace Database\Seeders;

use App\Models\Category;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     * 
     * ONLY seeds medical specialties (categories).
     * All users must be created manually via API or CLI.
     */
    public function run(): void
    {
        $specialties = [
            ['name' => 'Médecine générale', 'slug' => 'medecine-generale', 'icon' => '🩺', 'description' => 'Consultations généralistes, prévention, suivi de routine'],
            ['name' => 'Pédiatrie',         'slug' => 'pediatrie',         'icon' => '👶', 'description' => 'Santé du nourrisson, de l\'enfant et de l\'adolescent'],
            ['name' => 'Cardiologie',       'slug' => 'cardiologie',       'icon' => '❤️', 'description' => 'Maladies du cœur et système cardiovasculaire'],
            ['name' => 'Dermatologie',      'slug' => 'dermatologie',      'icon' => '🧴', 'description' => 'Affections de la peau, des cheveux et des ongles'],
            ['name' => 'Gynécologie',       'slug' => 'gynecologie',       'icon' => '🌸', 'description' => 'Santé de la femme, suivi de grossesse, ménopause'],
            ['name' => 'Psychiatrie',       'slug' => 'psychiatrie',       'icon' => '🧠', 'description' => 'Santé mentale, anxiété, dépression, troubles du sommeil'],
            ['name' => 'Dentisterie',       'slug' => 'dentisterie',       'icon' => '🦷', 'description' => 'Soins dentaires, hygiène bucco-dentaire'],
            ['name' => 'Ophtalmologie',     'slug' => 'ophtalmologie',     'icon' => '👁️', 'description' => 'Santé visuelle, troubles de la vue'],
        ];

        foreach ($specialties as $i => $spec) {
            Category::firstOrCreate(
                ['slug' => $spec['slug']],
                array_merge($spec, ['sort_order' => $i, 'is_active' => true])
            );
        }
    }
}
