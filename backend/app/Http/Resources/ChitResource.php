<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** Every amount is *_rupees (a formatted string) AND *_paise (an integer) so the app never has to convert. */
class ChitResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'chit_code' => $this->chit_code,
            'status' => $this->status,
            'loan_amount_paise' => $this->loan_amount_paise,
            'loan_amount' => rupees($this->loan_amount_paise),
            'frequency' => $this->frequency,
            'installment_count' => $this->installment_count,
            'installment_amount_paise' => $this->installment_amount_paise,
            'installment_amount' => rupees($this->installment_amount_paise),
            'total_repayment_paise' => $this->total_repayment_paise,
            'total_repayment' => rupees($this->total_repayment_paise),
            'paid_paise' => $this->paid_paise,
            'paid' => rupees($this->paid_paise),
            'paid_installments' => $this->paid_installments,
            'outstanding_paise' => $this->outstandingPaise(),
            'outstanding' => rupees($this->outstandingPaise()),
            'overdue_paise' => $this->overduePaise(),
            'overdue' => rupees($this->overduePaise()),
            'start_date' => $this->start_date->toDateString(),
            'end_date' => $this->end_date->toDateString(),
            'unit' => $this->unitLabel(false),
            'units' => $this->unitLabel(),
            'customer_name' => $this->whenLoaded('customer', fn () => $this->customer->user?->name),
            'customer_code' => $this->whenLoaded('customer', fn () => $this->customer->customer_code),
            'agent' => $this->whenLoaded('customer', fn () => $this->customer->relationLoaded('agent') && $this->customer->agent
                ? ['id' => $this->customer->agent->id, 'code' => $this->customer->agent->agent_code, 'name' => $this->customer->agent->user?->name]
                : null),
            'disbursement' => $this->whenLoaded('disbursement', fn () => $this->disbursement ? [
                'status' => $this->disbursement->status,
                'method' => $this->disbursement->method,
                'disbursed_on' => (string) $this->disbursement->disbursed_on,
                'reference' => $this->disbursement->reference,
            ] : null),
        ];
    }
}
