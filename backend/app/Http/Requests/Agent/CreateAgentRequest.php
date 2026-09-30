<?php

namespace App\Http\Requests\Agent;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class CreateAgentRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:120'],
            'mobile' => ['required', 'digits:10'],
            'address' => ['required', 'string'],
            'doc_type' => ['required', Rule::in(array_keys(config('thandal.document_types')))],
            'id_number' => ['required', 'string', 'max:40'],
            'document' => ['required', 'file', 'image', 'max:8192'],
        ];
    }
}
