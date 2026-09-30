<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Loan amount given to the customer (cash or bank transfer). A failed attempt leaves the chit Pending.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('disbursements', function (Blueprint $table) {
            $table->id();
            $table->foreignId('chit_id')->constrained('chits')->restrictOnDelete();
            $table->enum('method', ['cash', 'bank_transfer'])->nullable();
            $table->unsignedBigInteger('amount_paise');
            $table->enum('status', ['pending', 'completed', 'failed'])->default('pending');
            $table->date('disbursed_on')->nullable();
            $table->string('reference', 60)->nullable()->comment('required for bank transfer');
            $table->string('note', 255)->nullable();
            $table->foreignId('recorded_by')->nullable()->constrained('users')->restrictOnDelete();
            $table->timestamps();
            $table->index(['chit_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('disbursements');
    }
};
