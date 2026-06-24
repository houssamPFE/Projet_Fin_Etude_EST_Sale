<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->enum('plan', ['free', 'pro', 'premium'])->default('free')->after('is_active');
            $table->unsignedInteger('consultation_credits')->default(0)->after('plan');
            $table->timestamp('plan_expires_at')->nullable()->after('consultation_credits');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['plan', 'consultation_credits', 'plan_expires_at']);
        });
    }
};
