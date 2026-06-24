<?php

namespace App\Http\Requests\Api\V1\Admin;

use Illuminate\Foundation\Http\FormRequest;

class AdminConversationCleanupRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->role === 'admin';
    }

    public function rules(): array
    {
        return [
            'age_days' => ['required', 'integer', 'in:30,90,180,365'],
            'state'    => ['required', 'string', 'in:closed,all'],
        ];
    }
}
