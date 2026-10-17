<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     * Modul 3: Inventori Motosikal & Harga (Motorcycles & Pricing Engine)
     */
    public function up(): void
    {
        Schema::create('motorcycles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('owner_profile_id')->constrained('owner_profiles')->cascadeOnDelete();
            $table->string('brand', 100);
            $table->string('model', 150);
            $table->string('registration_number', 50);
            $table->string('category', 50)->index();
            $table->unsignedInteger('engine_cc')->nullable();
            $table->text('description')->nullable();
            $table->string('pickup_location');
            $table->enum('status', ['draft', 'published', 'maintenance', 'inactive'])->default('draft')->index();
            $table->timestamps();

            $table->index(['owner_profile_id', 'status']);
        });

        Schema::create('motorcycle_images', function (Blueprint $table) {
            $table->id();
            $table->foreignId('motorcycle_id')->constrained('motorcycles')->cascadeOnDelete();
            $table->string('path');
            $table->integer('sort_order')->default(0);
            $table->boolean('is_primary')->default(false);
            $table->timestamps();

            $table->index(['motorcycle_id', 'sort_order']);
        });

        Schema::create('rental_rates', function (Blueprint $table) {
            $table->id();
            $table->foreignId('motorcycle_id')->constrained('motorcycles')->cascadeOnDelete();
            $table->enum('day_type', ['weekday', 'weekend', 'all'])->default('all');
            $table->unsignedInteger('duration_hours');
            $table->decimal('price', 10, 2);
            $table->boolean('is_active')->default(true);
            $table->date('valid_from')->nullable();
            $table->date('valid_until')->nullable();
            $table->timestamps();

            $table->index(['motorcycle_id', 'duration_hours', 'day_type']);
        });

        Schema::create('rental_price_ledger', function (Blueprint $table) {
            $table->id();
            $table->foreignId('motorcycle_id')->constrained('motorcycles')->cascadeOnDelete();
            $table->foreignId('changed_by_user_id')->constrained('users')->restrictOnDelete();
            $table->string('change_type', 50);
            $table->json('old_values')->nullable();
            $table->json('new_values');
            $table->timestamp('valid_from')->nullable();
            $table->timestamp('valid_until')->nullable();
            $table->timestamp('created_at')->useCurrent();

            $table->index(['motorcycle_id', 'created_at']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('rental_price_ledger');
        Schema::dropIfExists('rental_rates');
        Schema::dropIfExists('motorcycle_images');
        Schema::dropIfExists('motorcycles');
    }
};
