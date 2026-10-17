<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     * Modul 2: Profil Pemilik & Langganan SaaS (Owner Profile & SaaS Billing)
     */
    public function up(): void
    {
        Schema::create('owner_profiles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained('users')->cascadeOnDelete();
            $table->string('business_name');
            $table->string('slug')->unique();
            $table->text('description')->nullable();
            $table->string('phone', 30);
            $table->string('email')->nullable();
            $table->text('address');
            $table->decimal('latitude', 10, 8)->nullable();
            $table->decimal('longitude', 11, 8)->nullable();
            $table->json('operating_hours')->nullable();
            $table->enum('status', ['pending', 'active', 'suspended'])->default('pending')->index();
            $table->timestamps();
        });

        Schema::create('owner_subscription_plans', function (Blueprint $table) {
            $table->id();
            $table->string('name', 100);
            $table->string('code', 50)->unique();
            $table->enum('billing_cycle', ['one_time', 'monthly', 'per_transaction'])->default('monthly');
            $table->decimal('price', 10, 2)->default(0.00);
            $table->unsignedInteger('trial_days')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::create('owner_subscriptions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('owner_profile_id')->constrained('owner_profiles')->cascadeOnDelete();
            $table->foreignId('plan_id')->constrained('owner_subscription_plans')->restrictOnDelete();
            $table->decimal('plan_price_snapshot', 10, 2);
            $table->enum('status', ['trialing', 'active', 'past_due', 'cancelled'])->default('trialing')->index();
            $table->timestamp('starts_at');
            $table->timestamp('ends_at')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('owner_subscriptions');
        Schema::dropIfExists('owner_subscription_plans');
        Schema::dropIfExists('owner_profiles');
    }
};
