-- Thandal MySQL 8 schema (generated from schema_dsl.py, do not edit by hand)
-- Money is stored in paise (1 rupee = 100 paise). All FKs are RESTRICT: financial data is never deleted.
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS=0;

-- Login identity for every role. Mobile number + hashed 4-digit PIN. Admin self-registrations are rows with role=admin and status=pending until a super admin approves.
CREATE TABLE `users` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `role` ENUM('customer','agent','admin','super_admin') NOT NULL,
  `name` VARCHAR(120) NOT NULL,
  `mobile` CHAR(10) NOT NULL COMMENT '10 digits, unique across all roles',
  `pin_hash` VARCHAR(255) NOT NULL COMMENT 'bcrypt hash, never the PIN',
  `status` ENUM('pending','active','inactive','rejected') NOT NULL DEFAULT 'active',
  `must_change_pin` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1 after an admin resets the PIN (temporary PIN)',
  `failed_attempts` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `locked_until` DATETIME NULL DEFAULT NULL COMMENT 'set after 3 wrong PINs, 15 minutes',
  `last_login_at` DATETIME NULL DEFAULT NULL,
  `decided_by` BIGINT UNSIGNED NULL DEFAULT NULL,
  `decided_at` DATETIME NULL DEFAULT NULL COMMENT 'admin registration decision',
  `decision_note` VARCHAR(255) NULL DEFAULT NULL,
  `created_by` BIGINT UNSIGNED NULL DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `users_mobile_unique` (`mobile`),
  KEY `users_decided_by_index` (`decided_by`),
  CONSTRAINT `users_decided_by_foreign` FOREIGN KEY (`decided_by`) REFERENCES `users` (`id`) ON DELETE RESTRICT,
  KEY `users_created_by_index` (`created_by`),
  CONSTRAINT `users_created_by_foreign` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE RESTRICT,
  KEY `users_role_status_index` (`role`,`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Agent profile.
CREATE TABLE `agents` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT UNSIGNED NOT NULL,
  `agent_code` VARCHAR(20) NOT NULL COMMENT 'AGT-007',
  `address` TEXT NOT NULL,
  `joined_on` DATE NOT NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `agents_user_id_unique` (`user_id`),
  UNIQUE KEY `agents_agent_code_unique` (`agent_code`),
  CONSTRAINT `agents_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Customer profile. agent_id is the CURRENT agent (history lives in agent_assignments).
CREATE TABLE `customers` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT UNSIGNED NOT NULL,
  `customer_code` VARCHAR(20) NOT NULL COMMENT 'THD-10245',
  `address` TEXT NOT NULL,
  `agent_id` BIGINT UNSIGNED NULL DEFAULT NULL,
  `joined_on` DATE NOT NULL,
  `created_by` BIGINT UNSIGNED NOT NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `customers_user_id_unique` (`user_id`),
  UNIQUE KEY `customers_customer_code_unique` (`customer_code`),
  CONSTRAINT `customers_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `customers_agent_id_foreign` FOREIGN KEY (`agent_id`) REFERENCES `agents` (`id`) ON DELETE RESTRICT,
  KEY `customers_created_by_index` (`created_by`),
  CONSTRAINT `customers_created_by_foreign` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE RESTRICT,
  KEY `customers_agent_id_index` (`agent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ID proof of a customer or an agent (any one type). Number is encrypted, file is in private storage.
CREATE TABLE `identity_documents` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `customer_id` BIGINT UNSIGNED NULL DEFAULT NULL,
  `agent_id` BIGINT UNSIGNED NULL DEFAULT NULL,
  `doc_type` ENUM('aadhaar_card','pan_card','voter_id','driving_licence','passport','ration_card') NOT NULL,
  `number_encrypted` TEXT NOT NULL COMMENT 'Laravel Crypt, never shown in full',
  `number_last4` CHAR(4) NOT NULL,
  `file_path` VARCHAR(255) NOT NULL COMMENT 'private disk path',
  `file_mime` VARCHAR(60) NOT NULL,
  `file_size_bytes` INT UNSIGNED NOT NULL,
  `is_current` TINYINT(1) NOT NULL DEFAULT 1,
  `uploaded_by` BIGINT UNSIGNED NOT NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `identity_documents_customer_id_foreign` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `identity_documents_agent_id_foreign` FOREIGN KEY (`agent_id`) REFERENCES `agents` (`id`) ON DELETE RESTRICT,
  KEY `identity_documents_uploaded_by_index` (`uploaded_by`),
  CONSTRAINT `identity_documents_uploaded_by_foreign` FOREIGN KEY (`uploaded_by`) REFERENCES `users` (`id`) ON DELETE RESTRICT,
  KEY `identity_documents_customer_id_is_current_index` (`customer_id`,`is_current`),
  KEY `identity_documents_agent_id_is_current_index` (`agent_id`,`is_current`),
  CONSTRAINT `chk_identity_owner` CHECK ((customer_id IS NULL) <> (agent_id IS NULL))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Who looked after a customer and when. Past rows are never edited.
CREATE TABLE `agent_assignments` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `customer_id` BIGINT UNSIGNED NOT NULL,
  `agent_id` BIGINT UNSIGNED NOT NULL,
  `assigned_by` BIGINT UNSIGNED NOT NULL,
  `assigned_on` DATE NOT NULL,
  `ended_on` DATE NULL DEFAULT NULL,
  `reason` VARCHAR(120) NULL DEFAULT NULL,
  `active_customer_id` BIGINT UNSIGNED NULL DEFAULT NULL COMMENT '= customer_id while current, NULL after. Unique => one current agent per customer',
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `agent_assignments_active_customer_id_unique` (`active_customer_id`),
  CONSTRAINT `agent_assignments_customer_id_foreign` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `agent_assignments_agent_id_foreign` FOREIGN KEY (`agent_id`) REFERENCES `agents` (`id`) ON DELETE RESTRICT,
  KEY `agent_assignments_assigned_by_index` (`assigned_by`),
  CONSTRAINT `agent_assignments_assigned_by_foreign` FOREIGN KEY (`assigned_by`) REFERENCES `users` (`id`) ON DELETE RESTRICT,
  KEY `agent_assignments_customer_id_assigned_on_index` (`customer_id`,`assigned_on`),
  KEY `agent_assignments_agent_id_index` (`agent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- A loan and its repayment plan. Total = installment x count. Created Pending; Active after a completed disbursement.
CREATE TABLE `chits` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `chit_code` VARCHAR(20) NOT NULL COMMENT 'THD-1001',
  `customer_id` BIGINT UNSIGNED NOT NULL,
  `created_by` BIGINT UNSIGNED NOT NULL,
  `loan_amount_paise` BIGINT UNSIGNED NOT NULL COMMENT 'amount given to the customer',
  `frequency` ENUM('daily','weekly','monthly') NOT NULL,
  `installment_count` SMALLINT UNSIGNED NOT NULL,
  `installment_amount_paise` BIGINT UNSIGNED NOT NULL COMMENT 'set by the admin/agent',
  `total_repayment_paise` BIGINT UNSIGNED NOT NULL COMMENT '= installment_count x installment_amount_paise',
  `paid_paise` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'cache, kept in the same transaction as payments',
  `paid_installments` SMALLINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'cache',
  `start_date` DATE NOT NULL COMMENT 'first installment is due on this date',
  `end_date` DATE NOT NULL,
  `status` ENUM('pending','active','completed','cancelled') NOT NULL DEFAULT 'pending',
  `activated_at` DATETIME NULL DEFAULT NULL,
  `completed_at` DATETIME NULL DEFAULT NULL,
  `cancelled_at` DATETIME NULL DEFAULT NULL,
  `cancel_reason` VARCHAR(255) NULL DEFAULT NULL,
  `notes` TEXT NULL DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `chits_chit_code_unique` (`chit_code`),
  CONSTRAINT `chits_customer_id_foreign` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`) ON DELETE RESTRICT,
  KEY `chits_created_by_index` (`created_by`),
  CONSTRAINT `chits_created_by_foreign` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE RESTRICT,
  KEY `chits_customer_id_status_index` (`customer_id`,`status`),
  KEY `chits_status_start_date_index` (`status`,`start_date`),
  CONSTRAINT `chk_chits_count` CHECK (installment_count > 0),
  CONSTRAINT `chk_chits_amount` CHECK (installment_amount_paise > 0),
  CONSTRAINT `chk_chits_total` CHECK (total_repayment_paise = installment_count * installment_amount_paise),
  CONSTRAINT `chk_chits_paid` CHECK (paid_paise <= total_repayment_paise)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- The repayment schedule, one row per due date. "Overdue" is derived: due_date < today (IST) and not paid.
CREATE TABLE `chit_installments` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `chit_id` BIGINT UNSIGNED NOT NULL,
  `sequence` SMALLINT UNSIGNED NOT NULL,
  `due_date` DATE NOT NULL,
  `amount_paise` BIGINT UNSIGNED NOT NULL,
  `paid_paise` BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `status` ENUM('upcoming','partially_paid','paid','cancelled') NOT NULL DEFAULT 'upcoming',
  `paid_at` DATETIME NULL DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `chit_installments_chit_id_sequence_unique` (`chit_id`,`sequence`),
  CONSTRAINT `chit_installments_chit_id_foreign` FOREIGN KEY (`chit_id`) REFERENCES `chits` (`id`) ON DELETE RESTRICT,
  KEY `chit_installments_due_date_status_index` (`due_date`,`status`),
  KEY `chit_installments_chit_id_status_index` (`chit_id`,`status`),
  CONSTRAINT `chk_inst_paid` CHECK (paid_paise <= amount_paise)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Loan amount given to the customer (cash or bank transfer). A failed attempt leaves the chit Pending.
CREATE TABLE `disbursements` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `chit_id` BIGINT UNSIGNED NOT NULL,
  `method` ENUM('cash','bank_transfer') NULL DEFAULT NULL,
  `amount_paise` BIGINT UNSIGNED NOT NULL,
  `status` ENUM('pending','completed','failed') NOT NULL DEFAULT 'pending',
  `disbursed_on` DATE NULL DEFAULT NULL,
  `reference` VARCHAR(60) NULL DEFAULT NULL COMMENT 'required for bank transfer',
  `note` VARCHAR(255) NULL DEFAULT NULL,
  `recorded_by` BIGINT UNSIGNED NULL DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `disbursements_chit_id_foreign` FOREIGN KEY (`chit_id`) REFERENCES `chits` (`id`) ON DELETE RESTRICT,
  KEY `disbursements_recorded_by_index` (`recorded_by`),
  CONSTRAINT `disbursements_recorded_by_foreign` FOREIGN KEY (`recorded_by`) REFERENCES `users` (`id`) ON DELETE RESTRICT,
  KEY `disbursements_chit_id_status_index` (`chit_id`,`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- One row per money received. Confirmed rows are immutable: fixes are made with payment_adjustments.
CREATE TABLE `payments` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `receipt_number` VARCHAR(24) NULL DEFAULT NULL COMMENT 'THD-RCP-000231, given when confirmed',
  `chit_id` BIGINT UNSIGNED NOT NULL,
  `customer_id` BIGINT UNSIGNED NOT NULL,
  `method` ENUM('cash','online') NOT NULL,
  `status` ENUM('pending','confirmed','failed','reversed') NOT NULL,
  `amount_paise` BIGINT UNSIGNED NOT NULL COMMENT 'amount as first recorded',
  `net_amount_paise` BIGINT UNSIGNED NULL DEFAULT NULL COMMENT 'amount after approved corrections; NULL = unchanged (effective = COALESCE(net, amount))',
  `paid_at` DATETIME NULL DEFAULT NULL,
  `collected_by_agent_id` BIGINT UNSIGNED NULL DEFAULT NULL,
  `recorded_by` BIGINT UNSIGNED NULL DEFAULT NULL,
  `razorpay_order_id` VARCHAR(40) NULL DEFAULT NULL,
  `razorpay_payment_id` VARCHAR(40) NULL DEFAULT NULL,
  `failure_reason` VARCHAR(255) NULL DEFAULT NULL,
  `client_request_id` VARCHAR(64) NULL DEFAULT NULL COMMENT 'sent by the app; blocks double taps and repeat submits',
  `notes` VARCHAR(255) NULL DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `payments_receipt_number_unique` (`receipt_number`),
  UNIQUE KEY `payments_razorpay_order_id_unique` (`razorpay_order_id`),
  UNIQUE KEY `payments_razorpay_payment_id_unique` (`razorpay_payment_id`),
  UNIQUE KEY `payments_client_request_id_unique` (`client_request_id`),
  CONSTRAINT `payments_chit_id_foreign` FOREIGN KEY (`chit_id`) REFERENCES `chits` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `payments_customer_id_foreign` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `payments_collected_by_agent_id_foreign` FOREIGN KEY (`collected_by_agent_id`) REFERENCES `agents` (`id`) ON DELETE RESTRICT,
  KEY `payments_recorded_by_index` (`recorded_by`),
  CONSTRAINT `payments_recorded_by_foreign` FOREIGN KEY (`recorded_by`) REFERENCES `users` (`id`) ON DELETE RESTRICT,
  KEY `payments_chit_id_paid_at_index` (`chit_id`,`paid_at`),
  KEY `payments_customer_id_paid_at_index` (`customer_id`,`paid_at`),
  KEY `payments_collected_by_agent_id_paid_at_index` (`collected_by_agent_id`,`paid_at`),
  KEY `payments_status_paid_at_index` (`status`,`paid_at`),
  CONSTRAINT `chk_pay_amount` CHECK (amount_paise > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Agent asks the admin to fix a confirmed payment.
CREATE TABLE `correction_requests` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(20) NOT NULL COMMENT 'CR-041',
  `payment_id` BIGINT UNSIGNED NOT NULL,
  `requested_by_agent_id` BIGINT UNSIGNED NOT NULL,
  `reason` ENUM('wrong_amount','wrong_customer_or_chit','duplicate_entry','other') NOT NULL,
  `requested_amount_paise` BIGINT UNSIGNED NULL DEFAULT NULL,
  `note` TEXT NOT NULL,
  `status` ENUM('pending','approved','rejected') NOT NULL DEFAULT 'pending',
  `resolution_chit_id` BIGINT UNSIGNED NULL DEFAULT NULL,
  `decided_by` BIGINT UNSIGNED NULL DEFAULT NULL,
  `decided_at` DATETIME NULL DEFAULT NULL,
  `decision_note` TEXT NULL DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `correction_requests_code_unique` (`code`),
  KEY `correction_requests_payment_id_index` (`payment_id`),
  CONSTRAINT `correction_requests_payment_id_foreign` FOREIGN KEY (`payment_id`) REFERENCES `payments` (`id`) ON DELETE RESTRICT,
  KEY `correction_requests_requested_by_agent_id_index` (`requested_by_agent_id`),
  CONSTRAINT `correction_requests_requested_by_agent_id_foreign` FOREIGN KEY (`requested_by_agent_id`) REFERENCES `agents` (`id`) ON DELETE RESTRICT,
  KEY `correction_requests_resolution_chit_id_index` (`resolution_chit_id`),
  CONSTRAINT `correction_requests_resolution_chit_id_foreign` FOREIGN KEY (`resolution_chit_id`) REFERENCES `chits` (`id`) ON DELETE RESTRICT,
  KEY `correction_requests_decided_by_index` (`decided_by`),
  CONSTRAINT `correction_requests_decided_by_foreign` FOREIGN KEY (`decided_by`) REFERENCES `users` (`id`) ON DELETE RESTRICT,
  KEY `correction_requests_status_created_at_index` (`status`,`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Append-only record of every correction applied to a payment (nothing is deleted).
CREATE TABLE `payment_adjustments` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `payment_id` BIGINT UNSIGNED NOT NULL,
  `correction_request_id` BIGINT UNSIGNED NULL DEFAULT NULL,
  `type` ENUM('amount_change','reversal','moved_to_other_chit') NOT NULL,
  `delta_paise` BIGINT NOT NULL COMMENT 'signed change to the payment amount',
  `created_by` BIGINT UNSIGNED NOT NULL,
  `reason` VARCHAR(255) NOT NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `payment_adjustments_payment_id_index` (`payment_id`),
  CONSTRAINT `payment_adjustments_payment_id_foreign` FOREIGN KEY (`payment_id`) REFERENCES `payments` (`id`) ON DELETE RESTRICT,
  KEY `payment_adjustments_correction_request_id_index` (`correction_request_id`),
  CONSTRAINT `payment_adjustments_correction_request_id_foreign` FOREIGN KEY (`correction_request_id`) REFERENCES `correction_requests` (`id`) ON DELETE RESTRICT,
  KEY `payment_adjustments_created_by_index` (`created_by`),
  CONSTRAINT `payment_adjustments_created_by_foreign` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- How a payment was applied to installments. Signed: reversals are negative rows linked to an adjustment.
CREATE TABLE `payment_allocations` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `payment_id` BIGINT UNSIGNED NOT NULL,
  `installment_id` BIGINT UNSIGNED NOT NULL,
  `amount_paise` BIGINT NOT NULL,
  `adjustment_id` BIGINT UNSIGNED NULL DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `payment_allocations_payment_id_foreign` FOREIGN KEY (`payment_id`) REFERENCES `payments` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `payment_allocations_installment_id_foreign` FOREIGN KEY (`installment_id`) REFERENCES `chit_installments` (`id`) ON DELETE RESTRICT,
  KEY `payment_allocations_adjustment_id_index` (`adjustment_id`),
  CONSTRAINT `payment_allocations_adjustment_id_foreign` FOREIGN KEY (`adjustment_id`) REFERENCES `payment_adjustments` (`id`) ON DELETE RESTRICT,
  KEY `payment_allocations_installment_id_index` (`installment_id`),
  KEY `payment_allocations_payment_id_index` (`payment_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Every Razorpay webhook received. event_id is unique so a repeated webhook is processed once.
CREATE TABLE `razorpay_events` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `event_id` VARCHAR(64) NOT NULL,
  `event_type` VARCHAR(60) NOT NULL,
  `payment_id` BIGINT UNSIGNED NULL DEFAULT NULL,
  `payload` JSON NOT NULL,
  `status` ENUM('received','processed','ignored','failed') NOT NULL DEFAULT 'received',
  `processed_at` DATETIME NULL DEFAULT NULL,
  `error` VARCHAR(255) NULL DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `razorpay_events_event_id_unique` (`event_id`),
  KEY `razorpay_events_payment_id_index` (`payment_id`),
  CONSTRAINT `razorpay_events_payment_id_foreign` FOREIGN KEY (`payment_id`) REFERENCES `payments` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Who did what and when. Append-only.
CREATE TABLE `audit_logs` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `actor_user_id` BIGINT UNSIGNED NULL DEFAULT NULL,
  `actor_label` VARCHAR(120) NOT NULL,
  `action` VARCHAR(80) NOT NULL,
  `entity_type` VARCHAR(40) NOT NULL,
  `entity_id` VARCHAR(40) NOT NULL,
  `summary` VARCHAR(500) NOT NULL,
  `before_json` JSON NULL,
  `after_json` JSON NULL,
  `ip_address` VARCHAR(45) NULL DEFAULT NULL,
  `user_agent` VARCHAR(255) NULL DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `audit_logs_actor_user_id_foreign` FOREIGN KEY (`actor_user_id`) REFERENCES `users` (`id`) ON DELETE RESTRICT,
  KEY `audit_logs_entity_type_entity_id_index` (`entity_type`,`entity_id`),
  KEY `audit_logs_actor_user_id_created_at_index` (`actor_user_id`,`created_at`),
  KEY `audit_logs_action_created_at_index` (`action`,`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Gap-free counters for receipt numbers and codes (locked with SELECT ... FOR UPDATE).
CREATE TABLE `sequences` (
  `name` VARCHAR(40) NOT NULL,
  `value` BIGINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Admin-editable settings (support phone, PIN rules, Razorpay mode, ...).
CREATE TABLE `settings` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `setting_key` VARCHAR(80) NOT NULL,
  `value` JSON NOT NULL,
  `updated_by` BIGINT UNSIGNED NULL DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `settings_setting_key_unique` (`setting_key`),
  KEY `settings_updated_by_index` (`updated_by`),
  CONSTRAINT `settings_updated_by_foreign` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Push notification tokens. Push is not used in V1; the table keeps the architecture ready.
CREATE TABLE `device_tokens` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT UNSIGNED NOT NULL,
  `token` VARCHAR(255) NOT NULL,
  `platform` ENUM('android','ios') NOT NULL,
  `last_seen_at` DATETIME NULL DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `device_tokens_token_unique` (`token`),
  KEY `device_tokens_user_id_index` (`user_id`),
  CONSTRAINT `device_tokens_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Framework tables (Laravel Sanctum + database sessions for the admin web)
CREATE TABLE `personal_access_tokens` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tokenable_type` VARCHAR(255) NOT NULL,
  `tokenable_id` BIGINT UNSIGNED NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `token` VARCHAR(64) NOT NULL,
  `abilities` TEXT NULL,
  `last_used_at` TIMESTAMP NULL DEFAULT NULL,
  `expires_at` TIMESTAMP NULL DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `personal_access_tokens_token_unique` (`token`),
  KEY `personal_access_tokens_tokenable_type_tokenable_id_index` (`tokenable_type`,`tokenable_id`),
  KEY `personal_access_tokens_expires_at_index` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `sessions` (
  `id` VARCHAR(255) NOT NULL,
  `user_id` BIGINT UNSIGNED NULL DEFAULT NULL,
  `ip_address` VARCHAR(45) NULL DEFAULT NULL,
  `user_agent` TEXT NULL,
  `payload` LONGTEXT NOT NULL,
  `last_activity` INT NOT NULL,
  PRIMARY KEY (`id`),
  KEY `sessions_user_id_index` (`user_id`),
  KEY `sessions_last_activity_index` (`last_activity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS=1;
