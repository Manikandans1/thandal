import 'dart:async';

import 'package:razorpay_flutter/razorpay_flutter.dart';

/// What happened in the Razorpay Checkout sheet.
class CheckoutResult {
  final bool success;
  final bool cancelled;
  final String? paymentId;
  final String? orderId;
  final String? signature;
  final String? message;

  const CheckoutResult({
    required this.success,
    this.cancelled = false,
    this.paymentId,
    this.orderId,
    this.signature,
    this.message,
  });
}

/// Opens Razorpay Checkout for an order the SERVER created. The result is only a hint:
/// Thandal's server re-verifies the signature with Razorpay before it counts the payment.
class RazorpayCheckout {
  Future<CheckoutResult> open({
    required String key,
    required String orderId,
    required int amountPaise,
    required String description,
    required String contact,
    required String customerName,
  }) {
    final completer = Completer<CheckoutResult>();
    final razorpay = Razorpay();

    void finish(CheckoutResult result) {
      if (!completer.isCompleted) completer.complete(result);
      Future<void>.microtask(razorpay.clear);
    }

    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse r) {
      finish(CheckoutResult(
        success: true,
        paymentId: r.paymentId,
        orderId: r.orderId,
        signature: r.signature,
      ));
    });
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse r) {
      // code 0 = the person closed the sheet without paying.
      finish(CheckoutResult(success: false, cancelled: r.code == 0, message: r.message));
    });
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse r) {
      // Wallet apps finish outside the sheet; the server / webhook confirms later.
    });

    try {
      razorpay.open({
        'key': key,
        'order_id': orderId,
        'amount': amountPaise,
        'currency': 'INR',
        'name': 'Thandal',
        'description': description,
        'prefill': {'contact': contact, 'name': customerName},
        'theme': {'color': '#0B6B4D'},
      });
    } catch (e) {
      finish(CheckoutResult(success: false, message: 'Could not open Razorpay.'));
    }
    return completer.future;
  }
}
