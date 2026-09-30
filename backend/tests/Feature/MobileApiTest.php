<?php

namespace Tests\Feature;

use App\Models\Agent;
use App\Models\Customer;
use App\Models\User;
use App\Services\ChitService;
use App\Services\PinService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/** The endpoints the Flutter app relies on: role scoping, list feeds, PIN reset, dashboards. */
class MobileApiTest extends TestCase
{
    use RefreshDatabase;

    protected User $admin;
    protected Agent $agentA;
    protected Agent $agentB;
    protected Customer $custA;
    protected Customer $custB;
    protected $chitA;

    protected function setUp(): void
    {
        parent::setUp();
        $this->admin = User::factory()->create(['role' => 'super_admin', 'mobile' => '9000000001']);
        [$this->agentA, $uA] = $this->makeAgent('9841000001', 'Agent A');
        [$this->agentB, $uB] = $this->makeAgent('9841000002', 'Agent B');
        $this->custA = $this->makeCustomer('9800000001', 'Anwar Basha', $this->agentA);
        $this->custB = $this->makeCustomer('9800000002', 'Balaji K', $this->agentB);
        $chits = app(ChitService::class);
        $this->chitA = $chits->create(['customer_id' => $this->custA->id, 'loan_amount_paise' => 1000000, 'frequency' => 'daily', 'installment_count' => 10, 'installment_amount_paise' => 12000, 'start_date' => now('Asia/Kolkata')->subDays(2)->toDateString()], $this->admin);
        $chits->recordDisbursement($this->chitA, ['method' => 'cash', 'status' => 'completed', 'disbursed_on' => now()->toDateString()], $this->admin);
    }

    protected function makeAgent(string $mobile, string $name): array
    {
        $u = User::factory()->create(['role' => 'agent', 'mobile' => $mobile, 'name' => $name]);

        return [Agent::factory()->create(['user_id' => $u->id]), $u];
    }

    protected function makeCustomer(string $mobile, string $name, Agent $agent): Customer
    {
        $u = User::factory()->create(['role' => 'customer', 'mobile' => $mobile, 'name' => $name]);

        return Customer::factory()->create(['user_id' => $u->id, 'agent_id' => $agent->id, 'created_by' => $this->admin->id]);
    }

    /** @test */
    public function agent_search_never_returns_another_agents_customers(): void
    {
        Sanctum::actingAs($this->agentA->user);
        $codeOfB = $this->custB->customer_code;

        $byCode = $this->getJson('/api/agent/customers?q='.$codeOfB)->assertOk()->json('data');
        $byName = $this->getJson('/api/agent/customers?q=Balaji')->assertOk()->json('data');

        $this->assertCount(0, $byCode, 'searching by another agent\'s customer code must not leak');
        $this->assertCount(0, $byName);
        $this->assertCount(1, $this->getJson('/api/agent/customers?q=Anwar')->json('data'));
    }

    /** @test */
    public function agent_portfolio_has_only_own_customers_with_schedule(): void
    {
        Sanctum::actingAs($this->agentA->user);
        $rows = $this->getJson('/api/agent/portfolio?schedules=1')->assertOk()->json();

        $this->assertCount(1, $rows);
        $this->assertSame('Anwar Basha', $rows[0]['name']);
        $this->assertCount(10, $rows[0]['chits'][0]['schedule']);
        $this->assertSame('overdue', $rows[0]['chits'][0]['schedule'][0]['status']);
        $this->assertGreaterThan(0, $rows[0]['overdue_paise']);
    }

    /** @test */
    public function cash_collection_flows_into_agent_history_and_customer_receipts(): void
    {
        Sanctum::actingAs($this->agentA->user);
        $this->postJson("/api/agent/chits/{$this->chitA->id}/collect-cash", ['amount' => 240, 'client_request_id' => 'r-1'])->assertCreated();
        // retrying with the same client_request_id must not double charge
        $this->postJson("/api/agent/chits/{$this->chitA->id}/collect-cash", ['amount' => 240, 'client_request_id' => 'r-1'])->assertCreated();

        $hist = $this->getJson('/api/agent/payments?range=today')->assertOk()->json();
        $this->assertCount(1, $hist);
        $this->assertSame(24000, $hist[0]['amount_paise']);
        $this->assertSame($this->custA->customer_code, $hist[0]['customer_code']);

        // agent B sees nothing of it
        Sanctum::actingAs($this->agentB->user);
        $this->assertCount(0, $this->getJson('/api/agent/payments')->json());

        // the customer sees the receipt on their chit, another customer gets 404
        Sanctum::actingAs($this->custA->user);
        $mine = $this->getJson("/api/customer/chits/{$this->chitA->id}/payments")->assertOk()->json();
        $this->assertCount(1, $mine);
        $this->assertSame([1, 2], array_column($mine[0]['allocations'], 'sequence'), 'structured allocations for the receipt');
        $chits = $this->getJson('/api/customer/chits')->assertOk()->json();
        $this->assertSame($this->agentA->user->name, $chits[0]['agent']['name'], 'customer sees who collects');
        Sanctum::actingAs($this->custB->user);
        $this->getJson("/api/customer/chits/{$this->chitA->id}/payments")->assertNotFound();
    }

