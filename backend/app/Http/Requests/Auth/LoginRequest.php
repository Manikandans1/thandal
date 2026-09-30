<?php

namespace App\Http\Requests\Auth;

use Illuminate\Foundation\Http\FormRequest;

class LoginRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'mobile' => ['required', 'digits:10'],
            'pin' => ['required', 'digits:4'],
        ];
    }
}
