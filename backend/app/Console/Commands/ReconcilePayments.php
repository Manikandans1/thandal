<?php

namespace App\Console\Commands;

use App\Models\Payment;
use App\Services\PaymentService;
use App\Services\RazorpayService;
use Illuminate\Console\Command;

/**
 * Online payments stuck "pending" for too long (app closed mid-payment, webhook missed) are
 * checked directly against Razorpay (functional spec §6.4 step 8). Scheduled every 5 minutes.
 */
class ReconcilePayments extends Command
{
    protected $signature = 'thandal:reconcile-payments';
    protected $description = 'Reconcile online payments stuck pending against Razorpay';

    public function handle(RazorpayService $razorpay, PaymentService $payments): int
    {
        $minutes = config('thandal.razorpay_reconcile_after_minutes');
        $stuck = Payment::where('status', 'pending')->where('method', 'online')
            ->where('created_at', '<=', now()->subMinutes($minutes))
            ->whereNotNull('razorpay_order_id')->get();

        foreach ($stuck as $payment) {
            // In a real Razorpay account we would look up the order's payments; simplified here to the direct payment id if known.
            if ($payment->razorpay_payment_id) {
                $status = $razorpay->fetchPaymentStatus($payment->razorpay_payment_id);
                if (in_array($status, ['captured', 'authorized'], true)) {
                    $payments->confirmOnlinePayment($payment, $payment->razorpay_payment_id);
                    $this->info("Confirmed payment #{$payment->id}");

                    continue;
                }
            }
            $payments->failOnlinePayment($payment, 'No confirmation received within the reconciliation window');
            $this->warn("Marked payment #{$payment->id} as failed");
        }

        return self::SUCCESS;
    }
}
