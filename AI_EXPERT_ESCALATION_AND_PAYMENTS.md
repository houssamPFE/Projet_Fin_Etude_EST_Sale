# Nexora AI, Expert Escalation, and Payments Notes

This file captures the product decisions discussed around AI triage, expert routing,
free tier, premium/subscription, and emergency behavior.

## Core Product Idea

Nexora has two levels:

- Level 1: AI assistant for triage, safe medical information, questions, and guidance.
- Level 2: Real validated doctors for paid/premium consultations.

The AI should feel intelligent and premium. It should not only answer text; it should
understand user intent and trigger useful actions such as showing available doctors,
asking if the user wants a doctor, or showing locked expert previews.

## Free Tier

Free users can:

- Chat with AI.
- Receive symptom triage.
- Get safe general medical information.
- Receive emergency guidance and SAMU 141 warnings.
- See doctor recommendations and available doctor previews.

Free users cannot:

- Start a real doctor consultation.
- Have an expert assigned to the same conversation.
- Use premium consultation credits.

If a free user asks something like:

> show me available cardiologists

The AI should not only say "Go Premium". It should:

1. Understand the intent: find available doctors.
2. Detect the specialty: cardiologie.
3. Ask the backend for available doctors.
4. Show locked expert cards with a lock icon.
5. Explain that expert consultations are included in Premium.
6. Show a `Go Premium` button.

Example AI response:

> I found available cardiologists for you. Expert consultations are included in Premium.

UI:

- Locked doctor cards:
  - Doctor name
  - Specialty
  - Rating
  - City
  - Availability
  - Price, optional
  - Lock icon
- Buttons:
  - `Go Premium`
  - `Continue with AI`

## Subscription Plans (FINAL — decided June 2026)

| Plan | Price | Consultations/month | Doctor earns/session | Nexora keeps |
|------|-------|--------------------|-----------------------|--------------|
| Free | 0 MAD | 0 | — | — |
| Pro | 249 MAD/month | 3 | 70 MAD | 39 MAD |
| Premium | 449 MAD/month | 6 | 70 MAD | 29 MAD |
| Extra | 89 MAD (one-time) | 1 | 70 MAD | 19 MAD |

### Plan rules
- Doctor always earns a flat **70 MAD per completed consultation**, regardless of which plan the patient is on.
- Subscription revenue goes to Nexora. Doctor payment comes from that pool per consultation completed.
- Users who run out of credits can buy extra consultations at 89 MAD each.
- Credits reset every month on renewal date.
- Unused credits do not roll over.

### Database fields needed on users table
- `plan` ENUM('free', 'pro', 'premium') DEFAULT 'free'
- `consultation_credits` INTEGER DEFAULT 0
- `plan_expires_at` TIMESTAMP NULLABLE

### Subscription flow
1. Patient selects Pro or Premium plan.
2. Patient pays via Stripe (international) or CMI (Morocco).
3. On payment success: set `plan`, set `consultation_credits` (3 or 6), set `plan_expires_at` to +30 days.
4. When patient starts a doctor consultation: check `consultation_credits > 0`, deduct 1 credit.
5. When credits = 0: show "Buy extra consultation" option (89 MAD).
6. On plan expiry: reset `plan` to 'free', reset `consultation_credits` to 0.

### Free vs paid gating
- Free users: AI chat only, see locked doctor cards, cannot start doctor consultations.
- Pro/Premium users: AI chat + unlocked doctor cards + can start consultations (if credits > 0).
- Both plans: same AI features, same emergency flow, same SAMU 141 warnings.

## Normal Consultation Flow

The AI should not instantly escalate normal cases to a doctor.

Better flow:

1. User describes symptoms.
2. AI triages and responds.
3. If a doctor opinion is recommended, AI asks:

   > Your situation deserves a doctor's opinion. Do you want me to search for an available specialist?

4. UI shows action buttons:
   - `Yes, find a doctor`
   - `No, continue with AI`

