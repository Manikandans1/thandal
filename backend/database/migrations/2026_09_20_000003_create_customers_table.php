<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Customer profile. agent_id is the CURRENT agent (history lives in agent_assignments).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('customers', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained('users')->restrictOnDelete();
            $table->string('customer_code', 20)->unique()->comment('THD-10245');
            $table->text('address');
            $table->foreignId('agent_id')->nullable()->constrained('agents')->restrictOnDelete();
            $table->date('joined_on');
            $table->foreignId('created_by')->constrained('users')->restrictOnDelete();
            $table->timestamps();
            $table->index(['agent_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('customers');
    }
};
