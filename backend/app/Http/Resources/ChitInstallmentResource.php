<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ChitInstallmentResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'sequence' => $this->sequence,
            'due_date' => $this->due_date->toDateString(),
            'amount_paise' => $this->amount_paise,
            'amount' => rupees($this->amount_paise),
            'paid_paise' => $this->paid_paise,
            'paid' => rupees($this->paid_paise),
            'remaining_paise' => $this->remainingPaise(),
            'status' => $this->displayStatus(), // upcoming|due_today|overdue|partially_paid|paid|cancelled
        ];
    }
}
