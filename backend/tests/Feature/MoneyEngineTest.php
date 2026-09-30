<?php

namespace Tests\Feature;

use App\Models\Agent;
use App\Models\Customer;
use App\Models\User;
use App\Services\ChitService;
use App\Services\PaymentService;
use App\Services\PeopleService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Validation\ValidationException;
use Tests\TestCase;

/**
 * Covers the acceptance checklist in docs/01-functional-spec.md §17, items 1-10 and 16.
 * Run with: php artisan test --filter=MoneyEngineTest  (needs a MySQL/MariaDB test database).
 */
class MoneyEngineTest extends TestCase
{
    use RefreshDatabase;

    protected User $admin;
    protected Agent $agent;
    protected Customer $customer;

    protected function setUp(): void
    {
        parent::setUp();
        $this->admin = User::factory()->create(['role' => 'super_admin']);
        $agentUser = User::factory()->create(['role' => 'agent', 'mobile' => '9841000001']);
        $this->agent = Agent::factory()->create(['user_id' => $agentUser->id]);
        $custUser = User::factory()->create(['role' => 'customer', 'mobile' => '9800000001']);
        $this->customer = Customer::factory()->create(['user_id' => $custUser->id, 'agent_id' => $this->agent->id]);
    }

    protected function makeActiveChit(array $overrides = [])
    {
        $chit = app(ChitService::class)->create(array_merge([
            'customer_id' => $this->customer->id,
            'loan_amount_paise' => 1000000,
            'frequency' => 'daily',
            'installment_count' => 100,
            'installment_amount_paise' => 12000,
            'start_date' => '2026-07-31',
        ], $overrides), $this->admin);

        app(ChitService::class)->recordDisbursement($chit, ['method' => 'cash', 'status' => 'completed', 'disbursed_on' => '2026-07-30'], $this->admin);

        return $chit->fresh();
    }

    /** @test */
    public function total_repayment_is_installment_amount_times_count(): void
    {
        $chit = $this->makeActiveChit();
        $this->assertSame(1200000, $chit->total_repayment_paise); // 12,000 * 100 = ₹12,000
    }

    /** @test */
    public function daily_schedule_has_the_right_number_of_rows_and_dates(): void
    {
        $chit = $this->makeActiveChit();
        $this->assertSame(100, $chit->installments()->count());
        $this->assertSame('2026-07-31', $chit->installments()->where('sequence', 1)->first()->due_date->toDateString());
        $this->assertSame('2026-11-07', $chit->installments()->where('sequence', 100)->first()->due_date->toDateString());
    }

    /** @test */
    public function monthly_schedule_clamps_to_the_last_day_of_short_months(): void
    {
        $chit = $this->makeActiveChit(['frequency' => 'monthly', 'installment_count' => 4, 'installment_amount_paise' => 300000, 'start_date' => '2026-01-31']);
        $dates = $chit->installments()->orderBy('sequence')->pluck('due_date')->map->toDateString();
        $this->assertSame(['2026-01-31', '2026-02-28', '2026-03-31', '2026-04-30'], $dates->all());
    }

    /** @test */
    public function customer_pays_exact_installment(): void
    {
        $chit = $this->makeActiveChit();
        $p = app(PaymentService::class)->collectCash($chit, $this->agent, 12000, 'req-1', $this->admin);
        $this->assertSame('confirmed', $p->status);
        $this->assertSame('paid', $chit->fresh()->installments()->where('sequence', 1)->first()->status);
    }

    /** @test */
    public function payment_is_allocated_oldest_first_with_partial_remainder(): void
    {
        $chit = $this->makeActiveChit();
        app(PaymentService::class)->collectCash($chit, $this->agent, 30000, 'req-2', $this->admin); // 300 -> 3 x 100 each? no: 12000 each -> covers inst 1 & 2 fully (24000) + 6000 partial on inst 3
        $chit->refresh();
        $rows = $chit->installments()->orderBy('sequence')->take(3)->get();
        $this->assertSame('paid', $rows[0]->status);
        $this->assertSame('paid', $rows[1]->status);
        $this->assertSame('partially_paid', $rows[2]->status);
        $this->assertSame(6000, $rows[2]->paid_paise);
    }

    /** @test */
    public function payment_larger_than_outstanding_is_rejected(): void
    {
        $chit = $this->makeActiveChit(['installment_count' => 2]);
        $this->expectException(ValidationException::class);
        app(PaymentService::class)->collectCash($chit, $this->agent, 999999999, 'req-3', $this->admin);
    }

    /** @test */
    public function double_submit_with_the_same_client_request_id_creates_one_payment(): void
    {
        $chit = $this->makeActiveChit();
        $service = app(PaymentService::class);
        $p1 = $service->collectCash($chit, $this->agent, 12000, 'same-key', $this->admin);
        $p2 = $service->collectCash($chit, $this->agent, 12000, 'same-key', $this->admin);
        $this->assertSame($p1->id, $p2->id);
        $this->assertSame(1, \App\Models\Payment::count());
    }

    /** @test */
    public function full_outstanding_payment_completes_the_chit(): void
    {
        $chit = $this->makeActiveChit(['installment_count' => 3]);
        $full = app(PaymentService::class)->fullOutstandingPaise($chit);
        $this->assertSame(36000, $full);
        app(PaymentService::class)->collectCash($chit, $this->agent, $full, 'req-close', $this->admin);
        $this->assertSame('completed', $chit->fresh()->status);
    }

    /** @test */
    public function overdue_installment_keeps_the_same_amount_no_penalty(): void
    {
        $chit = $this->makeActiveChit(['start_date' => now()->subDays(5)->toDateString()]);
        $row = $chit->installments()->where('sequence', 1)->first();
        $this->assertSame(12000, $row->amount_paise);
        $this->assertSame('overdue', $row->displayStatus());
    }

    /** @test */
    public function agent_cannot_collect_for_a_customer_that_is_not_theirs(): void
    {
        $otherAgentUser = User::factory()->create(['role' => 'agent', 'mobile' => '9841000099']);
        $otherAgent = Agent::factory()->create(['user_id' => $otherAgentUser->id]);
        $chit = $this->makeActiveChit();

        $this->expectException(ValidationException::class);
        app(PaymentService::class)->collectCash($chit, $otherAgent, 12000, 'req-x', $this->admin);
    }

    /** @test */
    public function agent_with_customers_cannot_be_deactivated(): void
    {
        $this->expectException(ValidationException::class);
        app(PeopleService::class)->deactivateAgent($this->agent, $this->admin);
    }
}