5. If user clicks yes, it should appear in the chat as if the user wrote yes.
6. Then:
   - If user is Premium: show unlocked available doctors.
   - If user is Free: show locked doctor cards + `Go Premium`.

## Emergency Flow

Emergency guidance must always be free.

If the AI detects emergency signs such as chest pain with breathing difficulty, stroke
signs, severe bleeding, loss of consciousness, suicidal ideation, or severe allergic
reaction:

1. Show emergency banner immediately:

   > Emergency detected. If symptoms worsen, call SAMU 141 or go to the nearest emergency department.

2. AI response should be short and action-oriented.
3. Nexora must not imply that it replaces ambulance, ER, or emergency services.
4. The AI can offer to search for available doctors, but expert connection still follows
   the subscription/payment rules unless the business later decides emergency handoff is free.

Recommended emergency wording:

> This may be urgent. Please call 141 or go to the nearest emergency department now. I can also look for a doctor available on Nexora, but do not wait for the app if symptoms are serious.

## Expert Escalation Rules

Escalation should mean:

> A doctor consultation is recommended or requested.

It should not always mean:

> Assign a doctor immediately for free.

Current desired logic:

1. AI detects specialty and urgency.
2. AI can recommend expert help.
3. Backend checks user access:
   - Premium with credit: expert can be assigned.
   - Free or no credits: show locked expert preview and premium gate.
4. Expert assignment happens only after access is valid.

Matching logic when assignment is allowed:

1. Prefer AI-suggested specialty.
2. Find validated + available expert with highest rating.
3. If no expert in suggested specialty, fall back to original category.
4. If emergency and no specialist is available, later we may allow fallback to any available validated doctor.
5. If no expert exists, keep conversation in AI mode instead of freezing it.

## AI / n8n Output Should Include Actions

n8n should not only return text. It should return structured intent and UI actions.

Example:

```json
{
  "language": "fr",
  "specialty": "cardiologie",
  "urgency_level": "moderate",
  "confidence": 0.86,
  "response": "Votre situation merite l'avis d'un cardiologue. Voulez-vous que je cherche un medecin disponible ?",
  "suggest_expert": true,
  "escalate": false,
  "actions": [
    {
      "type": "find_expert",
      "label": "Oui, chercher un medecin",
      "specialty": "cardiologie"
    },
    {
      "type": "continue_ai",
      "label": "Non, continuer avec l'IA"
    }
  ]
}
```

For free users after finding doctors:

```json
{
  "response": "J'ai trouve des cardiologues disponibles. Les consultations avec medecins sont incluses dans Premium.",
  "intent": "find_expert",
  "specialty": "cardiologie",
  "requires_premium": true,
  "actions": [
    {
      "type": "show_experts",
      "specialty": "cardiologie",
      "locked": true
    },
    {
      "type": "go_premium",
      "label": "Passer a Premium"
    }
  ]
}
```

## Payment / Subscription Timing

Do not build the full payment system before the AI workflows are stable.

Recommended implementation order:

1. Finish n8n workflow foundation:
   - triage
   - specialty classification
   - safe AI response
   - structured actions
   - emergency banner

2. Build expert preview:
   - AI can request available doctors
   - Free users see locked cards
   - Premium placeholder exists

3. Build subscription/payment:
   - Free vs Premium
   - monthly credits
   - Go Premium page
   - consume credit when expert chat starts

4. Polish:
   - invoices
   - expert wallet
   - admin payment analytics
   - mobile/web consistency

## Web and Mobile Consistency

The web app and mobile app must use the same backend state:

- Same user account.
- Same conversations endpoint.
- Same expert assignment rules.
- Same premium gates.
- Same locked/unlocked expert cards.

If conversations appear on web but not mobile for the same account, that is a bug to debug.
Likely causes:

- Mobile logged into a different account.
- Mobile token/cache stale.
- Mobile points to a different backend URL.
- Offline cache is showing old data.

Current local URLs:

- Web uses `/api/v1` proxied to `http://127.0.0.1:8000`.
- Mobile emulator uses `http://10.0.2.2:8000/api/v1`.

Both should hit the same backend in local development.
