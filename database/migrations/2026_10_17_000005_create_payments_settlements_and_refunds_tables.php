<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     * Modul 5: Gerbang Pembayaran, Rekod Kewangan & Penyata (Payment Domain - Decoupled)
     * Mengasingkan transaksi kewangan, idempotensi webhook, pemulangan wang, dan pelepasan dana pemilik.
     */
    public function up(): void
    {
        Schema::create('payments', function (Blueprint $table) {
            $table->id();
            $table->string('payment_reference', 64)->unique();
            $table->foreignId('booking_id')->constrained('bookings')->restrictOnDelete();
            $table->enum('provider', ['affanpay', 'manual'])->index();
            $table->enum('method', ['online', 'cash', 'qr_manual']);
            $table->string('provider_reference', 150)->nullable();
            $table->decimal('amount', 10, 2);
            $table->string('currency', 3)->default('MYR');
            $table->enum('status', [
                'pending',
                'paid',
                'failed',
                'cancelled',
                'refund_pending',
                'partially_refunded',
                'refunded',
            ])->default('pending')->index();
            $table->dateTime('paid_at')->nullable();
            $table->foreignId('recorded_by_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->index(['booking_id', 'status']);
            $table->index(['provider', 'provider_reference']);
        });

        Schema::create('payment_webhook_events', function (Blueprint $table) {
            $table->id();
            $table->string('provider', 50);
            $table->string('event_id', 150);
            $table->string('booking_reference', 32)->nullable()->index();
            $table->string('event_type', 100);
            $table->enum('processing_status', ['received', 'processed', 'ignored', 'failed'])->default('received')->index();
            $table->json('payload_redacted');
            $table->dateTime('received_at');
            $table->dateTime('processed_at')->nullable();

            $table->unique(['provider', 'event_id'], 'uq_provider_event');
        });

        Schema::create('refunds', function (Blueprint $table) {
            $table->id();
            $table->string('refund_reference', 64)->unique();
            $table->foreignId('booking_id')->constrained('bookings')->restrictOnDelete();
            $table->foreignId('payment_id')->constrained('payments')->restrictOnDelete();
            $table->decimal('amount', 10, 2);
            $table->decimal('eligible_amount', 10, 2);
            $table->decimal('percentage', 5, 2);
            $table->text('reason')->nullable();
            $table->enum('status', ['pending', 'processing', 'completed', 'failed', 'manual_review'])->default('pending')->index();
            $table->string('provider_reference', 150)->nullable();
            $table->dateTime('requested_at');
            $table->dateTime('processed_at')->nullable();
            $table->foreignId('processed_by_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();

            $table->index(['booking_id', 'status']);
        });

        Schema::create('settlements', function (Blueprint $table) {
            $table->id();
            $table->foreignId('booking_id')->constrained('bookings')->restrictOnDelete();
            $table->foreignId('owner_profile_id')->constrained('owner_profiles')->restrictOnDelete();
            $table->decimal('gross_amount', 10, 2);
            $table->decimal('fee_deducted', 10, 2)->default(0.00);
            $table->decimal('net_payout_amount', 10, 2);
            $table->enum('status', [
                'pending_affanpay_release',
                'platform_received',
                'pending_owner_release',
                'released_to_owner',
                'failed',
                'manual_review',
            ])->default('pending_affanpay_release')->index();
            $table->dateTime('affanpay_released_at')->nullable();
            $table->dateTime('owner_release_due_at')->index();
            $table->dateTime('owner_released_at')->nullable();
            $table->string('payout_reference', 150)->nullable();
            $table->timestamps();

            $table->index(['owner_profile_id', 'status']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('settlements');
        Schema::dropIfExists('refunds');
        Schema::dropIfExists('payment_webhook_events');
        Schema::dropIfExists('payments');
    }
};
