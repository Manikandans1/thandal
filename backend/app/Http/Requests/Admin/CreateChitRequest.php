<?php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/** Used by admin AND agent "create chit" screens. No interest, no penalty fields exist here on purpose. */
class CreateChitRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'customer_id' => ['required', 'exists:customers,id'],
            'loan_amount' => ['required', 'integer', 'min:1'],
            'frequency' => ['required', Rule::in(['daily', 'weekly', 'monthly'])],
            'installment_count' => ['required', 'integer', 'min:1'],
            'installment_amount' => ['required', 'integer', 'min:1'],
            'start_date' => ['required', 'date'],
            'agent_id' => ['nullable', 'exists:agents,id'],
            'notes' => ['nullable', 'string', 'max:1000'],
        ];
    }
}
