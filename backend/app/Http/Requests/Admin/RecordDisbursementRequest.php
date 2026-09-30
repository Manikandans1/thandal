<?php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class RecordDisbursementRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'method' => ['required', Rule::in(['cash', 'bank_transfer'])],
            'status' => ['required', Rule::in(['completed', 'failed'])],
            'disbursed_on' => ['required', 'date'],
            'reference' => ['nullable', 'required_if:method,bank_transfer', 'string', 'max:60'],
            'note' => ['nullable', 'string', 'max:255'],
        ];
    }
}
