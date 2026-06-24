<?php

namespace App\Http\Requests\Api\V1\Expert;

use Illuminate\Foundation\Http\FormRequest;

class UpdateExpertProfileRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'bio'            => ['nullable', 'string', 'max:2000'],
            'city'           => ['nullable', 'string', 'max:100'],
            'certifications' => ['nullable', 'array'],
            'category_id'    => ['nullable', 'exists:categories,id'],
        ];
    }

    public function messages(): array
    {
        return [
            'category_id.exists'  => 'La catégorie sélectionnée est invalide.',
            'bio.max'             => 'La bio ne doit pas dépasser 2000 caractères.',
        ];
    }
}
