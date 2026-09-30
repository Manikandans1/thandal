USE thandal_test;
INSERT INTO users(role,name,mobile,pin_hash,status,created_at) VALUES ('super_admin','Super Admin','9000012345','x','active',NOW()),('agent','Karthik R','9841022017','x','active',NOW()),('customer','Ravi Kumar','9876543210','x','active',NOW());
INSERT INTO agents(user_id,agent_code,address,joined_on,created_at) VALUES (2,'AGT-007','addr','2026-01-12',NOW());
INSERT INTO customers(user_id,customer_code,address,agent_id,joined_on,created_by,created_at) VALUES (3,'THD-10245','addr',1,'2026-07-28',1,NOW());
INSERT INTO chits(chit_code,customer_id,created_by,loan_amount_paise,frequency,installment_count,installment_amount_paise,total_repayment_paise,start_date,end_date,created_at) VALUES ('THD-1001',1,1,1000000,'daily',100,12000,1200000,'2026-07-31','2026-11-07',NOW());
SELECT 'OK chit created' r;
