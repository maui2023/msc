-- ==============================================================================
-- Schema SQL: MotoSewa — Marketplace SaaS Sewaan Motosikal
-- Reka bentuk pangkalan data berperingkat & berasingan (Decoupled Architecture)
-- Target: MariaDB 10.6+ / MySQL 8.0+ / SQLite 3 (Diterjemahkan via Laravel)
-- Tarikh: 17 Oktober 2026
-- ==============================================================================

SET FOREIGN_KEY_CHECKS = 0;

-- ------------------------------------------------------------------------------
-- MODUL 1: PENGESAHAN & PENGGUNA (AUTH & USERS)
-- ------------------------------------------------------------------------------

DROP TABLE IF EXISTS `audit_logs`;
DROP TABLE IF EXISTS `sessions`;
DROP TABLE IF EXISTS `password_reset_tokens`;
DROP TABLE IF EXISTS `users`;

CREATE TABLE `users` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(255) NOT NULL,
    `email` VARCHAR(255) NOT NULL UNIQUE,
    `phone` VARCHAR(30) NULL,
    `password` VARCHAR(255) NOT NULL,
    `role` ENUM('renter', 'owner', 'admin', 'moderator') NOT NULL DEFAULT 'renter',
    `status` ENUM('active', 'pending', 'suspended') NOT NULL DEFAULT 'active',
    `email_verified_at` TIMESTAMP NULL,
    `remember_token` VARCHAR(100) NULL,
    `created_at` TIMESTAMP NULL DEFAULT NULL,
    `updated_at` TIMESTAMP NULL DEFAULT NULL,
    INDEX `idx_users_role_status` (`role`, `status`),
    INDEX `idx_users_phone` (`phone`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `password_reset_tokens` (
    `email` VARCHAR(255) PRIMARY KEY,
    `token` VARCHAR(255) NOT NULL,
    `created_at` TIMESTAMP NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `sessions` (
    `id` VARCHAR(255) PRIMARY KEY,
    `user_id` BIGINT UNSIGNED NULL,
    `ip_address` VARCHAR(45) NULL,
    `user_agent` TEXT NULL,
    `payload` LONGTEXT NOT NULL,
    `last_activity` INT NOT NULL,
    INDEX `idx_sessions_user_id` (`user_id`),
    INDEX `idx_sessions_last_activity` (`last_activity`),
    CONSTRAINT `fk_sessions_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `audit_logs` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `actor_user_id` BIGINT UNSIGNED NULL,
    `action` VARCHAR(100) NOT NULL,
    `entity_type` VARCHAR(100) NULL,
    `entity_id` BIGINT UNSIGNED NULL,
    `before` JSON NULL,
    `after` JSON NULL,
    `ip_address` VARCHAR(45) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_audit_actor` (`actor_user_id`),
    INDEX `idx_audit_entity` (`entity_type`, `entity_id`),
    INDEX `idx_audit_action` (`action`),
    CONSTRAINT `fk_audit_actor` FOREIGN KEY (`actor_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ------------------------------------------------------------------------------
-- MODUL 2: PROFIL PEMILIK & LANGGANAN SAAS (OWNER & SAAS BILLING)
-- ------------------------------------------------------------------------------

DROP TABLE IF EXISTS `owner_subscriptions`;
DROP TABLE IF EXISTS `owner_subscription_plans`;
DROP TABLE IF EXISTS `owner_profiles`;

CREATE TABLE `owner_profiles` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id` BIGINT UNSIGNED NOT NULL UNIQUE,
    `business_name` VARCHAR(255) NOT NULL,
    `slug` VARCHAR(255) NOT NULL UNIQUE,
    `description` TEXT NULL,
    `phone` VARCHAR(30) NOT NULL,
    `email` VARCHAR(255) NULL,
    `address` TEXT NOT NULL,
    `latitude` DECIMAL(10, 8) NULL,
    `longitude` DECIMAL(11, 8) NULL,
    `operating_hours` JSON NULL,
    `status` ENUM('pending', 'active', 'suspended') NOT NULL DEFAULT 'pending',
    `created_at` TIMESTAMP NULL DEFAULT NULL,
    `updated_at` TIMESTAMP NULL DEFAULT NULL,
    INDEX `idx_owner_status` (`status`),
    INDEX `idx_owner_slug` (`slug`),
    CONSTRAINT `fk_owner_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `owner_subscription_plans` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(100) NOT NULL,
    `code` VARCHAR(50) NOT NULL UNIQUE,
    `billing_cycle` ENUM('one_time', 'monthly', 'per_transaction') NOT NULL DEFAULT 'monthly',
    `price` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    `trial_days` INT UNSIGNED NOT NULL DEFAULT 0,
    `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
    `created_at` TIMESTAMP NULL DEFAULT NULL,
    `updated_at` TIMESTAMP NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `owner_subscriptions` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `owner_profile_id` BIGINT UNSIGNED NOT NULL,
    `plan_id` BIGINT UNSIGNED NOT NULL,
    `plan_price_snapshot` DECIMAL(10, 2) NOT NULL,
    `status` ENUM('trialing', 'active', 'past_due', 'cancelled') NOT NULL DEFAULT 'trialing',
    `starts_at` TIMESTAMP NOT NULL,
    `ends_at` TIMESTAMP NULL DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT NULL,
    `updated_at` TIMESTAMP NULL DEFAULT NULL,
    INDEX `idx_sub_owner` (`owner_profile_id`),
    INDEX `idx_sub_status` (`status`),
    CONSTRAINT `fk_sub_owner` FOREIGN KEY (`owner_profile_id`) REFERENCES `owner_profiles` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_sub_plan` FOREIGN KEY (`plan_id`) REFERENCES `owner_subscription_plans` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ------------------------------------------------------------------------------
-- MODUL 3: INVENTORI MOTOSIKAL & HARGA (MOTORCYCLES & PRICING)
-- ------------------------------------------------------------------------------

DROP TABLE IF EXISTS `rental_price_ledger`;
DROP TABLE IF EXISTS `rental_rates`;
DROP TABLE IF EXISTS `motorcycle_images`;
DROP TABLE IF EXISTS `motorcycles`;

CREATE TABLE `motorcycles` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `owner_profile_id` BIGINT UNSIGNED NOT NULL,
    `brand` VARCHAR(100) NOT NULL,
    `model` VARCHAR(150) NOT NULL,
    `registration_number` VARCHAR(50) NOT NULL,
    `category` VARCHAR(50) NOT NULL,
    `engine_cc` INT UNSIGNED NULL,
    `description` TEXT NULL,
    `pickup_location` VARCHAR(255) NOT NULL,
    `status` ENUM('draft', 'published', 'maintenance', 'inactive') NOT NULL DEFAULT 'draft',
    `created_at` TIMESTAMP NULL DEFAULT NULL,
    `updated_at` TIMESTAMP NULL DEFAULT NULL,
    INDEX `idx_moto_owner` (`owner_profile_id`),
    INDEX `idx_moto_status` (`status`),
    INDEX `idx_moto_category` (`category`),
    CONSTRAINT `fk_moto_owner` FOREIGN KEY (`owner_profile_id`) REFERENCES `owner_profiles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `motorcycle_images` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `motorcycle_id` BIGINT UNSIGNED NOT NULL,
    `path` VARCHAR(255) NOT NULL,
    `sort_order` INT NOT NULL DEFAULT 0,
    `is_primary` BOOLEAN NOT NULL DEFAULT FALSE,
    `created_at` TIMESTAMP NULL DEFAULT NULL,
    `updated_at` TIMESTAMP NULL DEFAULT NULL,
    INDEX `idx_img_moto` (`motorcycle_id`),
    CONSTRAINT `fk_img_moto` FOREIGN KEY (`motorcycle_id`) REFERENCES `motorcycles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `rental_rates` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `motorcycle_id` BIGINT UNSIGNED NOT NULL,
    `day_type` ENUM('weekday', 'weekend', 'all') NOT NULL DEFAULT 'all',
    `duration_hours` INT UNSIGNED NOT NULL,
    `price` DECIMAL(10, 2) NOT NULL,
    `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
    `valid_from` DATE NULL,
    `valid_until` DATE NULL,
    `created_at` TIMESTAMP NULL DEFAULT NULL,
    `updated_at` TIMESTAMP NULL DEFAULT NULL,
    INDEX `idx_rates_moto_duration` (`motorcycle_id`, `duration_hours`, `day_type`),
    CONSTRAINT `fk_rates_moto` FOREIGN KEY (`motorcycle_id`) REFERENCES `motorcycles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `rental_price_ledger` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `motorcycle_id` BIGINT UNSIGNED NOT NULL,
    `changed_by_user_id` BIGINT UNSIGNED NOT NULL,
    `change_type` VARCHAR(50) NOT NULL,
    `old_values` JSON NULL,
    `new_values` JSON NOT NULL,
    `valid_from` TIMESTAMP NULL DEFAULT NULL,
    `valid_until` TIMESTAMP NULL DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_price_ledger_moto` (`motorcycle_id`),
    CONSTRAINT `fk_ledger_moto` FOREIGN KEY (`motorcycle_id`) REFERENCES `motorcycles` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_ledger_user` FOREIGN KEY (`changed_by_user_id`) REFERENCES `users` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ------------------------------------------------------------------------------
-- MODUL 4: PENGURUSAN TEMPAHAN & KETERSEDIAAN (BOOKING DOMAIN - DECOUPLED)
-- Tiada medan gerbang pembayaran disimpan di sini bagi menjamin pemisahan logik.
-- ------------------------------------------------------------------------------

DROP TABLE IF EXISTS `booking_status_histories`;
DROP TABLE IF EXISTS `renter_licenses`;
DROP TABLE IF EXISTS `bookings`;

CREATE TABLE `bookings` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `booking_reference` VARCHAR(32) NOT NULL UNIQUE,
    `renter_id` BIGINT UNSIGNED NOT NULL,
    `owner_profile_id` BIGINT UNSIGNED NOT NULL,
    `motorcycle_id` BIGINT UNSIGNED NOT NULL,
    `source` ENUM('marketplace', 'owner_manual') NOT NULL DEFAULT 'marketplace',
    `start_at` DATETIME NOT NULL,
    `end_at` DATETIME NOT NULL,
    `status` ENUM(
        'pending_payment',
        'confirmed',
        'ready_for_pickup',
        'ongoing',
        'completed',
        'cancellation_pending',
        'cancelled',
        'expired',
        'rejected'
    ) NOT NULL DEFAULT 'pending_payment',
    `hold_expires_at` DATETIME NULL,
    `rental_amount` DECIMAL(10, 2) NOT NULL,
    `deposit_amount` DECIMAL(10, 2) NOT NULL DEFAULT 50.00,
    `fee_amount` DECIMAL(10, 2) NOT NULL DEFAULT 2.00,
    `total_amount` DECIMAL(10, 2) NOT NULL,
    `currency` VARCHAR(3) NOT NULL DEFAULT 'MYR',
    `pricing_snapshot` JSON NOT NULL,
    `cancellation_policy_snapshot` JSON NOT NULL,
    `pickup_notes` TEXT NULL,
    `picked_up_at` DATETIME NULL,
    `returned_at` DATETIME NULL,
    `cancellation_requested_at` DATETIME NULL,
    `cancelled_at` DATETIME NULL,
    `cancellation_reason` TEXT NULL,
    `created_by_user_id` BIGINT UNSIGNED NOT NULL,
    `created_at` TIMESTAMP NULL DEFAULT NULL,
    `updated_at` TIMESTAMP NULL DEFAULT NULL,
    INDEX `idx_booking_overlap` (`motorcycle_id`, `start_at`, `end_at`, `status`),
    INDEX `idx_booking_renter` (`renter_id`),
    INDEX `idx_booking_owner` (`owner_profile_id`),
    INDEX `idx_booking_status` (`status`),
    INDEX `idx_booking_hold` (`hold_expires_at`),
    CONSTRAINT `fk_book_renter` FOREIGN KEY (`renter_id`) REFERENCES `users` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_book_owner` FOREIGN KEY (`owner_profile_id`) REFERENCES `owner_profiles` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_book_moto` FOREIGN KEY (`motorcycle_id`) REFERENCES `motorcycles` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_book_creator` FOREIGN KEY (`created_by_user_id`) REFERENCES `users` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `renter_licenses` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `booking_id` BIGINT UNSIGNED NOT NULL,
    `motorcycle_id` BIGINT UNSIGNED NOT NULL,
    `renter_id` BIGINT UNSIGNED NOT NULL,
    `file_path` VARCHAR(255) NOT NULL,
    `verification_status` ENUM('pending', 'accepted', 'rejected') NOT NULL DEFAULT 'pending',
    `reviewed_by_user_id` BIGINT UNSIGNED NULL,
    `reviewed_at` TIMESTAMP NULL DEFAULT NULL,
    `rejection_reason` VARCHAR(255) NULL,
    `created_at` TIMESTAMP NULL DEFAULT NULL,
    `updated_at` TIMESTAMP NULL DEFAULT NULL,
    INDEX `idx_license_booking` (`booking_id`),
    INDEX `idx_license_renter` (`renter_id`),
    CONSTRAINT `fk_lic_booking` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_lic_moto` FOREIGN KEY (`motorcycle_id`) REFERENCES `motorcycles` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_lic_renter` FOREIGN KEY (`renter_id`) REFERENCES `users` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_lic_reviewer` FOREIGN KEY (`reviewed_by_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `booking_status_histories` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `booking_id` BIGINT UNSIGNED NOT NULL,
    `from_status` VARCHAR(50) NULL,
    `to_status` VARCHAR(50) NOT NULL,
    `changed_by_user_id` BIGINT UNSIGNED NULL,
    `reason` TEXT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_hist_booking` (`booking_id`),
    CONSTRAINT `fk_hist_booking` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_hist_user` FOREIGN KEY (`changed_by_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ------------------------------------------------------------------------------
-- MODUL 5: PEMBAYARAN, PENYATA & REFUND (PAYMENT DOMAIN - DECOUPLED)
-- Mengendalikan kewangan, webhook gateway, dan penjejakan settlement secara berasingan.
-- ------------------------------------------------------------------------------

DROP TABLE IF EXISTS `settlements`;
DROP TABLE IF EXISTS `refunds`;
DROP TABLE IF EXISTS `payment_webhook_events`;
DROP TABLE IF EXISTS `payments`;

CREATE TABLE `payments` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `payment_reference` VARCHAR(64) NOT NULL UNIQUE,
    `booking_id` BIGINT UNSIGNED NOT NULL,
    `provider` ENUM('affanpay', 'manual') NOT NULL,
    `method` ENUM('online', 'cash', 'qr_manual') NOT NULL,
    `provider_reference` VARCHAR(150) NULL,
    `amount` DECIMAL(10, 2) NOT NULL,
    `currency` VARCHAR(3) NOT NULL DEFAULT 'MYR',
    `status` ENUM(
        'pending',
        'paid',
        'failed',
        'cancelled',
        'refund_pending',
        'partially_refunded',
        'refunded'
    ) NOT NULL DEFAULT 'pending',
    `paid_at` DATETIME NULL,
    `recorded_by_user_id` BIGINT UNSIGNED NULL,
    `notes` TEXT NULL,
    `created_at` TIMESTAMP NULL DEFAULT NULL,
    `updated_at` TIMESTAMP NULL DEFAULT NULL,
    INDEX `idx_pay_booking` (`booking_id`),
    INDEX `idx_pay_status` (`status`),
    INDEX `idx_pay_provider_ref` (`provider`, `provider_reference`),
    CONSTRAINT `fk_pay_booking` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_pay_recorder` FOREIGN KEY (`recorded_by_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `payment_webhook_events` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `provider` VARCHAR(50) NOT NULL,
    `event_id` VARCHAR(150) NOT NULL,
    `booking_reference` VARCHAR(32) NULL,
    `event_type` VARCHAR(100) NOT NULL,
    `processing_status` ENUM('received', 'processed', 'ignored', 'failed') NOT NULL DEFAULT 'received',
    `payload_redacted` JSON NOT NULL,
    `received_at` DATETIME NOT NULL,
    `processed_at` DATETIME NULL,
    UNIQUE KEY `uq_provider_event` (`provider`, `event_id`),
    INDEX `idx_wh_booking_ref` (`booking_reference`),
    INDEX `idx_wh_status` (`processing_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `refunds` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `refund_reference` VARCHAR(64) NOT NULL UNIQUE,
    `booking_id` BIGINT UNSIGNED NOT NULL,
    `payment_id` BIGINT UNSIGNED NOT NULL,
    `amount` DECIMAL(10, 2) NOT NULL,
    `eligible_amount` DECIMAL(10, 2) NOT NULL,
    `percentage` DECIMAL(5, 2) NOT NULL,
    `reason` TEXT NULL,
    `status` ENUM('pending', 'processing', 'completed', 'failed', 'manual_review') NOT NULL DEFAULT 'pending',
    `provider_reference` VARCHAR(150) NULL,
    `requested_at` DATETIME NOT NULL,
    `processed_at` DATETIME NULL,
    `processed_by_user_id` BIGINT UNSIGNED NULL,
    `created_at` TIMESTAMP NULL DEFAULT NULL,
    `updated_at` TIMESTAMP NULL DEFAULT NULL,
    INDEX `idx_ref_booking` (`booking_id`),
    INDEX `idx_ref_payment` (`payment_id`),
    INDEX `idx_ref_status` (`status`),
    CONSTRAINT `fk_ref_booking` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_ref_payment` FOREIGN KEY (`payment_id`) REFERENCES `payments` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_ref_processor` FOREIGN KEY (`processed_by_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `settlements` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `booking_id` BIGINT UNSIGNED NOT NULL,
    `owner_profile_id` BIGINT UNSIGNED NOT NULL,
    `gross_amount` DECIMAL(10, 2) NOT NULL,
    `fee_deducted` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    `net_payout_amount` DECIMAL(10, 2) NOT NULL,
    `status` ENUM(
        'pending_affanpay_release',
        'platform_received',
        'pending_owner_release',
        'released_to_owner',
        'failed',
        'manual_review'
    ) NOT NULL DEFAULT 'pending_affanpay_release',
    `affanpay_released_at` DATETIME NULL,
    `owner_release_due_at` DATETIME NOT NULL,
    `owner_released_at` DATETIME NULL,
    `payout_reference` VARCHAR(150) NULL,
    `created_at` TIMESTAMP NULL DEFAULT NULL,
    `updated_at` TIMESTAMP NULL DEFAULT NULL,
    INDEX `idx_settle_booking` (`booking_id`),
    INDEX `idx_settle_owner` (`owner_profile_id`),
    INDEX `idx_settle_status` (`status`),
    INDEX `idx_settle_due` (`owner_release_due_at`),
    CONSTRAINT `fk_settle_booking` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_settle_owner` FOREIGN KEY (`owner_profile_id`) REFERENCES `owner_profiles` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;
