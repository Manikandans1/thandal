<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Customer\CreateCustomerRequest;
use App\Models\Customer;
use App\Services\PeopleService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CustomerController extends Controller
{
    public function __construct(protected PeopleService $people) {}

    public function index(Request $request): JsonResponse
    {
        $q = Customer::with(['user', 'agent.user']);
        if ($request->user()->role === 'agent') {
            $q->where('agent_id', $request->user()->agent->id);
        }
        if ($s = $request->get('q')) {
            // Grouped so the agent scope above can never be bypassed by the OR.
            $q->where(function ($w) use ($s) {
                $w->whereHas('user', fn ($u) => $u->where('name', 'like', "%$s%")->orWhere('mobile', 'like', "%$s%"))
                  ->orWhere('customer_code', 'like', "%$s%");
            });
        }

        return response()->json($q->paginate(20));
    }

    public function store(CreateCustomerRequest $request): JsonResponse
    {
        $data = $request->validated();
        $data['document'] = $request->file('document');
        if ($request->user()->role === 'agent') {
            $data['agent_id'] = $request->user()->agent->id; // agents may only assign themselves
        }

        ['customer' => $customer, 'pin' => $pin] = $this->people->createCustomer($data, $request->user());

        return response()->json([
            'customer_id' => $customer->customer_code,
            'mobile' => $customer->user->mobile,
            'pin' => $pin, // shown to the creator exactly once
        ], 201);
    }

    public function show(Request $request, Customer $customer): JsonResponse
    {
        $this->authorizeView($request, $customer);
        $customer->load(['user', 'agent.user', 'currentIdentityDocument', 'chits']);

        return response()->json([
            'customer_code' => $customer->customer_code,
            'name' => $customer->user->name,
            'mobile' => $customer->user->mobile,
            'address' => $customer->address,
            'status' => $customer->user->status,
            'agent' => $customer->agent ? ['code' => $customer->agent->agent_code, 'name' => $customer->agent->user->name] : null,
            'id_proof' => $customer->currentIdentityDocument ? [
                'type' => $customer->currentIdentityDocument->typeLabel(),
                'last4' => $customer->currentIdentityDocument->number_last4,
            ] : null,
            'outstanding' => rupees($customer->outstandingPaise()),
            'overdue' => rupees($customer->overduePaise()),
            'chits' => \App\Http\Resources\ChitResource::collection($customer->chits),
        ]);
    }


    /** The logged-in customer's own chits (Customer Home "All my chits" + selector, functional spec §7). */
    public function myChits(Request $request): JsonResponse
    {
        $customer = $request->user()->customer;
        $customer->load(['chits.customer.user', 'chits.customer.agent.user']);

        return response()->json(\App\Http\Resources\ChitResource::collection($customer->chits));
    }

    protected function authorizeView(Request $request, Customer $customer): void
    {
        $u = $request->user();
        $ok = $u->isAdmin() || ($u->role === 'agent' && $customer->agent_id === $u->agent?->id) || ($u->role === 'customer' && $customer->user_id === $u->id);
        abort_unless($ok, 404);
    }
}
