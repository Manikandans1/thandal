<?php

namespace App\Livewire\Admin\Customers;

use App\Models\Agent;
use App\Services\PeopleService;
use Livewire\Component;
use Livewire\WithFileUploads;

/** Mirrors the approved "Create customer" screen: name, mobile, address, agent, and ID proof (any one). */
class CreatePage extends Component
{
    use WithFileUploads;

    public string $name = '';
    public string $mobile = '';
    public string $address = '';
    public ?int $agent_id = null;
    public string $doc_type = '';
    public string $id_number = '';
    public $document;

    public ?string $createdId = null;
    public ?string $createdPin = null;

    public function save(PeopleService $people)
    {
        $data = $this->validate([
            'name' => 'required|string|max:120',
            'mobile' => 'required|digits:10',
            'address' => 'required|string',
            'agent_id' => 'nullable|exists:agents,id',
            'doc_type' => 'required|in:aadhaar_card,pan_card,voter_id,driving_licence,passport,ration_card',
            'id_number' => 'required|string|max:40',
            'document' => 'required|image|max:8192',
        ]);

        $result = $people->createCustomer($data, auth()->user());
        $this->createdId = $result['customer']->customer_code;
        $this->createdPin = $result['pin'];
    }

    public function render()
    {
        return view('livewire.admin.customers.create-page', ['agents' => Agent::with('user')->where('user_id', '!=', null)->get()])->layout('layouts.admin');
    }
}
