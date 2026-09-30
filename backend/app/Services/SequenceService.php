<?php

namespace App\Services;

use App\Models\Sequence;

/**
 * Hands out gap-free, never-repeating numbers (customer, chit, agent, receipt, correction).
 * Call inside a DB transaction; the counter row is locked with lockForUpdate() so two
 * concurrent requests can never receive the same number.
 */
class SequenceService
{
    protected function next(string $name, int $startAt): int
    {
        $row = Sequence::query()->lockForUpdate()->find($name);

        if (! $row) {
            // First use of this counter: create it, then re-lock to be safe under concurrency.
            Sequence::query()->firstOrCreate(['name' => $name], ['value' => $startAt - 1]);
            $row = Sequence::query()->lockForUpdate()->find($name);
        }

        $row->value = $row->value + 1;
        $row->save();

        return (int) $row->value;
    }

    public function nextCustomerCode(): string
    {
        $cfg = config('thandal.ids');

        return 'THD-'.$this->next('customer_code', $cfg['customer_start']);
    }

    public function nextChitCode(): string
    {
        $cfg = config('thandal.ids');

        return $cfg['chit_prefix'].$this->next('chit_code', $cfg['chit_start']);
    }

    public function nextAgentCode(): string
    {
        $cfg = config('thandal.ids');

        return $cfg['agent_prefix'].str_pad((string) $this->next('agent_code', $cfg['agent_start']), 3, '0', STR_PAD_LEFT);
    }

    public function nextReceiptNumber(): string
    {
        $prefix = config('thandal.receipt_prefix');

        return $prefix.'-'.str_pad((string) $this->next('receipt_number', 1), 6, '0', STR_PAD_LEFT);
    }

    public function nextCorrectionCode(): string
    {
        $cfg = config('thandal.ids');

        return $cfg['correction_prefix'].str_pad((string) $this->next('correction_code', $cfg['correction_start']), 3, '0', STR_PAD_LEFT);
    }
}
