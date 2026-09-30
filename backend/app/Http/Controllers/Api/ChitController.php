<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\CreateChitRequest;
use App\Http\Requests\Admin\RecordDisbursementRequest;
use App\Http\Resources\ChitInstallmentResource;
use App\Http\Resources\ChitResource;
use App\Models\Chit;
use App\Models\Customer;
use App\Services\ChitService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/** Used by both Admin and Agent — an agent may only create/view chits for their own customers (checked below). */
class ChitController extends Controller
{
    public function __construct(protected ChitService $chits) {}

    public function store(CreateChitRequest $request): JsonResponse
    {
        $data = $request->validated();
        $customer = Customer::findOrFail($data['customer_id']);
        $this->authorizeCustomer($request, $customer);

        $chit = $this->chits->create([
            'customer_id' => $customer->id,
            'loan_amount_paise' => $data['loan_amount'] * 100,
            'frequency' => $data['frequency'],
            'installment_count' => $data['installment_count'],
            'installment_amount_paise' => $data['installment_amount'] * 100,
            'start_date' => $data['start_date'],
            'notes' => $data['notes'] ?? null,
        ], $request->user());

        return response()->json(new ChitResource($chit), 201);
    }

    public function show(Request $request, Chit $chit): JsonResponse
    {
        $this->authorizeCustomer($request, $chit->customer);

        return response()->json(new ChitResource($chit->load('installments')));
    }

    public function schedule(Request $request, Chit $chit): JsonResponse
    {
        $this->authorizeCustomer($request, $chit->customer);

        return response()->json(ChitInstallmentResource::collection($chit->installments));
    }

    public function disburse(RecordDisbursementRequest $request, Chit $chit): JsonResponse
    {
        abort_unless($request->user()->isAdmin(), 403);
        $d = $this->chits->recordDisbursement($chit, $request->validated(), $request->user());

        return response()->json(['status' => $d->status, 'chit' => new ChitResource($chit->fresh())]);
    }

    public function cancel(Request $request, Chit $chit): JsonResponse
    {
        abort_unless($request->user()->isAdmin(), 403);
        $request->validate(['reason' => 'required|string|max:255']);
        $chit = $this->chits->cancel($chit, $request->reason, $request->user());

        return response()->json(new ChitResource($chit));
    }

    protected function authorizeCustomer(Request $request, Customer $customer): void
    {
        $u = $request->user();
        if ($u->isAdmin()) {
            return;
        }
        if ($u->role === 'agent' && $customer->agent_id === $u->agent?->id) {
            return;
        }
        if ($u->role === 'customer' && $customer->user_id === $u->id) {
            return;
        }
        abort(404); // never reveal that a record exists to someone without access
    }
}
