<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * The repayment schedule, one row per due date. "Overdue" is derived: due_date < today (IST) and not paid.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('chit_installments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('chit_id')->constrained('chits')->restrictOnDelete();
            $table->unsignedSmallInteger('sequence');
            $table->date('due_date');
            $table->unsignedBigInteger('amount_paise');
            $table->unsignedBigInteger('paid_paise')->default(0);
            $table->enum('status', ['upcoming', 'partially_paid', 'paid', 'cancelled'])->default('upcoming');
            $table->dateTime('paid_at')->nullable();
            $table->timestamps();
            $table->unique(['chit_id', 'sequence']);
            $table->index(['due_date', 'status']);
            $table->index(['chit_id', 'status']);
        });
        DB::statement('ALTER TABLE `chit_installments` ADD CONSTRAINT `chk_inst_paid` CHECK (paid_paise <= amount_paise)');
    }

    public function down(): void
    {
        Schema::dropIfExists('chit_installments');
    }
};
