<?php

namespace App\Http\Requests\Api\V1\Conversation;

use Illuminate\Foundation\Http\FormRequest;

class CreateConversationRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'category_id' => ['required', 'exists:categories,id'],
            'expert_id'   => ['nullable', 'exists:experts,id'],
            'title'       => ['nullable', 'string', 'max:255'],
            'message'     => ['nullable', 'string', 'max:5000'],
        ];
    }

    public function messages(): array
    {
        return [
            'category_id.required' => 'La catégorie est obligatoire.',
            'category_id.exists'   => 'La catégorie sélectionnée est invalide.',
            'message.required'     => 'Le message initial est obligatoire.',
            'message.max'          => 'Le message ne doit pas dépasser 5000 caractères.',
        ];
    }
}
