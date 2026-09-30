<?php

namespace Database\Seeders;

use App\Models\Agent;
use App\Models\Chit;
use App\Models\Customer;
use App\Models\IdentityDocument;
use App\Models\User;
use App\Services\ChitService;
use App\Services\PinService;
use Illuminate\Database\Seeder;

/**
 * Demo data matching the approved UI prototypes (Ravi Kumar / THD-10245, Karthik R / AGT-007, ...)
 * so the app looks right the first time you run it. Run with: php artisan db:seed
 */
class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $pins = app(PinService::class);
        $chits = app(ChitService::class);

        $super = User::create(['role' => 'super_admin', 'name' => 'Super Admin', 'mobile' => '9000012345', 'pin_hash' => $pins->hash('1357'), 'status' => 'active']);
        User::create(['role' => 'admin', 'name' => 'Lavanya M', 'mobile' => '9840055512', 'pin_hash' => $pins->hash('2468'), 'status' => 'active', 'decided_by' => $super->id, 'decided_at' => now()]);

        $agentUser = User::create(['role' => 'agent', 'name' => 'Karthik R', 'mobile' => '9841022017', 'pin_hash' => $pins->hash('2580'), 'status' => 'active']);
        $agent = Agent::create(['user_id' => $agentUser->id, 'agent_code' => 'AGT-007', 'address' => '8, Rajaji Street, Gandhi Nagar', 'joined_on' => '2026-01-12']);
        IdentityDocument::create(['agent_id' => $agent->id, 'doc_type' => 'aadhaar_card', 'number_encrypted' => IdentityDocument::encryptNumber('123456785521'), 'number_last4' => '5521', 'file_path' => 'seed/placeholder.jpg', 'file_mime' => 'image/jpeg', 'file_size_bytes' => 1, 'is_current' => true, 'uploaded_by' => $super->id]);

        $custUser = User::create(['role' => 'customer', 'name' => 'Ravi Kumar', 'mobile' => '9876543210', 'pin_hash' => $pins->hash('4826'), 'status' => 'active']);
        $customer = Customer::create(['user_id' => $custUser->id, 'customer_code' => 'THD-10245', 'address' => '12, Gandhi Street, Periyar Nagar', 'agent_id' => $agent->id, 'joined_on' => '2026-07-28', 'created_by' => $super->id]);
        IdentityDocument::create(['customer_id' => $customer->id, 'doc_type' => 'aadhaar_card', 'number_encrypted' => IdentityDocument::encryptNumber('123412343000'), 'number_last4' => '3000', 'file_path' => 'seed/placeholder.jpg', 'file_mime' => 'image/jpeg', 'file_size_bytes' => 1, 'is_current' => true, 'uploaded_by' => $super->id]);

        \App\Models\AgentAssignment::create(['customer_id' => $customer->id, 'agent_id' => $agent->id, 'assigned_by' => $super->id, 'assigned_on' => '2026-07-28', 'reason' => 'First assignment', 'active_customer_id' => $customer->id]);

        // THD-1001: daily chit, 100 days, matches the prototype (loan 10,000, 120/day)
        $chit1 = $chits->create(['customer_id' => $customer->id, 'loan_amount_paise' => 1000000, 'frequency' => 'daily', 'installment_count' => 100, 'installment_amount_paise' => 12000, 'start_date' => '2026-07-31'], $super);
        $chits->recordDisbursement($chit1, ['method' => 'cash', 'status' => 'completed', 'disbursed_on' => '2026-07-30'], $super);

        // THD-1048: weekly chit (loan 20,000, 1,250/week x 20 weeks)
        $chit2 = $chits->create(['customer_id' => $customer->id, 'loan_amount_paise' => 2000000, 'frequency' => 'weekly', 'installment_count' => 20, 'installment_amount_paise' => 125000, 'start_date' => '2026-08-01'], $super);
        $chits->recordDisbursement($chit2, ['method' => 'bank_transfer', 'status' => 'completed', 'disbursed_on' => '2026-07-31', 'reference' => 'NEFT-48120'], $super);

        $this->command?->info('Seeded: Super Admin 9000012345/1357, Admin 9840055512/2468, Agent AGT-007 9841022017/2580, Customer THD-10245 9876543210/4826');
    }
}
