<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * How a payment was applied to installments. Signed: reversals are negative rows linked to an adjustment.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('payment_allocations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('payment_id')->constrained('payments')->restrictOnDelete();
            $table->foreignId('installment_id')->constrained('chit_installments')->restrictOnDelete();
            $table->bigInteger('amount_paise');
            $table->foreignId('adjustment_id')->nullable()->constrained('payment_adjustments')->restrictOnDelete();
            $table->timestamps();
            $table->index(['installment_id']);
            $table->index(['payment_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payment_allocations');
    }
};
