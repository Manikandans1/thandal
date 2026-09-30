<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Agent asks the admin to fix a confirmed payment.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('correction_requests', function (Blueprint $table) {
            $table->id();
            $table->string('code', 20)->unique()->comment('CR-041');
            $table->foreignId('payment_id')->constrained('payments')->restrictOnDelete();
            $table->foreignId('requested_by_agent_id')->constrained('agents')->restrictOnDelete();
            $table->enum('reason', ['wrong_amount', 'wrong_customer_or_chit', 'duplicate_entry', 'other']);
            $table->unsignedBigInteger('requested_amount_paise')->nullable();
            $table->text('note');
            $table->enum('status', ['pending', 'approved', 'rejected'])->default('pending');
            $table->foreignId('resolution_chit_id')->nullable()->constrained('chits')->restrictOnDelete();
            $table->foreignId('decided_by')->nullable()->constrained('users')->restrictOnDelete();
            $table->dateTime('decided_at')->nullable();
            $table->text('decision_note')->nullable();
            $table->timestamps();
            $table->index(['status', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('correction_requests');
    }
};
