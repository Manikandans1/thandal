<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PaymentResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'receipt_number' => $this->receipt_number,
            'chit_code' => $this->chit->chit_code,
            'customer_name' => $this->customer->user->name,
            'method' => $this->method,
            'status' => $this->status,
            'amount_paise' => $this->effectiveAmountPaise(),
            'amount' => rupees($this->effectiveAmountPaise()),
            'paid_at' => $this->paid_at?->toIso8601String(),
            'collected_by' => $this->collectedByAgent?->user?->name,
            'customer_code' => $this->customer->customer_code,
            'chit_id' => $this->chit_id,
            'razorpay_payment_id' => $this->razorpay_payment_id,
            'allocations' => $this->allocations->where('amount_paise', '>', 0)->map(fn ($a) => [
                'sequence' => $a->installment->sequence,
                'due_date' => $a->installment->due_date->toDateString(),
                'amount_paise' => $a->amount_paise,
            ])->values(),
            'applied_to' => $this->allocations->where('amount_paise', '>', 0)->map(fn ($a) => $a->installment->due_date->format('M j'))->values(),
            'correction_status' => optional($this->correctionRequests->sortByDesc('id')->first())->status,
        ];
    }
}
