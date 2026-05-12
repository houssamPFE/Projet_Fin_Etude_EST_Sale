<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\Storage;

class ExpertDocumentResource extends JsonResource
{
    private static function publicUrl(string $url): string
    {
        $internal = config('filesystems.disks.s3.endpoint');
        $public   = env('MINIO_PUBLIC_URL', $internal);

        if ($internal && $public && $public !== $internal) {
            $url = str_replace(rtrim($internal, '/'), rtrim($public, '/'), $url);
        }

        return $url;
    }

    public function toArray(Request $request): array
    {
        return [
            'id'            => $this->id,
            'type'          => $this->type->value,
            'file_url'      => $this->file_url,
            'stream_url'    => url("/api/v1/admin/documents/{$this->id}/stream"),
            'original_name' => $this->original_name,
            'verified'      => $this->verified,
            'created_at'    => $this->created_at->toISOString(),
        ];
    }
}
