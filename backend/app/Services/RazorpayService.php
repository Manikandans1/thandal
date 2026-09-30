<?php

namespace App\Services;

use App\Models\Payment;
use App\Models\RazorpayEvent;
use Razorpay\Api\Api;

/**
 * The app's "payment succeeded" is NEVER trusted (functional spec §6.4). Every online payment
 * is confirmed only after the server verifies the signature with Razorpay AND/OR a webhook arrives.
 */
class RazorpayService
{
    protected Api $api;

    public function __construct()
    {
        $this->api = new Api(config('services.razorpay.key'), config('services.razorpay.secret'));
    }

    public function createOrder(Payment $payment): array
    {
        $order = $this->api->order->create([
            'amount' => $payment->amount_paise,
            'currency' => 'INR',
            'receipt' => 'thandal_payment_'.$payment->id,
            'notes' => ['chit_id' => (string) $payment->chit_id, 'payment_id' => (string) $payment->id],
        ]);

        $payment->razorpay_order_id = $order->id;
        $payment->save();

        return ['order_id' => $order->id, 'amount_paise' => $payment->amount_paise, 'key' => config('services.razorpay.key')];
    }

    /** Verify the checkout callback signature. Throws SignatureVerificationError on failure. */
    public function verifyCheckoutSignature(string $orderId, string $paymentId, string $signature): void
    {
        $this->api->utility->verifyPaymentSignature([
            'razorpay_order_id' => $orderId,
            'razorpay_payment_id' => $paymentId,
            'razorpay_signature' => $signature,
        ]);
    }

    public function fetchPaymentStatus(string $razorpayPaymentId): string
    {
        return $this->api->payment->fetch($razorpayPaymentId)->status; // created|authorized|captured|failed|refunded
    }

    /** Verify a webhook body against the webhook secret (different from the API secret). */
    public function verifyWebhookSignature(string $body, string $signature): bool
    {
        try {
            $this->api->utility->verifyWebhookSignature($body, $signature, config('services.razorpay.webhook_secret'));

            return true;
        } catch (\Throwable) {
            return false;
        }
    }

    /** Records the webhook exactly once (event_id is unique). Returns false if it was already seen. */
    public function recordEventOnce(string $eventId, string $eventType, array $payload, ?int $paymentId = null): bool
    {
        if (RazorpayEvent::where('event_id', $eventId)->exists()) {
            return false;
        }
        RazorpayEvent::create([
            'event_id' => $eventId,
            'event_type' => $eventType,
            'payment_id' => $paymentId,
            'payload' => $payload,
            'status' => 'received',
        ]);

        return true;
    }
}
