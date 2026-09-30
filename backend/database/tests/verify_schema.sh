#!/bin/bash
mkdir -p /run/mysqld && chown mysql:mysql /run/mysqld
(nohup mysqld_safe --skip-networking >/tmp/mysqld.log 2>&1 &)
for i in $(seq 1 30); do mariadb -e "select 1" >/dev/null 2>&1 && break; sleep 1; done
cd /mnt/user-data/outputs/thandal/backend/database
mariadb -e "DROP DATABASE IF EXISTS thandal_test; CREATE DATABASE thandal_test CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mariadb thandal_test < schema.sql || { echo "SCHEMA FAILED"; exit 1; }
echo "SCHEMA LOADED: $(mariadb thandal_test -N -e "select count(*) from information_schema.tables where table_schema='thandal_test'") tables"
mariadb < /mnt/user-data/outputs/thandal/backend/database/tests/seed_rules.sql >/dev/null
pass=0; fail=0
blocked(){ out=$(mariadb thandal_test -e "$2" 2>&1); rc=$?; if [ $rc -ne 0 ]; then echo "PASS  $1"; pass=$((pass+1)); else echo "FAIL  $1 (was allowed!)"; fail=$((fail+1)); fi; }
ok(){ out=$(mariadb thandal_test -e "$2" 2>&1); rc=$?; if [ $rc -eq 0 ]; then echo "PASS  $1"; pass=$((pass+1)); else echo "FAIL  $1: $out"; fail=$((fail+1)); fi; }
blocked "duplicate mobile number" "INSERT INTO users(role,name,mobile,pin_hash) VALUES ('customer','X','9876543210','x');"
blocked "chit total must equal installment x count" "INSERT INTO chits(chit_code,customer_id,created_by,loan_amount_paise,frequency,installment_count,installment_amount_paise,total_repayment_paise,start_date,end_date) VALUES ('THD-9',1,1,1,'daily',10,100,999,'2026-01-01','2026-01-10');"
ok "valid installment row" "INSERT INTO chit_installments(chit_id,sequence,due_date,amount_paise) VALUES (1,1,'2026-07-31',12000);"
blocked "installment cannot be over-paid" "UPDATE chit_installments SET paid_paise=13000 WHERE id=1;"
blocked "duplicate installment number in a chit" "INSERT INTO chit_installments(chit_id,sequence,due_date,amount_paise) VALUES (1,1,'2026-08-01',12000);"
blocked "zero-amount payment" "INSERT INTO payments(chit_id,customer_id,method,status,amount_paise) VALUES (1,1,'cash','confirmed',0);"
ok "valid cash payment" "INSERT INTO payments(receipt_number,chit_id,customer_id,method,status,amount_paise,paid_at,collected_by_agent_id,client_request_id) VALUES ('THD-RCP-000231',1,1,'cash','confirmed',12000,NOW(),1,'req-1');"
blocked "duplicate receipt number" "INSERT INTO payments(receipt_number,chit_id,customer_id,method,status,amount_paise) VALUES ('THD-RCP-000231',1,1,'cash','confirmed',12000);"
blocked "double-submit (same client_request_id)" "INSERT INTO payments(chit_id,customer_id,method,status,amount_paise,client_request_id) VALUES (1,1,'cash','confirmed',12000,'req-1');"
blocked "same Razorpay payment id twice" "INSERT INTO payments(chit_id,customer_id,method,status,amount_paise,razorpay_payment_id) VALUES (1,1,'online','pending',100,'pay_A'),(1,1,'online','pending',100,'pay_A');"
ok "first webhook event" "INSERT INTO razorpay_events(event_id,event_type,payload) VALUES ('evt_1','payment.captured','{}');"
blocked "repeat webhook event" "INSERT INTO razorpay_events(event_id,event_type,payload) VALUES ('evt_1','payment.captured','{}');"
blocked "ID proof with no owner" "INSERT INTO identity_documents(doc_type,number_encrypted,number_last4,file_path,file_mime,file_size_bytes,uploaded_by) VALUES ('pan_card','x','1234','p','image/jpeg',10,1);"
blocked "ID proof with two owners" "INSERT INTO identity_documents(customer_id,agent_id,doc_type,number_encrypted,number_last4,file_path,file_mime,file_size_bytes,uploaded_by) VALUES (1,1,'pan_card','x','1234','p','image/jpeg',10,1);"
ok "ID proof for a customer" "INSERT INTO identity_documents(customer_id,doc_type,number_encrypted,number_last4,file_path,file_mime,file_size_bytes,uploaded_by) VALUES (1,'aadhaar_card','x','3421','p','image/jpeg',10,1);"
ok "first agent assignment" "INSERT INTO agent_assignments(customer_id,agent_id,assigned_by,assigned_on,active_customer_id) VALUES (1,1,1,'2026-07-28',1);"
blocked "two current agents for one customer" "INSERT INTO agent_assignments(customer_id,agent_id,assigned_by,assigned_on,active_customer_id) VALUES (1,1,1,'2026-09-02',1);"
ok "transfer: end old row, add new current row" "UPDATE agent_assignments SET ended_on='2026-09-02',active_customer_id=NULL WHERE id=1; INSERT INTO agent_assignments(customer_id,agent_id,assigned_by,assigned_on,active_customer_id) VALUES (1,1,1,'2026-09-02',1);"
echo "      history rows kept: $(mariadb thandal_test -N -e 'select count(*) from agent_assignments')"
blocked "customer with a chit cannot be deleted" "DELETE FROM customers WHERE id=1;"
blocked "chit with payments cannot be deleted" "DELETE FROM chits WHERE id=1;"
blocked "payment cannot be deleted while a correction points to it" "INSERT INTO correction_requests(code,payment_id,requested_by_agent_id,reason,note) VALUES ('CR-1',1,1,'wrong_amount','x'); DELETE FROM payments WHERE id=1;"
echo; echo "RESULT: $pass passed, $fail failed"
