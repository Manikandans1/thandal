<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Every Razorpay webhook received. event_id is unique so a repeated webhook is processed once.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('razorpay_events', function (Blueprint $table) {
            $table->id();
            $table->string('event_id', 64)->unique();
            $table->string('event_type', 60);
            $table->foreignId('payment_id')->nullable()->constrained('payments')->restrictOnDelete();
            $table->json('payload');
            $table->enum('status', ['received', 'processed', 'ignored', 'failed'])->default('received');
            $table->dateTime('processed_at')->nullable();
            $table->string('error', 255)->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('razorpay_events');
    }
};
