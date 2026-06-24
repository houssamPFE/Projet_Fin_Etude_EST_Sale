<?php

namespace App\Http\Requests\Api\V1\Expert;

use App\Enums\DocumentType;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class ApplyExpertRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'category_id'    => ['required', 'exists:categories,id'],
            'bio'            => ['nullable', 'string', 'max:2000'],
            'city'           => ['nullable', 'string', 'max:100'],
            'certifications' => ['nullable', 'array'],

            // Documents (at least one required — ID card)
            'documents'        => ['required', 'array', 'min:1', 'max:10'],
            'documents.*.file' => ['required', 'file', 'mimes:pdf,jpg,jpeg,png', 'max:5120'], // 5MB
            'documents.*.type' => ['required', 'string', Rule::in(array_column(DocumentType::cases(), 'value'))],
        ];
    }

    public function messages(): array
    {
        return [
            'category_id.required'     => 'La catégorie est obligatoire.',
            'category_id.exists'       => 'La catégorie sélectionnée est invalide.',
            'documents.required'       => 'Au moins un document est obligatoire.',
            'documents.min'            => 'Au moins un document est obligatoire.',
            'documents.*.file.required' => 'Le fichier est obligatoire.',
            'documents.*.file.mimes'   => 'Le fichier doit être au format PDF, JPG ou PNG.',
            'documents.*.file.max'     => 'Le fichier ne doit pas dépasser 5 Mo.',
            'documents.*.type.required' => 'Le type de document est obligatoire.',
            'documents.*.type.in'      => 'Le type de document est invalide.',
            'bio.max'                  => 'La bio ne doit pas dépasser 2000 caractères.',
        ];
    }
}