    /** @test */
    public function agent_dashboard_expected_is_pending_plus_collected_toward_due(): void
    {
        Sanctum::actingAs($this->agentA->user);
        $before = $this->getJson('/api/agent/dashboard')->assertOk()->json();
        $this->postJson("/api/agent/chits/{$this->chitA->id}/collect-cash", ['amount' => 120, 'client_request_id' => 'r-2'])->assertCreated();
        $after = $this->getJson('/api/agent/dashboard')->json();

        $this->assertSame($before['expected_today'], $after['expected_today'], 'expected must not shrink while the agent collects');
        $this->assertNotSame($before['pending_today'], $after['pending_today']);
        $this->assertSame('₹120', $after['collected_today']);
        $this->assertGreaterThan(0, $after['percent_collected']);
        $this->assertSame(12000, $after['paise']['collected_today']);
        $this->assertSame($after['paise']['expected_today'], $after['paise']['pending_today'] + $after['paise']['collected_toward_due']);
    }

    /** @test */
    public function admin_lists_work_and_are_admin_only(): void
    {
        Sanctum::actingAs($this->admin);
        $this->assertCount(1, $this->getJson('/api/admin/chits')->assertOk()->json());
        $this->assertSame('Anwar Basha', $this->getJson('/api/admin/chits')->json('0.customer_name'));
        $this->getJson('/api/admin/payments')->assertOk();
        $this->assertNotEmpty($this->getJson('/api/admin/audit-logs')->assertOk()->json());
        $this->assertCount(2, $this->getJson('/api/admin/portfolio')->assertOk()->json());
        $agents = $this->getJson('/api/admin/agents')->assertOk()->json();
        $this->assertArrayHasKey('id', $agents[0]);
        $this->assertArrayHasKey('collected_today', $agents[0]);
        $this->getJson('/api/admin/dashboard')->assertOk()->assertJsonStructure(['expected_today', 'pending_today', 'collected_today', 'pending_corrections', 'pending_online_payments', 'pending_disbursements']);

        foreach (['/api/admin/chits', '/api/admin/payments', '/api/admin/audit-logs', '/api/admin/portfolio'] as $url) {
            Sanctum::actingAs($this->agentA->user);
            $this->getJson($url)->assertForbidden();
            Sanctum::actingAs($this->custA->user);
            $this->getJson($url)->assertForbidden();
        }
    }

    /** @test */
    public function admin_can_reset_a_pin_and_the_user_must_choose_a_new_one(): void
    {
        $pins = app(PinService::class);
        $this->custA->user->update(['pin_hash' => $pins->hash('4826')]);

        Sanctum::actingAs($this->admin);
        $res = $this->postJson("/api/admin/customers/{$this->custA->id}/reset-pin")->assertOk()->json();
        $this->assertMatchesRegularExpression('/^\d{4}$/', $res['pin']);

        $this->app['auth']->forgetGuards();
        $this->postJson('/api/auth/login', ['mobile' => '9800000001', 'pin' => '4826'])->assertStatus(422);
        $login = $this->postJson('/api/auth/login', ['mobile' => '9800000001', 'pin' => $res['pin']])->assertOk()->json();
        $this->assertTrue($login['must_change_pin']);

        // choosing the own PIN clears the flag; a weak PIN is refused
        $this->postJson('/api/auth/set-new-pin', ['mobile' => '9800000001', 'temporary_pin' => $res['pin'], 'pin' => '1234', 'pin_confirmation' => '1234'])->assertStatus(422);
        $this->postJson('/api/auth/set-new-pin', ['mobile' => '9800000001', 'temporary_pin' => $res['pin'], 'pin' => '7391', 'pin_confirmation' => '7391'])->assertOk();
        $this->assertFalse($this->postJson('/api/auth/login', ['mobile' => '9800000001', 'pin' => '7391'])->assertOk()->json('must_change_pin'));

        // agents and customers cannot reset PINs
        Sanctum::actingAs($this->agentA->user);
        $this->postJson("/api/admin/customers/{$this->custA->id}/reset-pin")->assertForbidden();
    }

    /** @test */
    public function admin_can_deactivate_and_reactivate_customers_and_agents(): void
    {
        Sanctum::actingAs($this->admin);
        // customer: inactive cannot log in, chits stay
        $this->postJson("/api/admin/customers/{$this->custB->id}/active", ['active' => false])->assertOk()->assertJsonPath('status', 'inactive');
        $this->app['auth']->forgetGuards();
        $this->postJson('/api/auth/login', ['mobile' => '9800000002', 'pin' => '1111'])->assertStatus(403);
        Sanctum::actingAs($this->admin);
        $this->postJson("/api/admin/customers/{$this->custB->id}/active", ['active' => true])->assertOk()->assertJsonPath('status', 'active');

        // agent with customers cannot be deactivated until they are transferred
        $this->postJson("/api/admin/agents/{$this->agentB->id}/active", ['active' => false])->assertStatus(422);
        $this->postJson("/api/admin/customers/{$this->custB->id}/transfer", ['agent_id' => $this->agentA->id])->assertOk();
        $this->postJson("/api/admin/agents/{$this->agentB->id}/active", ['active' => false])->assertOk()->assertJsonPath('status', 'inactive');
        $this->postJson("/api/admin/agents/{$this->agentB->id}/active", ['active' => true])->assertOk()->assertJsonPath('status', 'active');

        // agents cannot do this
        Sanctum::actingAs($this->agentA->user);
        $this->postJson("/api/admin/customers/{$this->custB->id}/active", ['active' => false])->assertForbidden();
    }

    /** @test */
    public function customer_dashboard_no_longer_errors(): void
    {
        Sanctum::actingAs($this->custA->user);
        $this->getJson('/api/customer/dashboard')->assertOk()->assertJsonPath('active_chits', 1);
    }
}
