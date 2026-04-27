# Nexora

Plateforme de télémédecine SaaS qui met en relation des patients et des médecins
qualifiés, avec l'aide d'un assistant IA pour le tri initial et l'information.

Projet de fin d'études — EST Salé.

## Concept

Deux niveaux de réponse :

- **Niveau 1 — IA** : analyse la demande du patient, classe la spécialité médicale,
  évalue l'urgence et répond aux questions générales d'information.
- **Niveau 2 — Médecin** : si la confiance de l'IA est faible, si l'urgence est
  signalée, ou à la demande du patient, la conversation est escaladée au meilleur
  médecin disponible dans la spécialité.

L'IA ne pose **jamais** de diagnostic et ne prescrit **jamais** de traitement —
ces actes sont réservés aux médecins validés sur la plateforme.

## Spécialités couvertes

Médecine générale · Pédiatrie · Cardiologie · Dermatologie · Gynécologie ·
Psychiatrie · Dentisterie · Ophtalmologie

## Stack technique

| Couche | Technologies |
|---|---|
| Backend | Laravel 11, PHP 8.3, MySQL 8, Redis 7 |
| Authentification | Sanctum + JWT refresh, OAuth Google/Facebook, 2FA TOTP |
| Temps réel | Laravel Reverb (WebSocket) + Laravel Echo |
| IA | OpenAI GPT-4 orchestré via n8n |
| Audio | Whisper (transcription) + ElevenLabs (synthèse vocale) |
| RAG | Qdrant (base de données vectorielle) |
| Stockage | AWS S3 / MinIO en local |
| Paiement | Stripe + CMI (Maroc) |
| Frontend Web | React 18 + Vite + Tailwind |
| Mobile | Flutter |
| Infra | Docker Compose, GitHub Actions |

## Architecture

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  React SPA   │     │  Flutter App │     │ Admin Panel  │
└──────┬───────┘     └──────┬───────┘     └──────┬───────┘
       │                    │                    │
       └────────────────────┴────────────────────┘
                            │ HTTPS + WebSocket
                            ▼
                  ┌──────────────────────┐
                  │   Laravel API        │
                  │   (Sanctum + Reverb) │
                  └──────────┬───────────┘
                             │
        ┌────────────────────┼────────────────────┐
        ▼                    ▼                    ▼
   ┌─────────┐         ┌─────────┐         ┌────────────┐
   │  MySQL  │         │  Redis  │         │     n8n    │
   └─────────┘         │ (queue) │         │ (workflows)│
                       └─────────┘         └─────┬──────┘
                                                 │
                                  ┌──────────────┼──────────────┐
                                  ▼              ▼              ▼
                              ┌────────┐    ┌────────┐     ┌─────────┐
                              │ OpenAI │    │ Qdrant │     │   S3    │
                              └────────┘    └────────┘     └─────────┘
```

## Démarrage local

Pré-requis : Docker Desktop, Node 20+, Git.

```bash
# 1. Cloner le repo
git clone https://github.com/houssamPFE/Projet_Fin_Etude_EST_Sale.git nexora
cd nexora

# 2. Configurer les variables d'environnement
cp backend/.env.example backend/.env
cp frontend/.env.example frontend/.env

# 3. Démarrer les conteneurs
docker compose up -d

# 4. Installer les dépendances backend + générer la clé
docker compose exec app composer install
docker compose exec app php artisan key:generate

# 5. Migrer + seeder la base
docker compose exec app php artisan migrate:fresh --seed

# 6. Installer les dépendances frontend
cd frontend
npm install
npm run dev
```

L'application est accessible sur :

- Frontend : http://localhost:5173
- API : http://localhost:8000/api/v1
- Reverb (WebSocket) : ws://localhost:8080
- n8n : http://localhost:5678

## Comptes de test (après seed)

| Rôle | Email | Mot de passe |
|---|---|---|
| Admin | admin@nexora.ma | password |
| Patient | houssam@test.ma | password |
| Médecin (généraliste) | karim.bensouda@nexora.ma | password |
| Médecin (pédiatre) | amina.berrada@nexora.ma | password |

## Structure du projet

```
.
├── backend/          # Laravel 11 — API REST + WebSocket
│   ├── app/
│   ├── database/migrations
│   ├── database/seeders
│   └── routes/api.php
├── frontend/         # React + Vite — interface web
│   └── src/
├── docker-compose.yml
└── README.md
```

## Avertissement médical

Les informations fournies par l'assistant IA sont à titre informatif uniquement
et ne remplacent pas une consultation médicale. En cas d'urgence vitale, appelez
immédiatement le **SAMU au 141** ou rendez-vous aux urgences les plus proches.

## Équipe

Projet réalisé dans le cadre du PFE à l'EST Salé.
