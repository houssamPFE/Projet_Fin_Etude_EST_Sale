<?php

namespace App\Http\Requests\Api\V1\User;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateProfileRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name'              => ['sometimes', 'string', 'max:150'],
            'phone'             => ['sometimes', 'nullable', 'string', 'max:20', Rule::unique('users')->ignore($this->user()->id)],
            'language'          => ['sometimes', 'string', 'in:fr,ar'],
            'is_online_visible' => ['sometimes', 'boolean'],
        ];
    }
}
