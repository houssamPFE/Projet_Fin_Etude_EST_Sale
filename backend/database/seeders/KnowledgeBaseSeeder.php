<?php

namespace Database\Seeders;

use App\Models\AiKnowledgeBase;
use App\Models\Category;
use Illuminate\Database\Seeder;

class KnowledgeBaseSeeder extends Seeder
{
    public function run(): void
    {
        $catIds = Category::pluck('id', 'slug');

        $entries = [
            // ── Médecine générale ────────────────────────────────────
            [
                'specialty' => 'medecine-generale',
                'fr' => [
                    'q' => 'Quels sont les symptômes courants de la grippe ?',
                    'a' => 'La grippe se manifeste généralement par une fièvre supérieure à 38°C, des courbatures, une fatigue intense, des maux de tête, une toux sèche et un mal de gorge. Les symptômes durent en moyenne 5 à 7 jours. Si la fièvre dépasse 39,5°C, persiste plus de 3 jours, ou s\'accompagne de difficultés respiratoires, consultez un médecin.',
                    'k' => ['grippe', 'fièvre', 'courbatures', 'toux'],
                ],
                'ar' => [
                    'q' => 'ما هي الأعراض الشائعة للأنفلونزا؟',
                    'a' => 'تتميز الأنفلونزا عادة بحمى تتجاوز 38 درجة مئوية، آلام في الجسم، تعب شديد، صداع، سعال جاف والتهاب في الحلق. تستمر الأعراض في المتوسط من 5 إلى 7 أيام. إذا تجاوزت الحمى 39.5 درجة أو استمرت أكثر من 3 أيام أو صاحبتها صعوبة في التنفس، استشر طبيبًا.',
                    'k' => ['أنفلونزا', 'حمى', 'سعال'],
                ],
            ],
            [
                'specialty' => 'medecine-generale',
                'fr' => [
                    'q' => 'À quelle fréquence faire un bilan de santé ?',
                    'a' => 'Un bilan de santé annuel est recommandé après 40 ans, et tous les 2-3 ans entre 25 et 40 ans en l\'absence de facteurs de risque. Il inclut généralement une prise de tension, un bilan sanguin (cholestérol, glycémie) et un examen clinique. Discutez avec votre médecin traitant pour un suivi personnalisé.',
                    'k' => ['bilan', 'check-up', 'prévention'],
                ],
            ],
            [
                'specialty' => 'medecine-generale',
                'fr' => [
                    'q' => 'Quand consulter pour un mal de tête ?',
                    'a' => 'Consultez en urgence si le mal de tête est brutal et très intense ("le pire de votre vie"), accompagné de fièvre, raideur de la nuque, troubles de la vue, faiblesse d\'un côté du corps ou confusion. Pour des maux de tête récurrents qui perturbent votre quotidien, prenez rendez-vous avec un médecin pour en chercher la cause.',
                    'k' => ['céphalée', 'migraine', 'mal de tête'],
                ],
            ],

            // ── Pédiatrie ────────────────────────────────────────────
            [
                'specialty' => 'pediatrie',
                'fr' => [
                    'q' => 'Quelle est la température normale d\'un nourrisson ?',
                    'a' => 'La température normale d\'un bébé se situe entre 36,5°C et 37,5°C (rectale). On parle de fièvre au-delà de 38°C. Chez un nourrisson de moins de 3 mois, toute fièvre nécessite une consultation médicale rapide. Au-delà de 3 mois, consultez si la fièvre dure plus de 48h ou s\'accompagne de signes inquiétants (refus de boire, somnolence, éruption).',
                    'k' => ['nourrisson', 'fièvre', 'bébé'],
                ],
                'ar' => [
                    'q' => 'ما هي درجة الحرارة الطبيعية للرضيع؟',
                    'a' => 'تتراوح درجة حرارة الرضيع الطبيعية بين 36.5 و37.5 درجة مئوية (شرجياً). تُعتبر حمى عندما تتجاوز 38 درجة. عند الرضع دون 3 أشهر، أي حمى تستوجب استشارة طبية عاجلة. بعد 3 أشهر، استشر إذا استمرت الحمى أكثر من 48 ساعة أو صاحبتها علامات مقلقة.',
                    'k' => ['رضيع', 'حمى', 'طفل'],
                ],
            ],
            [
                'specialty' => 'pediatrie',
                'fr' => [
                    'q' => 'Quel est le calendrier vaccinal au Maroc ?',
                    'a' => 'Le programme national d\'immunisation marocain inclut : BCG et hépatite B à la naissance ; pentavalent + polio + pneumocoque à 2, 3 et 4 mois ; rougeole-rubéole à 9 mois ; rappels à 18 mois et 5 ans. Un carnet de santé est remis à la naissance. Consultez un pédiatre pour valider le suivi de votre enfant.',
                    'k' => ['vaccin', 'immunisation', 'enfant'],
                ],
            ],
            [
                'specialty' => 'pediatrie',
                'fr' => [
                    'q' => 'Mon enfant ne mange pas, dois-je m\'inquiéter ?',
                    'a' => 'Une baisse temporaire d\'appétit chez un enfant en bonne santé, actif et qui prend du poids normalement n\'est généralement pas inquiétante. En revanche, si votre enfant perd du poids, est apathique, refuse de boire, ou si la baisse d\'appétit dure plus d\'une semaine, consultez un pédiatre.',
                    'k' => ['appétit', 'enfant', 'alimentation'],
                ],
            ],

            // ── Cardiologie ──────────────────────────────────────────
            [
                'specialty' => 'cardiologie',
                'fr' => [
                    'q' => 'Quels sont les signes d\'une crise cardiaque ?',
                    'a' => 'Les signes principaux : douleur ou oppression thoracique (souvent au centre, irradiant vers le bras gauche, la mâchoire ou le dos), essoufflement, sueurs froides, nausées, sensation d\'angoisse intense. Les symptômes peuvent être plus discrets chez la femme (fatigue inhabituelle, douleur dorsale). EN CAS DE SUSPICION : appelez immédiatement le SAMU au 141.',
                    'k' => ['infarctus', 'crise cardiaque', 'urgence', 'douleur thoracique'],
                ],
                'ar' => [
                    'q' => 'ما هي علامات النوبة القلبية؟',
                    'a' => 'العلامات الرئيسية: ألم أو ضغط في الصدر (غالبًا في الوسط، ينتشر إلى الذراع الأيسر أو الفك أو الظهر)، ضيق في التنفس، تعرق بارد، غثيان. عند الاشتباه، اتصل فورًا بالإسعاف على الرقم 141.',
                    'k' => ['نوبة قلبية', 'ألم الصدر', 'طوارئ'],
                ],
            ],
            [
                'specialty' => 'cardiologie',
                'fr' => [
                    'q' => 'Quelle est la tension artérielle normale ?',
                    'a' => 'Une tension considérée comme normale est inférieure à 120/80 mmHg. Entre 120-139/80-89 mmHg on parle de pré-hypertension. À partir de 140/90 mmHg mesuré à plusieurs reprises, il s\'agit d\'hypertension qui nécessite un suivi médical. Mesurez votre tension au calme, après 5 minutes de repos.',
                    'k' => ['tension', 'hypertension', 'pression artérielle'],
                ],
            ],

            // ── Dermatologie ─────────────────────────────────────────
            [
                'specialty' => 'dermatologie',
                'fr' => [
                    'q' => 'Comment reconnaître un grain de beauté suspect ?',
                    'a' => 'Utilisez la règle ABCDE : A = Asymétrie, B = Bords irréguliers, C = Couleur non homogène, D = Diamètre supérieur à 6 mm, E = Évolution (changement de taille, forme ou couleur). Si un grain de beauté présente l\'un de ces signes, consultez rapidement un dermatologue. Un examen annuel est recommandé pour les peaux à risque.',
                    'k' => ['grain de beauté', 'mélanome', 'peau'],
                ],
            ],
            [
                'specialty' => 'dermatologie',
                'fr' => [
                    'q' => 'Comment traiter l\'acné de l\'adolescent ?',
                    'a' => 'Une hygiène douce (nettoyage matin et soir avec un produit non agressif), éviter de toucher ou percer les boutons, et limiter le maquillage occlusif aident. Pour les formes modérées à sévères, des traitements locaux (peroxyde de benzoyle, rétinoïdes) ou oraux peuvent être prescrits par un dermatologue. Évitez l\'automédication.',
                    'k' => ['acné', 'adolescent', 'boutons'],
                ],
            ],

            // ── Gynécologie ──────────────────────────────────────────
            [
                'specialty' => 'gynecologie',
                'fr' => [
                    'q' => 'À quelle fréquence faire un frottis cervical ?',
                    'a' => 'Le frottis cervico-utérin est recommandé tous les 3 ans à partir de 25 ans, après 2 frottis normaux à un an d\'intervalle. Après 30 ans, un test HPV peut remplacer le frottis tous les 5 ans. Le dépistage s\'arrête généralement à 65 ans si les résultats antérieurs étaient normaux.',
                    'k' => ['frottis', 'dépistage', 'col de l\'utérus'],
                ],
            ],
            [
                'specialty' => 'gynecologie',
                'fr' => [
                    'q' => 'Quels signes de grossesse précoce ?',
                    'a' => 'Les premiers signes possibles : retard de règles, tension mammaire, nausées matinales, fatigue inhabituelle, envies fréquentes d\'uriner. Ces signes ne sont pas spécifiques. Un test de grossesse urinaire est fiable dès le premier jour de retard de règles. Consultez un gynécologue pour confirmer et démarrer le suivi.',
                    'k' => ['grossesse', 'symptômes', 'test'],
                ],
            ],

            // ── Psychiatrie ──────────────────────────────────────────
            [
                'specialty' => 'psychiatrie',
                'fr' => [
                    'q' => 'Comment reconnaître une dépression ?',
                    'a' => 'Une dépression se caractérise par une tristesse persistante (plus de 2 semaines), une perte d\'intérêt pour les activités habituelles, des troubles du sommeil et de l\'appétit, une fatigue, une sensation de dévalorisation. Si ces symptômes vous touchent, parlez-en à un médecin ou un psychiatre. La dépression se soigne. EN CAS DE PENSÉES SUICIDAIRES, appelez immédiatement SOS Détresse Maroc ou rendez-vous aux urgences.',
                    'k' => ['dépression', 'tristesse', 'santé mentale'],
                ],
                'ar' => [
                    'q' => 'كيف نتعرف على الاكتئاب؟',
                    'a' => 'يتميز الاكتئاب بحزن مستمر (أكثر من أسبوعين)، فقدان الاهتمام بالأنشطة المعتادة، اضطرابات النوم والشهية، تعب، وشعور بانعدام القيمة. إذا كنت تعاني من هذه الأعراض، تحدث إلى طبيب. الاكتئاب قابل للعلاج. في حالة الأفكار الانتحارية، اتصل فورًا بخدمة الطوارئ.',
                    'k' => ['اكتئاب', 'حزن', 'صحة نفسية'],
                ],
            ],
            [
                'specialty' => 'psychiatrie',
                'fr' => [
                    'q' => 'Comment gérer l\'anxiété au quotidien ?',
                    'a' => 'Quelques pistes : pratiquer la respiration abdominale (5 secondes inspirer, 5 secondes expirer), une activité physique régulière, limiter la caféine, maintenir un sommeil régulier, et tenir un journal des pensées anxieuses. Si l\'anxiété envahit votre quotidien, perturbe le sommeil ou s\'accompagne de crises de panique, consultez un psychiatre ou un psychologue.',
                    'k' => ['anxiété', 'stress', 'panique'],
                ],
            ],

            // ── Dentisterie ─────────────────────────────────────────
            [
                'specialty' => 'dentisterie',
                'fr' => [
                    'q' => 'À quelle fréquence aller chez le dentiste ?',
                    'a' => 'Une visite de contrôle tous les 6 à 12 mois est recommandée chez l\'adulte sans problème particulier. Pour les enfants, une visite annuelle dès l\'apparition des premières dents. Un détartrage est généralement conseillé une fois par an. Consultez plus tôt en cas de douleur, sensibilité, ou saignement gingival persistant.',
                    'k' => ['dentiste', 'contrôle', 'détartrage'],
                ],
            ],
            [
                'specialty' => 'dentisterie',
                'fr' => [
                    'q' => 'Comment soulager une rage de dents en attendant le rendez-vous ?',
                    'a' => 'En attendant le dentiste : un antalgique type paracétamol (en respectant la posologie), un bain de bouche tiède à l\'eau salée, éviter les aliments très chauds, très froids ou sucrés. NE PAS appliquer d\'aspirine directement sur la dent (brûlure de la gencive). Consultez rapidement, surtout si la douleur s\'accompagne de fièvre ou de gonflement.',
                    'k' => ['rage de dents', 'douleur dentaire', 'urgence'],
                ],
            ],

            // ── Ophtalmologie ───────────────────────────────────────
            [
                'specialty' => 'ophtalmologie',
                'fr' => [
                    'q' => 'Quand faire vérifier sa vue ?',
                    'a' => 'Un examen ophtalmologique est recommandé tous les 2 ans chez l\'adulte sans correction, et tous les ans chez les porteurs de lunettes ou lentilles. Après 50 ans, un dépistage annuel du glaucome et de la DMLA est conseillé. Chez l\'enfant, un examen vers 3 ans, puis avant l\'entrée à l\'école primaire.',
                    'k' => ['vue', 'examen', 'lunettes'],
                ],
            ],
            [
                'specialty' => 'ophtalmologie',
                'fr' => [
                    'q' => 'Que faire en cas d\'œil rouge ?',
                    'a' => 'Un œil rouge peut avoir de nombreuses causes : conjonctivite, sécheresse, corps étranger, allergie. Consultez en urgence si l\'œil rouge s\'accompagne de douleur intense, baisse de la vue, sensibilité à la lumière, ou suite à un traumatisme. Pour une simple irritation, des larmes artificielles peuvent soulager en attendant un avis médical.',
                    'k' => ['œil rouge', 'conjonctivite', 'irritation'],
                ],
            ],
        ];

        foreach ($entries as $entry) {
            // FR version (always present)
            AiKnowledgeBase::create([
                'category_id' => $catIds[$entry['specialty']] ?? null,
                'question'    => $entry['fr']['q'],
                'answer'      => $entry['fr']['a'],
                'keywords'    => $entry['fr']['k'],
                'language'    => 'fr',
                'is_active'   => true,
            ]);

            // AR version (only when provided)
            if (isset($entry['ar'])) {
                AiKnowledgeBase::create([
                    'category_id' => $catIds[$entry['specialty']] ?? null,
                    'question'    => $entry['ar']['q'],
                    'answer'      => $entry['ar']['a'],
                    'keywords'    => $entry['ar']['k'],
                    'language'    => 'ar',
                    'is_active'   => true,
                ]);
            }
        }
    }
}
