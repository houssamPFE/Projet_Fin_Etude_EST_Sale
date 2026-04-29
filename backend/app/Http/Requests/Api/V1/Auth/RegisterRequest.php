<?php

namespace App\Http\Requests\Api\V1\Auth;

use Illuminate\Foundation\Http\FormRequest;

class RegisterRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'name'     => ['required', 'string', 'max:150'],
            'email'    => ['required', 'email', 'max:180', 'unique:users,email'],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
            'language' => ['sometimes', 'string', 'in:fr,ar'],
            'phone'    => ['sometimes', 'nullable', 'string', 'max:20', 'unique:users,phone'],
        ];
    }
}
