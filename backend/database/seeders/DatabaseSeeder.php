<?php

namespace Database\Seeders;

use App\Models\Category;
use App\Models\Expert;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // ── Medical specialties (stored in `categories` table) ──────
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
            Category::create(array_merge($spec, ['sort_order' => $i, 'is_active' => true]));
        }

        $catIds = Category::pluck('id', 'slug');

        // ── Admin ────────────────────────────────────────────────────
        User::create([
            'name'              => 'Admin Nexora',
            'email'             => 'admin@nexora.ma',
            'password'          => Hash::make('password'),
            'role'              => 'admin',
            'email_verified_at' => now(),
            'is_active'         => true,
        ]);

        // ── Patients ─────────────────────────────────────────────────
        $patients = [
            ['name' => 'Houssam Fatih',  'email' => 'houssam@test.ma'],
            ['name' => 'Fatima Zahra',   'email' => 'fatima@test.ma'],
            ['name' => 'Youssef Alami',  'email' => 'youssef@test.ma'],
            ['name' => 'Nadia Benali',   'email' => 'nadia@test.ma'],
            ['name' => 'Omar Tahiri',    'email' => 'omar@test.ma'],
        ];

        foreach ($patients as $u) {
            User::create(array_merge($u, [
                'password'          => Hash::make('password'),
                'role'              => 'user',
                'email_verified_at' => now(),
                'is_active'         => true,
            ]));
        }

        // ── Validated doctors (one per specialty) ────────────────────
        $doctors = [
            [
                'name'          => 'Dr. Karim Bensouda',
                'email'         => 'karim.bensouda@nexora.ma',
                'specialty'     => 'medecine-generale',
                'bio'           => 'Médecin généraliste avec 15 ans d\'expérience. Spécialisé en médecine interne et prévention des maladies chroniques. Diplômé de la Faculté de Médecine de Casablanca.',
                'hourly_rate'   => 300,
                'rating_avg'    => 4.9,
                'total_reviews' => 128,
            ],
            [
                'name'          => 'Dr. Amina Berrada',
                'email'         => 'amina.berrada@nexora.ma',
                'specialty'     => 'pediatrie',
                'bio'           => 'Pédiatre avec 12 ans d\'expérience. Spécialisée dans le suivi de l\'enfant et les maladies infantiles. Diplômée de la Faculté de Médecine de Rabat.',
                'hourly_rate'   => 380,
                'rating_avg'    => 4.8,
                'total_reviews' => 95,
            ],
            [
                'name'          => 'Dr. Youssef Alaoui',
                'email'         => 'youssef.alaoui@nexora.ma',
                'specialty'     => 'cardiologie',
                'bio'           => 'Cardiologue interventionnel avec 18 ans de pratique. Expert en maladies cardiovasculaires et prévention cardiaque. Ancien chef de service au CHU de Casablanca.',
                'hourly_rate'   => 500,
                'rating_avg'    => 4.7,
                'total_reviews' => 74,
            ],
            [
                'name'          => 'Dr. Salma Idrissi',
                'email'         => 'salma.idrissi@nexora.ma',
                'specialty'     => 'dermatologie',
                'bio'           => 'Dermatologue spécialisée en dermatologie esthétique et pédiatrique. 10 ans d\'expérience à Marrakech. Diplômée de la Faculté de Médecine de Rabat.',
                'hourly_rate'   => 400,
                'rating_avg'    => 4.8,
                'total_reviews' => 62,
            ],
            [
                'name'          => 'Dr. Leila Chaoui',
                'email'         => 'leila.chaoui@nexora.ma',
                'specialty'     => 'gynecologie',
                'bio'           => 'Gynécologue-obstétricienne, 14 ans d\'expérience. Suivi de grossesse, planification familiale, ménopause. Diplômée de la Faculté de Médecine de Casablanca.',
                'hourly_rate'   => 450,
                'rating_avg'    => 4.9,
                'total_reviews' => 110,
            ],
            [
                'name'          => 'Dr. Mehdi Rahmani',
                'email'         => 'mehdi.rahmani@nexora.ma',
                'specialty'     => 'psychiatrie',
                'bio'           => 'Psychiatre spécialisé dans les troubles anxieux et la dépression. Approche cognitivo-comportementale. 11 ans d\'expérience à Rabat.',
                'hourly_rate'   => 420,
                'rating_avg'    => 4.7,
                'total_reviews' => 58,
            ],
            [
                'name'          => 'Dr. Hicham El Fassi',
                'email'         => 'hicham.elfassi@nexora.ma',
                'specialty'     => 'dentisterie',
                'bio'           => 'Chirurgien-dentiste, 9 ans de pratique. Soins conservateurs, prothèses, conseils d\'hygiène bucco-dentaire. Cabinet à Casablanca.',
                'hourly_rate'   => 280,
                'rating_avg'    => 4.6,
                'total_reviews' => 41,
            ],
            [
                'name'          => 'Dr. Nawal Tahiri',
                'email'         => 'nawal.tahiri@nexora.ma',
                'specialty'     => 'ophtalmologie',
                'bio'           => 'Ophtalmologue, 13 ans d\'expérience. Spécialisée en chirurgie de la cataracte et troubles de la réfraction. Diplômée de la Faculté de Médecine de Fès.',
                'hourly_rate'   => 460,
                'rating_avg'    => 4.8,
                'total_reviews' => 87,
            ],
        ];

        foreach ($doctors as $data) {
            $user = User::create([
                'name'              => $data['name'],
                'email'             => $data['email'],
                'password'          => Hash::make('password'),
                'role'              => 'expert',
                'email_verified_at' => now(),
                'is_active'         => true,
            ]);

            Expert::create([
                'user_id'        => $user->id,
                'category_id'    => $catIds[$data['specialty']],
                'bio'            => $data['bio'],
                'hourly_rate'    => $data['hourly_rate'],
                'rating_avg'     => $data['rating_avg'],
                'total_reviews'  => $data['total_reviews'],
                'is_available'   => true,
                'status'         => 'validated',
                'validated_at'   => now(),
                'certifications' => json_encode([
                    'Doctorat en médecine',
                    'Inscrit à l\'Ordre National des Médecins du Maroc',
                ]),
            ]);
        }

        // ── Pending doctor applications ──────────────────────────────
        $pending = [
            ['name' => 'Dr. Sara Fennich', 'email' => 'sara@nexora.ma',   'specialty' => 'medecine-generale'],
            ['name' => 'Dr. Khalid Tazi',  'email' => 'khalid@nexora.ma', 'specialty' => 'cardiologie'],
        ];

        foreach ($pending as $data) {
            $user = User::create([
                'name'              => $data['name'],
                'email'             => $data['email'],
                'password'          => Hash::make('password'),
                'role'              => 'expert',
                'email_verified_at' => now(),
                'is_active'         => true,
            ]);

            Expert::create([
                'user_id'       => $user->id,
                'category_id'   => $catIds[$data['specialty']],
                'bio'           => 'Dossier en cours de validation par l\'administration.',
                'hourly_rate'   => 300,
                'rating_avg'    => 0,
                'total_reviews' => 0,
                'is_available'  => false,
                'status'        => 'pending',
            ]);
        }

        // ── Knowledge base ───────────────────────────────────────────
        $this->call(KnowledgeBaseSeeder::class);
    }
}
