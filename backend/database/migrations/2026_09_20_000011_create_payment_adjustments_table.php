<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Append-only record of every correction applied to a payment (nothing is deleted).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('payment_adjustments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('payment_id')->constrained('payments')->restrictOnDelete();
            $table->foreignId('correction_request_id')->nullable()->constrained('correction_requests')->restrictOnDelete();
            $table->enum('type', ['amount_change', 'reversal', 'moved_to_other_chit']);
            $table->bigInteger('delta_paise')->comment('signed change to the payment amount');
            $table->foreignId('created_by')->constrained('users')->restrictOnDelete();
            $table->string('reason', 255);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payment_adjustments');
    }
};
