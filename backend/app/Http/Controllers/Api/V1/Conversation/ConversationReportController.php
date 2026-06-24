<?php

namespace App\Http\Controllers\Api\V1\Conversation;

use App\Models\Conversation;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Http\Request;
use Illuminate\Http\Response;

class ConversationReportController
{
    /**
     * Generate and download a PDF report for a closed consultation.
     *
     * GET /api/v1/conversations/{conversation}/report
     */
    public function __invoke(Request $request, Conversation $conversation): Response
    {
        // Only the patient or the assigned expert can download the report
        $user = $request->user();

        $isOwner  = $conversation->user_id === $user->id;
        $isExpert = $conversation->expert && $conversation->expert->user_id === $user->id;
        $isAdmin  = $user->role === 'admin';

        if (! $isOwner && ! $isExpert && ! $isAdmin) {
            abort(403, 'Accès refusé.');
        }

        // Load all relationships needed by the view
        $conversation->loadMissing([
            'user',
            'expert.user',
            'category',
            'messages',
        ]);

        $pdf = Pdf::loadView('pdf.consultation-report', compact('conversation'))
            ->setPaper('a4', 'portrait')
            ->setOptions([
                'defaultFont'     => 'DejaVu Sans',
                'isHtml5ParserEnabled' => true,
                'isRemoteEnabled' => false,
                'dpi'             => 96,
            ]);

        $filename = 'rapport-consultation-' . $conversation->id . '.pdf';

        return $pdf->download($filename);
    }
}
