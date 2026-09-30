<?php

namespace App\Livewire\Admin\Agents;

use App\Services\PeopleService;
use Livewire\Component;
use Livewire\WithFileUploads;

class CreatePage extends Component
{
    use WithFileUploads;

    public string $name = '';
    public string $mobile = '';
    public string $address = '';
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
            'doc_type' => 'required|in:aadhaar_card,pan_card,voter_id,driving_licence,passport,ration_card',
            'id_number' => 'required|string|max:40',
            'document' => 'required|image|max:8192',
        ]);

        $result = $people->createAgent($data, auth()->user());
        $this->createdId = $result['agent']->agent_code;
        $this->createdPin = $result['pin'];
    }

    public function render()
    {
        return view('livewire.admin.agents.create-page')->layout('layouts.admin');
    }
}
