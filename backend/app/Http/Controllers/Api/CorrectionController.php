<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CorrectionRequest;
use App\Models\Payment;
use App\Services\CorrectionService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class CorrectionController extends Controller
{
    public function __construct(protected CorrectionService $corrections) {}

    public function store(Request $request, Payment $payment): JsonResponse
    {
        abort_unless($request->user()->role === 'agent', 403);
        $request->validate([
            'reason' => ['required', Rule::in(['wrong_amount', 'wrong_customer_or_chit', 'duplicate_entry', 'other'])],
            'requested_amount' => 'nullable|integer|min:0',
            'note' => 'required|string|min:10',
        ]);

        $cr = $this->corrections->request(
            $payment, $request->user()->agent, $request->reason,
            $request->requested_amount !== null ? $request->requested_amount * 100 : null,
            $request->note, $request->user()
        );

        return response()->json(['code' => $cr->code, 'status' => $cr->status], 201);
    }

    public function index(Request $request): JsonResponse
    {
        abort_unless($request->user()->isAdmin(), 403);
        $q = CorrectionRequest::with(['payment.customer.user', 'requestedByAgent.user'])
            ->when($request->status, fn ($qq) => $qq->where('status', $request->status))
            ->latest();

        return response()->json($q->paginate(20));
    }

    public function approve(Request $request, CorrectionRequest $correction): JsonResponse
    {
        abort_unless($request->user()->isAdmin(), 403);
        $request->validate(['note' => 'nullable|string', 'resolution_chit_id' => 'nullable|exists:chits,id']);
        $cr = $this->corrections->approve($correction, $request->resolution_chit_id, $request->note ?? 'Approved.', $request->user());

        return response()->json(['status' => $cr->status]);
    }

    public function reject(Request $request, CorrectionRequest $correction): JsonResponse
    {
        abort_unless($request->user()->isAdmin(), 403);
        $request->validate(['note' => 'required|string']);
        $cr = $this->corrections->reject($correction, $request->note, $request->user());

        return response()->json(['status' => $cr->status]);
    }
}
