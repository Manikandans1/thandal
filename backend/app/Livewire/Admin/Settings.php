<?php

namespace App\Livewire\Admin;

use App\Models\Setting;
use Livewire\Component;

class Settings extends Component
{
    public string $support_phone;
    public string $support_hours;
    public string $receipt_prefix;

    public function mount()
    {
        $this->support_phone = config('thandal.support_phone');
        $this->support_hours = config('thandal.support_hours');
        $this->receipt_prefix = config('thandal.receipt_prefix');
    }

    public function save()
    {
        foreach (['support_phone', 'support_hours', 'receipt_prefix'] as $key) {
            Setting::updateOrCreate(['setting_key' => $key], ['value' => $this->$key, 'updated_by' => auth()->id()]);
        }
        session()->flash('saved', true);
    }

    public function render()
    {
        return view('livewire.admin.settings')->layout('layouts.admin');
    }
}
