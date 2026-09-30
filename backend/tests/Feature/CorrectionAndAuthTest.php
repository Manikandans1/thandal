<?php

namespace Tests\Feature;

use App\Models\Agent;
use App\Models\Customer;
use App\Models\User;
use App\Services\ChitService;
use App\Services\CorrectionService;
use App\Services\PaymentService;
use App\Services\PinService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Validation\ValidationException;
use Tests\TestCase;

/** Covers acceptance checklist items 17-18 (corrections) and 28-29 (PIN lock/reset). */
class CorrectionAndAuthTest extends TestCase
{
    use RefreshDatabase;

    /** @test */
    public function a_correction_reduces_the_payment_and_the_chit_returns_to_active_if_it_had_completed(): void
    {
        $admin = User::factory()->create(['role' => 'super_admin']);
        $agentUser = User::factory()->create(['role' => 'agent']);
        $agent = Agent::factory()->create(['user_id' => $agentUser->id]);
        $custUser = User::factory()->create(['role' => 'customer']);
        $customer = Customer::factory()->create(['user_id' => $custUser->id, 'agent_id' => $agent->id]);

        $chit = app(ChitService::class)->create(['customer_id' => $customer->id, 'loan_amount_paise' => 100000, 'frequency' => 'daily', 'installment_count' => 1, 'installment_amount_paise' => 30000, 'start_date' => now()->toDateString()], $admin);
        app(ChitService::class)->recordDisbursement($chit, ['method' => 'cash', 'status' => 'completed', 'disbursed_on' => now()->toDateString()], $admin);

        $payment = app(PaymentService::class)->collectCash($chit, $agent, 30000, 'req-1', $admin);
        $this->assertSame('completed', $chit->fresh()->status);

        $cr = app(CorrectionService::class)->request($payment, $agent, 'wrong_amount', 20000, 'Customer actually paid 200', $admin);
        app(CorrectionService::class)->approve($cr, null, 'Verified with customer', $admin);

        $chit->refresh();
        $this->assertSame('active', $chit->status, 'A correction that lowers the amount reopens a completed chit');
        $this->assertSame(20000, $chit->paid_paise);
    }

    /** @test */
    public function rejecting_a_correction_requires_a_note(): void
    {
        $admin = User::factory()->create(['role' => 'super_admin']);
        $agentUser = User::factory()->create(['role' => 'agent']);
        $agent = Agent::factory()->create(['user_id' => $agentUser->id]);
        $custUser = User::factory()->create(['role' => 'customer']);
        $customer = Customer::factory()->create(['user_id' => $custUser->id, 'agent_id' => $agent->id]);
        $chit = app(ChitService::class)->create(['customer_id' => $customer->id, 'loan_amount_paise' => 100000, 'frequency' => 'daily', 'installment_count' => 5, 'installment_amount_paise' => 20000, 'start_date' => now()->toDateString()], $admin);
        app(ChitService::class)->recordDisbursement($chit, ['method' => 'cash', 'status' => 'completed', 'disbursed_on' => now()->toDateString()], $admin);
        $payment = app(PaymentService::class)->collectCash($chit, $agent, 20000, 'req-2', $admin);
        $cr = app(CorrectionService::class)->request($payment, $agent, 'duplicate_entry', null, 'Looks like a duplicate entry today', $admin);

        $this->expectException(ValidationException::class);
        app(CorrectionService::class)->reject($cr, '', $admin);
    }

    /** @test */
    public function three_wrong_pins_lock_the_account(): void
    {
        $pins = app(PinService::class);
        $user = User::factory()->create(['pin_hash' => $pins->hash('4826')]);

        $pins->attemptLogin($user, '0000');
        $pins->attemptLogin($user, '0000');
        $result = $pins->attemptLogin($user, '0000');

        $this->assertFalse($result['ok']);
        $this->assertTrue($user->fresh()->isLocked());

        $stillLocked = $pins->attemptLogin($user->fresh(), '4826');
        $this->assertFalse($stillLocked['ok'], 'Correct PIN is still rejected while locked');
    }

    /** @test */
    public function weak_and_repeated_pins_are_rejected(): void
    {
        $pins = app(PinService::class);
        $this->assertNotNull($pins->validateNewPin('0000'));
        $this->assertNotNull($pins->validateNewPin('1234'));
        $hash = $pins->hash('4826');
        $this->assertNotNull($pins->validateNewPin('4826', $hash));
        $this->assertNull($pins->validateNewPin('7391'));
    }
}
