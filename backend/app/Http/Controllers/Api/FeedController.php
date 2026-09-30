<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\ChitInstallmentResource;
use App\Http\Resources\ChitResource;
use App\Http\Resources\PaymentResource;
use App\Models\AuditLog;
use App\Models\Chit;
use App\Models\Customer;
use App\Models\Payment;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Read-only "list" endpoints the mobile app needs (payment history, portfolio, admin lists).
 * Every query is scoped by role here on the server; the app never filters for security.
 */
class FeedController extends Controller
{
    /** Customer: payments (receipts) on one of my own chits, newest first. */
    public function customerChitPayments(Request $request, Chit $chit): JsonResponse
    {
        abort_unless($chit->customer_id === $request->user()->customer?->id, 404);

        return response()->json(PaymentResource::collection($this->paymentQuery()->where('chit_id', $chit->id)->limit(500)->get()));
    }

    /** Agent: payments on his customers' chits, or that he collected. ?range=today|yesterday|week|all */
    public function agentPayments(Request $request): JsonResponse
    {
        $agent = $request->user()->agent;
        $q = $this->paymentQuery()->where(function ($w) use ($agent) {
            $w->where('collected_by_agent_id', $agent->id)
              ->orWhereIn('customer_id', Customer::where('agent_id', $agent->id)->select('id'));
        });
        $this->applyRange($q, $request->get('range', 'all'));

        return response()->json(PaymentResource::collection($q->limit(500)->get()));
    }

    /** Admin: all payments. ?range=today|yesterday|week|all &method=cash|online &status=confirmed|pending|failed|reversed */
    public function adminPayments(Request $request): JsonResponse
    {
        abort_unless($request->user()->isAdmin(), 403);
        $q = $this->paymentQuery();
        $this->applyRange($q, $request->get('range', 'all'));
        if ($m = $request->get('method')) {
            $q->where('method', $m);
        }
        if ($s = $request->get('status')) {
            $q->where('status', $s);
        }

        return response()->json(PaymentResource::collection($q->limit(500)->get()));
    }

    /**
     * Customers with their chits (and, for the agent app, each chit's schedule) in ONE call,
     * so the app does not make a request per customer. Agents only ever get their own customers.
     * ?schedules=1 includes the installment schedule of every chit.
     */
    public function portfolio(Request $request): JsonResponse
    {
        $u = $request->user();
        abort_unless($u->role === 'agent' || $u->isAdmin(), 403);
        $q = Customer::with(['user', 'agent.user', 'currentIdentityDocument', 'chits.installments', 'chits.disbursement'])->orderBy('id');
        if ($u->role === 'agent') {
            $q->where('agent_id', $u->agent->id);
        }
        $withSchedule = $request->boolean('schedules');

        $rows = $q->get()->map(function (Customer $c) use ($withSchedule) {
            $c->chits->each(fn (Chit $ch) => $ch->setRelation('customer', $c));
            $active = $c->chits->where('status', 'active');

            return [
                'id' => $c->id,
                'customer_code' => $c->customer_code,
                'name' => $c->user->name,
                'mobile' => $c->user->mobile,
                'address' => $c->address,
                'status' => $c->user->status,
                'joined_on' => $c->joined_on?->toDateString(),
                'agent' => $c->agent ? ['id' => $c->agent->id, 'code' => $c->agent->agent_code, 'name' => $c->agent->user->name] : null,
                'id_proof' => $c->currentIdentityDocument ? [
                    'type' => $c->currentIdentityDocument->typeLabel(),
                    'last4' => $c->currentIdentityDocument->number_last4,
                ] : null,
                'outstanding_paise' => $active->sum(fn (Chit $ch) => $ch->outstandingPaise()),
                'overdue_paise' => $active->sum(fn (Chit $ch) => $ch->overduePaise()),
                'chits' => $c->chits->map(function (Chit $ch) use ($withSchedule) {
                    $data = (new ChitResource($ch))->resolve();
                    if ($withSchedule) {
                        $data['schedule'] = ChitInstallmentResource::collection($ch->installments)->resolve();
                    }

                    return $data;
                })->values(),
            ];
        })->values();

        return response()->json($rows);
    }

    /** Admin: every chit with customer, agent and disbursement info. ?status=pending|active|completed|cancelled */
    public function adminChits(Request $request): JsonResponse
    {
        abort_unless($request->user()->isAdmin(), 403);
        $q = Chit::with(['customer.user', 'customer.agent.user', 'disbursement'])->orderByDesc('id');
        if ($s = $request->get('status')) {
            $q->where('status', $s);
        }

        return response()->json(ChitResource::collection($q->limit(1000)->get()));
    }

    /** Admin: audit trail, newest first. ?q=search */
    public function auditLogs(Request $request): JsonResponse
    {
        abort_unless($request->user()->isAdmin(), 403);
        $q = AuditLog::query()->latest('id');
        if ($s = $request->get('q')) {
            $q->where(fn ($w) => $w->where('entity_id', 'like', "%$s%")->orWhere('summary', 'like', "%$s%"));
        }

        return response()->json($q->limit(200)->get()->map(fn (AuditLog $l) => [
            'id' => $l->id,
            'action' => $l->action,
            'actor' => $l->actor_label,
            'entity_type' => $l->entity_type,
            'entity_id' => $l->entity_id,
            'summary' => $l->summary,
            'created_at' => $l->created_at?->toIso8601String(),
        ]));
    }

    protected function paymentQuery()
    {
        return Payment::with(['chit', 'customer.user', 'collectedByAgent.user', 'allocations.installment', 'correctionRequests'])
            ->whereIn('status', ['confirmed', 'reversed', 'pending', 'failed'])
            ->where(fn ($w) => $w->where('status', '!=', 'pending')->orWhere('method', 'online'))
            ->latest('id');
    }

    protected function applyRange($q, string $range): void
    {
        $today = Carbon::now('Asia/Kolkata')->startOfDay();
        match ($range) {
            'today' => $q->where('paid_at', '>=', $today->copy()),
            'yesterday' => $q->where('paid_at', '>=', $today->copy()->subDay())->where('paid_at', '<', $today->copy()),
            'week' => $q->where('paid_at', '>=', $today->copy()->subDays(7)),
            default => null,
        };
    }
}
