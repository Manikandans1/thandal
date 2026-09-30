<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Login identity for every role. Mobile number + hashed 4-digit PIN. Admin self-registrations are rows with role=admin and status=pending until a super admin approves.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->enum('role', ['customer', 'agent', 'admin', 'super_admin']);
            $table->string('name', 120);
            $table->char('mobile', 10)->unique()->comment('10 digits, unique across all roles');
            $table->string('pin_hash', 255)->comment('bcrypt hash, never the PIN');
            $table->enum('status', ['pending', 'active', 'inactive', 'rejected'])->default('active');
            $table->boolean('must_change_pin')->default(0)->comment('1 after an admin resets the PIN (temporary PIN)');
            $table->unsignedTinyInteger('failed_attempts')->default(0);
            $table->dateTime('locked_until')->nullable()->comment('set after 3 wrong PINs, 15 minutes');
            $table->dateTime('last_login_at')->nullable();
            $table->foreignId('decided_by')->nullable()->constrained('users')->restrictOnDelete();
            $table->dateTime('decided_at')->nullable()->comment('admin registration decision');
            $table->string('decision_note', 255)->nullable();
            $table->foreignId('created_by')->nullable()->constrained('users')->restrictOnDelete();
            $table->timestamps();
            $table->index(['role', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('users');
    }
};
