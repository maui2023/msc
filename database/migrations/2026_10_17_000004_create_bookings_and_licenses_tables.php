<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     * Modul 4: Pengurusan Tempahan & Ketersediaan (Booking Domain - Decoupled)
     * Tidak mengandungi sebarang kolum gerbang pembayaran bagi mengekalkan pemisahan domain.
     */
    public function up(): void
    {
        Schema::create('bookings', function (Blueprint $table) {
            $table->id();
            $table->string('booking_reference', 32)->unique();
            $table->foreignId('renter_id')->constrained('users')->restrictOnDelete();
            $table->foreignId('owner_profile_id')->constrained('owner_profiles')->restrictOnDelete();
            $table->foreignId('motorcycle_id')->constrained('motorcycles')->restrictOnDelete();
            $table->enum('source', ['marketplace', 'owner_manual'])->default('marketplace');
            $table->dateTime('start_at');
            $table->dateTime('end_at');
            $table->enum('status', [
                'pending_payment',
                'confirmed',
                'ready_for_pickup',
                'ongoing',
                'completed',
                'cancellation_pending',
                'cancelled',
                'expired',
                'rejected',
            ])->default('pending_payment')->index();
            $table->dateTime('hold_expires_at')->nullable()->index();
            $table->decimal('rental_amount', 10, 2);
            $table->decimal('deposit_amount', 10, 2)->default(50.00);
            $table->decimal('fee_amount', 10, 2)->default(2.00);
            $table->decimal('total_amount', 10, 2);
            $table->string('currency', 3)->default('MYR');
            $table->json('pricing_snapshot');
            $table->json('cancellation_policy_snapshot');
            $table->text('pickup_notes')->nullable();
            $table->dateTime('picked_up_at')->nullable();
            $table->dateTime('returned_at')->nullable();
            $table->dateTime('cancellation_requested_at')->nullable();
            $table->dateTime('cancelled_at')->nullable();
            $table->text('cancellation_reason')->nullable();
            $table->foreignId('created_by_user_id')->constrained('users')->restrictOnDelete();
            $table->timestamps();

            // Indeks komposit penting untuk semakan pertindihan tarikh & ketersediaan pantas
            $table->index(['motorcycle_id', 'start_at', 'end_at', 'status'], 'idx_booking_overlap');
            $table->index(['renter_id', 'status']);
            $table->index(['owner_profile_id', 'status']);
        });

        Schema::create('renter_licenses', function (Blueprint $table) {
            $table->id();
            $table->foreignId('booking_id')->constrained('bookings')->cascadeOnDelete();
            $table->foreignId('motorcycle_id')->constrained('motorcycles')->restrictOnDelete();
            $table->foreignId('renter_id')->constrained('users')->restrictOnDelete();
            $table->string('file_path');
            $table->enum('verification_status', ['pending', 'accepted', 'rejected'])->default('pending')->index();
            $table->foreignId('reviewed_by_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('reviewed_at')->nullable();
            $table->string('rejection_reason')->nullable();
            $table->timestamps();

            $table->index(['booking_id', 'motorcycle_id']);
        });

        Schema::create('booking_status_histories', function (Blueprint $table) {
            $table->id();
            $table->foreignId('booking_id')->constrained('bookings')->cascadeOnDelete();
            $table->string('from_status', 50)->nullable();
            $table->string('to_status', 50);
            $table->foreignId('changed_by_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->text('reason')->nullable();
            $table->timestamp('created_at')->useCurrent();

            $table->index(['booking_id', 'created_at']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('booking_status_histories');
        Schema::dropIfExists('renter_licenses');
        Schema::dropIfExists('bookings');
    }
};
