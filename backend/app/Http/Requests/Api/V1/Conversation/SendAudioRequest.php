<?php

namespace App\Http\Requests\Api\V1\Conversation;

use Illuminate\Foundation\Http\FormRequest;

class SendAudioRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'audio' => [
                'required',
                'file',
                // mimetypes checks the actual file content (finfo), not the extension.
                // M4A files are detected as audio/mp4 or video/mp4 depending on the OS/PHP version.
                // video/webm is included because PHP finfo often detects browser WebM
                // recordings (audio/webm;codecs=opus) as video/webm — same container.
                'mimetypes:audio/mp4,audio/x-m4a,video/mp4,audio/aac,audio/x-aac,audio/webm,video/webm,audio/ogg,video/ogg,audio/mpeg,audio/mp3,audio/wav,audio/x-wav,application/octet-stream',
                'max:10240', // 10 MB
            ],
        ];
    }

    public function messages(): array
    {
        return [
            'audio.required'   => 'Le fichier audio est obligatoire.',
            'audio.mimetypes'  => 'Le format audio doit être M4A, AAC, WebM, OGG, MP3 ou WAV.',
            'audio.max'        => 'Le fichier audio ne doit pas dépasser 10 Mo.',
        ];
    }
}
