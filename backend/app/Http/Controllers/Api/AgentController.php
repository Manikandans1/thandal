<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Agent\CreateAgentRequest;
use App\Models\Agent;
use App\Models\Customer;
use App\Services\PeopleService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/** Admin-only: create/list/transfer/deactivate agents. */
class AgentController extends Controller
{
    public function __construct(protected PeopleService $people) {}

    public function index(): JsonResponse
    {
        $today = today_ist()->toDateString();

        return response()->json(Agent::with(['user', 'currentIdentityDocument'])->get()->map(function (Agent $a) use ($today) {
            $customerIds = $a->customers()->pluck('id');
            $chits = \App\Models\Chit::whereIn('customer_id', $customerIds)->where('status', 'active')->with('installments')->get();
            $pending = $chits->sum(fn ($c) => $c->installments
                ->filter(fn ($i) => $i->due_date->toDateString() <= $today && ! in_array($i->status, ['paid', 'cancelled'], true))
                ->sum(fn ($i) => $i->remainingPaise()));
            $collected = \App\Models\Payment::where('status', 'confirmed')->whereDate('paid_at', $today)
                ->where(fn ($q) => $q->where('collected_by_agent_id', $a->id)->orWhereIn('customer_id', $customerIds))->sum('amount_paise');

            return [
                'id' => $a->id, 'code' => $a->agent_code, 'name' => $a->user->name, 'mobile' => $a->user->mobile,
                'address' => $a->address, 'joined_on' => $a->joined_on?->toDateString(),
                'status' => $a->user->status, 'customers' => $customerIds->count(),
                'id_proof' => $a->currentIdentityDocument ? ['type' => $a->currentIdentityDocument->typeLabel(), 'last4' => $a->currentIdentityDocument->number_last4] : null,
                'collected_today' => rupees((int) $collected), 'collected_today_paise' => (int) $collected,
                'pending_today' => rupees((int) $pending), 'pending_today_paise' => (int) $pending,
            ];
        }));
    }

    public function store(CreateAgentRequest $request): JsonResponse
    {
        $data = $request->validated();
        $data['document'] = $request->file('document');
        ['agent' => $agent, 'pin' => $pin] = $this->people->createAgent($data, $request->user());

        return response()->json(['agent_id' => $agent->agent_code, 'mobile' => $agent->user->mobile, 'pin' => $pin], 201);
    }

    public function resetAgentPin(Request $request, Agent $agent): JsonResponse
    {
        $pin = $this->people->resetPin($agent->user, $request->user());

        return response()->json(['mobile' => $agent->user->mobile, 'pin' => $pin]);
    }

    public function resetCustomerPin(Request $request, Customer $customer): JsonResponse
    {
        $pin = $this->people->resetPin($customer->user, $request->user());

        return response()->json(['mobile' => $customer->user->mobile, 'pin' => $pin]);
    }

    public function setAgentActive(Request $request, Agent $agent): JsonResponse
    {
        $request->validate(['active' => 'required|boolean']);
        $this->people->setActive($agent->user, $request->boolean('active'), $request->user());

        return response()->json(['status' => $agent->user->fresh()->status]);
    }

    public function setCustomerActive(Request $request, Customer $customer): JsonResponse
    {
        $request->validate(['active' => 'required|boolean']);
        $this->people->setActive($customer->user, $request->boolean('active'), $request->user());

        return response()->json(['status' => $customer->user->fresh()->status]);
    }

    public function transfer(Request $request, Customer $customer): JsonResponse
    {
        $request->validate(['agent_id' => 'required|exists:agents,id', 'reason' => 'nullable|string|max:120']);
        $agent = Agent::findOrFail($request->agent_id);
        $this->people->transferAgent($customer, $agent, $request->reason ?? 'Route change', $request->user());

        return response()->json(['ok' => true]);
    }

    public function deactivate(Request $request, Agent $agent): JsonResponse
    {
        $this->people->deactivateAgent($agent, $request->user());

        return response()->json(['ok' => true]);
    }
}
