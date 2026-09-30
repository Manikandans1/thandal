<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Who looked after a customer and when. Past rows are never edited.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('agent_assignments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('customer_id')->constrained('customers')->restrictOnDelete();
            $table->foreignId('agent_id')->constrained('agents')->restrictOnDelete();
            $table->foreignId('assigned_by')->constrained('users')->restrictOnDelete();
            $table->date('assigned_on');
            $table->date('ended_on')->nullable();
            $table->string('reason', 120)->nullable();
            $table->unsignedBigInteger('active_customer_id')->nullable()->unique()->comment('= customer_id while current, NULL after. Unique => one current agent per customer');
            $table->timestamps();
            $table->index(['customer_id', 'assigned_on']);
            $table->index(['agent_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('agent_assignments');
    }
};
