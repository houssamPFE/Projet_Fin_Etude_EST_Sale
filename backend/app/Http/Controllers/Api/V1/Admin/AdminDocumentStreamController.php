<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\ExpertDocument;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Storage;

class AdminDocumentStreamController extends Controller
{
    /**
     * GET /api/v1/admin/documents/{document}/stream
     * Serve an expert document through Laravel (bypasses MinIO internal hostname).
     * ?download=1 → Content-Disposition: attachment (force download).
     */
    public function __invoke(Request $request, ExpertDocument $document): Response
    {
        $contents = Storage::disk('s3')->get($document->file_url);

        abort_if($contents === null, 404, 'Fichier introuvable.');

        $mime        = Storage::disk('s3')->mimeType($document->file_url) ?: 'application/octet-stream';
        $disposition = $request->boolean('download') ? 'attachment' : 'inline';

        return response($contents, 200, [
            'Content-Type'        => $mime,
            'Content-Disposition' => "{$disposition}; filename=\"{$document->original_name}\"",
            'Cache-Control'       => 'private, max-age=3600',
        ]);
    }
}
