<?php

namespace App\Livewire\Admin\Reports;

use App\Models\Agent;
use App\Models\Chit;
use App\Models\Customer;
use App\Models\Payment;
use Livewire\Component;

/** All reports export as CSV/Excel via maatwebsite/excel — see app/Exports/ReportExport.php. */
class IndexPage extends Component
{
    public string $report = 'daily';

    protected function reports(): array
    {
        return [
            'daily' => 'Daily collection', 'agents' => 'Agent collection', 'customers' => 'Customer report',
            'payments' => 'Payment report', 'outstanding' => 'Outstanding', 'overdue' => 'Overdue report',
            'completed' => 'Completed accounts', 'cash' => 'Cash payments', 'razorpay' => 'Razorpay payments',
            'disbursements' => 'Disbursements',
        ];
    }

    public function render()
    {
        return view('livewire.admin.reports.index-page', ['reports' => $this->reports()])->layout('layouts.admin');
    }
}
