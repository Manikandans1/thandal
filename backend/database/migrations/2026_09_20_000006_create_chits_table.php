<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * A loan and its repayment plan. Total = installment x count. Created Pending; Active after a completed disbursement.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('chits', function (Blueprint $table) {
            $table->id();
            $table->string('chit_code', 20)->unique()->comment('THD-1001');
            $table->foreignId('customer_id')->constrained('customers')->restrictOnDelete();
            $table->foreignId('created_by')->constrained('users')->restrictOnDelete();
            $table->unsignedBigInteger('loan_amount_paise')->comment('amount given to the customer');
            $table->enum('frequency', ['daily', 'weekly', 'monthly']);
            $table->unsignedSmallInteger('installment_count');
            $table->unsignedBigInteger('installment_amount_paise')->comment('set by the admin/agent');
            $table->unsignedBigInteger('total_repayment_paise')->comment('= installment_count x installment_amount_paise');
            $table->unsignedBigInteger('paid_paise')->default(0)->comment('cache, kept in the same transaction as payments');
            $table->unsignedSmallInteger('paid_installments')->default(0)->comment('cache');
            $table->date('start_date')->comment('first installment is due on this date');
            $table->date('end_date');
            $table->enum('status', ['pending', 'active', 'completed', 'cancelled'])->default('pending');
            $table->dateTime('activated_at')->nullable();
            $table->dateTime('completed_at')->nullable();
            $table->dateTime('cancelled_at')->nullable();
            $table->string('cancel_reason', 255)->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();
            $table->index(['customer_id', 'status']);
            $table->index(['status', 'start_date']);
        });
        DB::statement('ALTER TABLE `chits` ADD CONSTRAINT `chk_chits_count` CHECK (installment_count > 0)');
        DB::statement('ALTER TABLE `chits` ADD CONSTRAINT `chk_chits_amount` CHECK (installment_amount_paise > 0)');
        DB::statement('ALTER TABLE `chits` ADD CONSTRAINT `chk_chits_total` CHECK (total_repayment_paise = installment_count * installment_amount_paise)');
        DB::statement('ALTER TABLE `chits` ADD CONSTRAINT `chk_chits_paid` CHECK (paid_paise <= total_repayment_paise)');
    }

    public function down(): void
    {
        Schema::dropIfExists('chits');
    }
};
