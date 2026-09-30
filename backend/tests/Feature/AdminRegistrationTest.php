<?php

namespace Tests\Feature;

use App\Models\User;
use App\Services\AdminRegistrationService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Validation\ValidationException;
use Tests\TestCase;

/** Covers acceptance checklist item 30: admin registration pending, approved and rejected. */
class AdminRegistrationTest extends TestCase
{
    use RefreshDatabase;

    /** @test */
    public function a_new_admin_is_pending_until_a_super_admin_approves(): void
    {
        $service = app(AdminRegistrationService::class);
        $pending = $service->register(['name' => 'Divya S', 'mobile' => '9500077788', 'pin' => '5566', 'pin_confirmation' => '5566']);
        $this->assertSame('pending', $pending->status);

        $super = User::factory()->create(['role' => 'super_admin']);
        $service->approve($pending, $super, 'Looks good');
        $this->assertSame('active', $pending->fresh()->status);
    }

    /** @test */
    public function rejecting_requires_a_note_and_the_super_admin_cannot_be_deactivated(): void
    {
        $service = app(AdminRegistrationService::class);
        $pending = $service->register(['name' => 'X', 'mobile' => '9500000002', 'pin' => '5566', 'pin_confirmation' => '5566']);
        $super = User::factory()->create(['role' => 'super_admin']);

        $this->expectException(ValidationException::class);
        $service->reject($pending, $super, '');
    }

    /** @test */
    public function the_super_admin_account_cannot_be_deactivated(): void
    {
        $service = app(AdminRegistrationService::class);
        $super = User::factory()->create(['role' => 'super_admin']);

        $this->expectException(ValidationException::class);
        $service->setActive($super, false, $super);
    }
}
