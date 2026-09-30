<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\PaymentResource;
use App\Models\Chit;
use App\Services\PaymentService;
use App\Services\RazorpayService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class PaymentController extends Controller
{
    public function __construct(protected PaymentService $payments, protected RazorpayService $razorpay) {}

    /** Agent collects cash. client_request_id is required so a retry never double-charges (functional spec §6.5). */
    public function collectCash(Request $request, Chit $chit): JsonResponse
    {
        $request->validate(['amount' => 'required|integer|min:1', 'client_request_id' => 'required|string|max:64']);
        abort_unless($request->user()->role === 'agent', 403);

        $payment = $this->payments->collectCash($chit, $request->user()->agent, $request->amount * 100, $request->client_request_id, $request->user());

        return response()->json(new PaymentResource($payment), 201);
    }

    /** Step 1 of an online payment: the server decides the amount and opens a Razorpay order. */
    public function startOnline(Request $request, Chit $chit): JsonResponse
    {
        $request->validate(['amount' => 'required|integer|min:1']);
        abort_unless($request->user()->role === 'customer' && $chit->customer_id === $request->user()->customer->id, 403);

        $payment = $this->payments->startOnlinePayment($chit, $request->amount * 100, $request->user());
        $order = $this->razorpay->createOrder($payment);

        return response()->json(['payment_id' => $payment->id] + $order);
    }

    /** Step 2: called by the app after Razorpay Checkout closes. The server re-verifies before confirming — see functional spec §6.4. */
    public function verifyOnline(Request $request): JsonResponse
    {
        $request->validate([
            'payment_id' => 'required|exists:payments,id',
            'razorpay_order_id' => 'required|string',
            'razorpay_payment_id' => 'required|string',
            'razorpay_signature' => 'required|string',
        ]);

        $payment = \App\Models\Payment::findOrFail($request->payment_id);

        try {
            $this->razorpay->verifyCheckoutSignature($request->razorpay_order_id, $request->razorpay_payment_id, $request->razorpay_signature);
        } catch (\Throwable) {
            $this->payments->failOnlinePayment($payment, 'Signature verification failed');

            throw ValidationException::withMessages(['signature' => 'Payment could not be verified.']);
        }

        $status = $this->razorpay->fetchPaymentStatus($request->razorpay_payment_id);
        if (! in_array($status, ['captured', 'authorized'], true)) {
            $this->payments->failOnlinePayment($payment, "Razorpay status: {$status}");

            return response()->json(['status' => 'failed'], 422);
        }

        $payment = $this->payments->confirmOnlinePayment($payment, $request->razorpay_payment_id);

        return response()->json(new PaymentResource($payment));
    }

    public function show(Request $request, \App\Models\Payment $payment): JsonResponse
    {
        return response()->json(new PaymentResource($payment->load(['allocations.installment', 'correctionRequests'])));
    }
}
