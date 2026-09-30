<?php

namespace App\Services;

use App\Models\Agent;
use App\Models\AgentAssignment;
use App\Models\Customer;
use App\Models\IdentityDocument;
use App\Models\User;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\ValidationException;

/**
 * Creating customers and agents (functional spec §4). Both require exactly one ID proof.
 * A customer created by an agent is auto-assigned to that agent.
 */
class PeopleService
{
    public function __construct(
        protected SequenceService $sequences,
        protected PinService $pins,
        protected AuditLogger $audit,
    ) {}

    /** @return array{customer: Customer, pin: string} */
    public function createCustomer(array $data, User $actor): array
    {
        $this->assertMobileFree($data['mobile']);
        $pin = $this->pins->generateTemporaryPin();

        return DB::transaction(function () use ($data, $actor, $pin) {
            $user = User::create([
                'role' => 'customer', 'name' => $data['name'], 'mobile' => $data['mobile'],
                'pin_hash' => $this->pins->hash($pin), 'status' => 'active', 'must_change_pin' => true,
                'created_by' => $actor->id,
            ]);

            $agentId = $data['agent_id'] ?? ($actor->agent?->id);

            $customer = Customer::create([
                'user_id' => $user->id,
                'customer_code' => $this->sequences->nextCustomerCode(),
                'address' => $data['address'],
                'agent_id' => $agentId,
                'joined_on' => now()->toDateString(),
                'created_by' => $actor->id,
            ]);

            $this->attachIdentityDocument($customer, null, $data, $actor);

            if ($agentId) {
                AgentAssignment::create([
                    'customer_id' => $customer->id, 'agent_id' => $agentId, 'assigned_by' => $actor->id,
                    'assigned_on' => now()->toDateString(), 'reason' => 'First assignment',
                    'active_customer_id' => $customer->id,
                ]);
            }

            $this->audit->log($actor, 'customer_created', 'customer', $customer->customer_code,
                "{$customer->user->name} added with {$data['doc_type']} on file");

            return ['customer' => $customer->fresh(), 'pin' => $pin];
        });
    }

    /** @return array{agent: Agent, pin: string} */
    public function createAgent(array $data, User $actor): array
    {
        $this->assertMobileFree($data['mobile']);
        $pin = $this->pins->generateTemporaryPin();

        return DB::transaction(function () use ($data, $actor, $pin) {
            $user = User::create([
                'role' => 'agent', 'name' => $data['name'], 'mobile' => $data['mobile'],
                'pin_hash' => $this->pins->hash($pin), 'status' => 'active', 'must_change_pin' => true,
                'created_by' => $actor->id,
            ]);

            $agent = Agent::create([
                'user_id' => $user->id,
                'agent_code' => $this->sequences->nextAgentCode(),
                'address' => $data['address'],
                'joined_on' => now()->toDateString(),
            ]);

            $this->attachIdentityDocument(null, $agent, $data, $actor);

            $this->audit->log($actor, 'agent_created', 'agent', $agent->agent_code, "{$agent->user->name} added with {$data['doc_type']} on file");

            return ['agent' => $agent->fresh(), 'pin' => $pin];
        });
    }

    public function transferAgent(Customer $customer, Agent $newAgent, string $reason, User $actor): void
    {
        DB::transaction(function () use ($customer, $newAgent, $reason, $actor) {
            $old = $customer->agent_id;

            AgentAssignment::where('customer_id', $customer->id)->whereNull('ended_on')
                ->update(['ended_on' => now()->toDateString(), 'active_customer_id' => null]);

            AgentAssignment::create([
                'customer_id' => $customer->id, 'agent_id' => $newAgent->id, 'assigned_by' => $actor->id,
                'assigned_on' => now()->toDateString(), 'reason' => $reason, 'active_customer_id' => $customer->id,
            ]);

            $customer->agent_id = $newAgent->id;
            $customer->save();

            $this->audit->log($actor, $old ? 'agent_transfer' : 'agent_assigned', 'customer', $customer->customer_code,
                ($old ? Agent::find($old)?->agent_code : 'none')." -> {$newAgent->agent_code}");
        });
    }

    /** Admin resets a customer's or agent's PIN: a new temporary PIN is shown once and must be changed at next login (spec 3.2). */
    public function resetPin(User $target, User $actor): string
    {
        if (! in_array($target->role, ['customer', 'agent'], true)) {
            throw ValidationException::withMessages(['user' => 'Only customer and agent PINs can be reset here.']);
        }
        $pin = $this->pins->generateTemporaryPin();
        $target->pin_hash = $this->pins->hash($pin);
        $target->must_change_pin = true;
        $target->failed_attempts = 0;
        $target->locked_until = null;
        $target->save();
        $target->tokens()->delete();
        $code = $target->role === 'customer' ? $target->customer?->customer_code : $target->agent?->agent_code;
        $this->audit->log($actor, 'pin_reset', $target->role, (string) $code, 'Temporary PIN issued');

        return $pin;
    }

    /** An agent can only be deactivated once they have no current customers (functional spec §4.2). */
    public function deactivateAgent(Agent $agent, User $actor): void
    {
        if ($agent->customers()->count() > 0) {
            throw ValidationException::withMessages(['agent' => 'Transfer all customers to another agent before deactivating.']);
        }
        $agent->user->status = 'inactive';
        $agent->user->save();
        $this->audit->log($actor, 'agent_deactivated', 'agent', $agent->agent_code, 'Status changed');
    }

    /**
     * Activate / deactivate a customer or an agent (functional spec 4.1, 4.2).
     * Inactive customers cannot log in but their chits continue; an agent with customers cannot be deactivated.
     */
    public function setActive(User $target, bool $active, User $actor): void
    {
        if ($target->role === 'agent' && ! $active) {
            $agent = $target->agent;
            if ($agent && $agent->customers()->count() > 0) {
                throw ValidationException::withMessages(['agent' => 'Transfer all customers to another agent before deactivating.']);
            }
        }
        if (! in_array($target->role, ['customer', 'agent'], true)) {
            throw ValidationException::withMessages(['user' => 'Only customers and agents can be changed here.']);
        }
        $target->status = $active ? 'active' : 'inactive';
        $target->save();
        if (! $active) {
            $target->tokens()->delete(); // signs them out of every device
        }
        $code = $target->role === 'customer' ? $target->customer?->customer_code : $target->agent?->agent_code;
        $this->audit->log($actor, $target->role.($active ? '_activated' : '_deactivated'), $target->role, (string) $code, 'Status changed');
    }

    protected function attachIdentityDocument(?Customer $customer, ?Agent $agent, array $data, User $actor): void
    {
        /** @var UploadedFile $file */
        $file = $data['document'];
        $path = $file->store('id-proofs', ['disk' => 'private']);
        $number = preg_replace('/\s+/', '', (string) $data['id_number']);

        IdentityDocument::create([
            'customer_id' => $customer?->id, 'agent_id' => $agent?->id,
            'doc_type' => $data['doc_type'],
            'number_encrypted' => IdentityDocument::encryptNumber($number),
            'number_last4' => substr($number, -4),
            'file_path' => $path, 'file_mime' => $file->getMimeType(), 'file_size_bytes' => $file->getSize(),
            'is_current' => true, 'uploaded_by' => $actor->id,
        ]);
    }

    protected function assertMobileFree(string $mobile): void
    {
        if (User::where('mobile', $mobile)->exists()) {
            throw ValidationException::withMessages(['mobile' => 'This mobile number is already used.']);
        }
    }
}
