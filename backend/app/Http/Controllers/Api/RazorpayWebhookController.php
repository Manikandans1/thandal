<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Payment;
use App\Services\PaymentService;
use App\Services\RazorpayService;
use Illuminate\Http\Request;
use Illuminate\Http\Response;

/**
 * Razorpay webhook endpoint. Runs OUTSIDE auth (Razorpay calls it directly) but the
 * signature is checked before anything else. Every event_id is stored once — a repeated
 * webhook (Razorpay retries on timeout) can never confirm a payment twice.
 */
class RazorpayWebhookController extends Controller
{
    public function __construct(protected RazorpayService $razorpay, protected PaymentService $payments) {}

    public function handle(Request $request): Response
    {
        $signature = $request->header('X-Razorpay-Signature', '');
        $body = $request->getContent();

        if (! $this->razorpay->verifyWebhookSignature($body, $signature)) {
            return response('invalid signature', 400);
        }

        $payload = json_decode($body, true);
        $eventId = $payload['id'] ?? $request->header('X-Razorpay-Event-Id', md5($body));
        $type = $payload['event'] ?? 'unknown';
        $rpPaymentId = $payload['payload']['payment']['entity']['id'] ?? null;

        $payment = $rpPaymentId ? Payment::where('razorpay_payment_id', $rpPaymentId)->first() : null;
        $isNew = $this->razorpay->recordEventOnce($eventId, $type, $payload, $payment?->id);

        if ($isNew && $type === 'payment.captured' && $rpPaymentId) {
            $orderId = $payload['payload']['payment']['entity']['order_id'] ?? null;
            $pending = Payment::where('razorpay_order_id', $orderId)->where('status', 'pending')->first();
            if ($pending) {
                $this->payments->confirmOnlinePayment($pending, $rpPaymentId);
            }
        }
        if ($isNew && $type === 'payment.failed' && $rpPaymentId) {
            $orderId = $payload['payload']['payment']['entity']['order_id'] ?? null;
            $pending = Payment::where('razorpay_order_id', $orderId)->where('status', 'pending')->first();
            $pending?->update(['status' => 'failed', 'failure_reason' => 'Razorpay reported payment.failed']);
        }

        return response('ok', 200); // always 200 once verified, so Razorpay stops retrying
    }
}
