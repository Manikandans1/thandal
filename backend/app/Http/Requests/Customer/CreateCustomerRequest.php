<?php

namespace App\Http\Requests\Customer;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/** Used by both the admin and the agent "create customer" screens. ID proof is required (functional spec §4.3). */
class CreateCustomerRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:120'],
            'mobile' => ['required', 'digits:10'],
            'address' => ['required', 'string'],
            'agent_id' => ['nullable', 'exists:agents,id'],
            'doc_type' => ['required', Rule::in(array_keys(config('thandal.document_types')))],
            'id_number' => ['required', 'string', 'max:40'],
            'document' => ['required', 'file', 'image', 'max:8192'],
        ];
    }
}
