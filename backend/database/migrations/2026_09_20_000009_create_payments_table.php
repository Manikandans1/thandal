<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * One row per money received. Confirmed rows are immutable: fixes are made with payment_adjustments.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('payments', function (Blueprint $table) {
            $table->id();
            $table->string('receipt_number', 24)->nullable()->unique()->comment('THD-RCP-000231, given when confirmed');
            $table->foreignId('chit_id')->constrained('chits')->restrictOnDelete();
            $table->foreignId('customer_id')->constrained('customers')->restrictOnDelete();
            $table->enum('method', ['cash', 'online']);
            $table->enum('status', ['pending', 'confirmed', 'failed', 'reversed']);
            $table->unsignedBigInteger('amount_paise')->comment('amount as first recorded');
            $table->unsignedBigInteger('net_amount_paise')->nullable()->comment('amount after approved corrections; NULL = unchanged (effective = COALESCE(net, amount))');
            $table->dateTime('paid_at')->nullable();
            $table->foreignId('collected_by_agent_id')->nullable()->constrained('agents')->restrictOnDelete();
            $table->foreignId('recorded_by')->nullable()->constrained('users')->restrictOnDelete();
            $table->string('razorpay_order_id', 40)->nullable()->unique();
            $table->string('razorpay_payment_id', 40)->nullable()->unique();
            $table->string('failure_reason', 255)->nullable();
            $table->string('client_request_id', 64)->nullable()->unique()->comment('sent by the app; blocks double taps and repeat submits');
            $table->string('notes', 255)->nullable();
            $table->timestamps();
            $table->index(['chit_id', 'paid_at']);
            $table->index(['customer_id', 'paid_at']);
            $table->index(['collected_by_agent_id', 'paid_at']);
            $table->index(['status', 'paid_at']);
        });
        DB::statement('ALTER TABLE `payments` ADD CONSTRAINT `chk_pay_amount` CHECK (amount_paise > 0)');
    }

    public function down(): void
    {
        Schema::dropIfExists('payments');
    }
};
