<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * ID proof of a customer or an agent (any one type). Number is encrypted, file is in private storage.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('identity_documents', function (Blueprint $table) {
            $table->id();
            $table->foreignId('customer_id')->nullable()->constrained('customers')->restrictOnDelete();
            $table->foreignId('agent_id')->nullable()->constrained('agents')->restrictOnDelete();
            $table->enum('doc_type', ['aadhaar_card', 'pan_card', 'voter_id', 'driving_licence', 'passport', 'ration_card']);
            $table->text('number_encrypted')->comment('Laravel Crypt, never shown in full');
            $table->char('number_last4', 4);
            $table->string('file_path', 255)->comment('private disk path');
            $table->string('file_mime', 60);
            $table->unsignedInteger('file_size_bytes');
            $table->boolean('is_current')->default(1);
            $table->foreignId('uploaded_by')->constrained('users')->restrictOnDelete();
            $table->timestamps();
            $table->index(['customer_id', 'is_current']);
            $table->index(['agent_id', 'is_current']);
        });
        DB::statement('ALTER TABLE `identity_documents` ADD CONSTRAINT `chk_identity_owner` CHECK ((customer_id IS NULL) <> (agent_id IS NULL))');
    }

    public function down(): void
    {
        Schema::dropIfExists('identity_documents');
    }
};
