<?php

namespace App\Http\Requests\Api\V1\Conversation;

use Illuminate\Foundation\Http\FormRequest;

class SendFileRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'file' => [
                'required',
                'file',
                // Images: jpeg, png, gif, webp — Documents: pdf, doc, docx, xls, xlsx, txt
                'mimetypes:image/jpeg,image/png,image/gif,image/webp,'
                    . 'application/pdf,'
                    . 'application/msword,'
                    . 'application/vnd.openxmlformats-officedocument.wordprocessingml.document,'
                    . 'application/vnd.ms-excel,'
                    . 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet,'
                    . 'text/plain',
                'max:5120', // 5 MB
            ],
        ];
    }

    public function messages(): array
    {
        return [
            'file.required' => 'Le fichier est obligatoire.',
            'file.mimetypes' => 'Format accepté : image (JPEG, PNG, GIF, WEBP), PDF, Word, Excel ou texte.',
            'file.max'      => 'Le fichier ne doit pas dépasser 5 Mo.',
        ];
    }
}
