# Single source of truth for the Thandal database. Generates: MySQL DDL, Laravel migrations, ER diagram, docs tables.
ENUMS = {
 'role':['customer','agent','admin','super_admin'],
 'user_status':['pending','active','inactive','rejected'],
 'doc_type':['aadhaar_card','pan_card','voter_id','driving_licence','passport','ration_card'],
 'frequency':['daily','weekly','monthly'],
 'chit_status':['pending','active','completed','cancelled'],
 'inst_status':['upcoming','partially_paid','paid','cancelled'],
 'disb_method':['cash','bank_transfer'],
 'disb_status':['pending','completed','failed'],
 'pay_method':['cash','online'],
 'pay_status':['pending','confirmed','failed','reversed'],
 'corr_reason':['wrong_amount','wrong_customer_or_chit','duplicate_entry','other'],
 'corr_status':['pending','approved','rejected'],
 'adj_type':['amount_change','reversal','moved_to_other_chit'],
 'rp_event_status':['received','processed','ignored','failed'],
 'platform':['android','ios'],
}
def E(k): return 'enum:'+'|'.join(ENUMS[k])
# column: (name, type, opts)   opts keys: null, unique, default, index, note
def fk(name,table,**o): return (name,'fk:'+table,o)
TABLES = [
 dict(name='users', note='Login identity for every role. Mobile number + hashed 4-digit PIN. Admin self-registrations are rows with role=admin and status=pending until a super admin approves.', cols=[
   ('role',E('role'),{}),('name','str:120',{}),('mobile','char:10',{'unique':1,'note':'10 digits, unique across all roles'}),
   ('pin_hash','str:255',{'note':'bcrypt hash, never the PIN'}),('status',E('user_status'),{'default':'active'}),
   ('must_change_pin','bool',{'default':0,'note':'1 after an admin resets the PIN (temporary PIN)'}),
   ('failed_attempts','utiny',{'default':0}),('locked_until','datetime',{'null':1,'note':'set after 3 wrong PINs, 15 minutes'}),
   ('last_login_at','datetime',{'null':1}),
   fk('decided_by','users',null=1),('decided_at','datetime',{'null':1,'note':'admin registration decision'}),('decision_note','str:255',{'null':1}),
   fk('created_by','users',null=1)],
   indexes=[['role','status']]),
 dict(name='agents', note='Agent profile.', cols=[
   fk('user_id','users',unique=1),('agent_code','str:20',{'unique':1,'note':'AGT-007'}),('address','text',{}),('joined_on','date',{})]),
 dict(name='customers', note='Customer profile. agent_id is the CURRENT agent (history lives in agent_assignments).', cols=[
   fk('user_id','users',unique=1),('customer_code','str:20',{'unique':1,'note':'THD-10245'}),('address','text',{}),
   fk('agent_id','agents',null=1),('joined_on','date',{}),fk('created_by','users')],
   indexes=[['agent_id']]),
 dict(name='identity_documents', note='ID proof of a customer or an agent (any one type). Number is encrypted, file is in private storage.', cols=[
   fk('customer_id','customers',null=1),fk('agent_id','agents',null=1),('doc_type',E('doc_type'),{}),
   ('number_encrypted','text',{'note':'Laravel Crypt, never shown in full'}),('number_last4','char:4',{}),
   ('file_path','str:255',{'note':'private disk path'}),('file_mime','str:60',{}),('file_size_bytes','uint',{}),
   ('is_current','bool',{'default':1}),fk('uploaded_by','users')],
   checks=[('chk_identity_owner','(customer_id IS NULL) <> (agent_id IS NULL)')],indexes=[['customer_id','is_current'],['agent_id','is_current']]),
 dict(name='agent_assignments', note='Who looked after a customer and when. Past rows are never edited.', cols=[
   fk('customer_id','customers'),fk('agent_id','agents'),fk('assigned_by','users'),('assigned_on','date',{}),('ended_on','date',{'null':1}),
   ('reason','str:120',{'null':1}),('active_customer_id','money',{'null':1,'unique':1,'note':'= customer_id while current, NULL after. Unique => one current agent per customer'})],
   indexes=[['customer_id','assigned_on'],['agent_id']]),
 dict(name='chits', note='A loan and its repayment plan. Total = installment x count. Created Pending; Active after a completed disbursement.', cols=[
   ('chit_code','str:20',{'unique':1,'note':'THD-1001'}),fk('customer_id','customers'),fk('created_by','users'),
   ('loan_amount_paise','money',{'note':'amount given to the customer'}),('frequency',E('frequency'),{}),
   ('installment_count','usmall',{}),('installment_amount_paise','money',{'note':'set by the admin/agent'}),
   ('total_repayment_paise','money',{'note':'= installment_count x installment_amount_paise'}),
   ('paid_paise','money',{'default':0,'note':'cache, kept in the same transaction as payments'}),('paid_installments','usmall',{'default':0,'note':'cache'}),
   ('start_date','date',{'note':'first installment is due on this date'}),('end_date','date',{}),
   ('status',E('chit_status'),{'default':'pending'}),('activated_at','datetime',{'null':1}),('completed_at','datetime',{'null':1}),
   ('cancelled_at','datetime',{'null':1}),('cancel_reason','str:255',{'null':1}),('notes','text',{'null':1})],
   checks=[('chk_chits_count','installment_count > 0'),('chk_chits_amount','installment_amount_paise > 0'),
           ('chk_chits_total','total_repayment_paise = installment_count * installment_amount_paise'),
           ('chk_chits_paid','paid_paise <= total_repayment_paise')],
   indexes=[['customer_id','status'],['status','start_date']]),
 dict(name='chit_installments', note='The repayment schedule, one row per due date. "Overdue" is derived: due_date < today (IST) and not paid.', cols=[
   fk('chit_id','chits'),('sequence','usmall',{}),('due_date','date',{}),('amount_paise','money',{}),('paid_paise','money',{'default':0}),
   ('status',E('inst_status'),{'default':'upcoming'}),('paid_at','datetime',{'null':1})],
   uniques=[['chit_id','sequence']],checks=[('chk_inst_paid','paid_paise <= amount_paise')],indexes=[['due_date','status'],['chit_id','status']]),
 dict(name='disbursements', note='Loan amount given to the customer (cash or bank transfer). A failed attempt leaves the chit Pending.', cols=[
   fk('chit_id','chits'),('method',E('disb_method'),{'null':1}),('amount_paise','money',{}),('status',E('disb_status'),{'default':'pending'}),
   ('disbursed_on','date',{'null':1}),('reference','str:60',{'null':1,'note':'required for bank transfer'}),('note','str:255',{'null':1}),fk('recorded_by','users',null=1)],
   indexes=[['chit_id','status']]),
 dict(name='payments', note='One row per money received. Confirmed rows are immutable: fixes are made with payment_adjustments.', cols=[
   ('receipt_number','str:24',{'null':1,'unique':1,'note':'THD-RCP-000231, given when confirmed'}),fk('chit_id','chits'),fk('customer_id','customers'),
   ('method',E('pay_method'),{}),('status',E('pay_status'),{}),('amount_paise','money',{'note':'amount as first recorded'}),('net_amount_paise','money',{'null':1,'note':'amount after approved corrections; NULL = unchanged (effective = COALESCE(net, amount))'}),('paid_at','datetime',{'null':1}),
   fk('collected_by_agent_id','agents',null=1),fk('recorded_by','users',null=1),
   ('razorpay_order_id','str:40',{'null':1,'unique':1}),('razorpay_payment_id','str:40',{'null':1,'unique':1}),
   ('failure_reason','str:255',{'null':1}),('client_request_id','str:64',{'null':1,'unique':1,'note':'sent by the app; blocks double taps and repeat submits'}),('notes','str:255',{'null':1})],
   checks=[('chk_pay_amount','amount_paise > 0')],
   indexes=[['chit_id','paid_at'],['customer_id','paid_at'],['collected_by_agent_id','paid_at'],['status','paid_at']]),
 dict(name='correction_requests', note='Agent asks the admin to fix a confirmed payment.', cols=[
   ('code','str:20',{'unique':1,'note':'CR-041'}),fk('payment_id','payments'),fk('requested_by_agent_id','agents'),('reason',E('corr_reason'),{}),
   ('requested_amount_paise','money',{'null':1}),('note','text',{}),('status',E('corr_status'),{'default':'pending'}),
   fk('resolution_chit_id','chits',null=1),fk('decided_by','users',null=1),('decided_at','datetime',{'null':1}),('decision_note','text',{'null':1})],
   indexes=[['status','created_at']]),
 dict(name='payment_adjustments', note='Append-only record of every correction applied to a payment (nothing is deleted).', cols=[
   fk('payment_id','payments'),fk('correction_request_id','correction_requests',null=1),('type',E('adj_type'),{}),
   ('delta_paise','smoney',{'note':'signed change to the payment amount'}),fk('created_by','users'),('reason','str:255',{})]),
 dict(name='payment_allocations', note='How a payment was applied to installments. Signed: reversals are negative rows linked to an adjustment.', cols=[
   fk('payment_id','payments'),fk('installment_id','chit_installments'),('amount_paise','smoney',{}),fk('adjustment_id','payment_adjustments',null=1)],
   indexes=[['installment_id'],['payment_id']]),
 dict(name='razorpay_events', note='Every Razorpay webhook received. event_id is unique so a repeated webhook is processed once.', cols=[
   ('event_id','str:64',{'unique':1}),('event_type','str:60',{}),fk('payment_id','payments',null=1),('payload','json',{}),
   ('status',E('rp_event_status'),{'default':'received'}),('processed_at','datetime',{'null':1}),('error','str:255',{'null':1})]),
 dict(name='audit_logs', note='Who did what and when. Append-only.', timestamps='created', cols=[
   fk('actor_user_id','users',null=1),('actor_label','str:120',{}),('action','str:80',{}),('entity_type','str:40',{}),('entity_id','str:40',{}),
   ('summary','str:500',{}),('before_json','json',{'null':1}),('after_json','json',{'null':1}),('ip_address','str:45',{'null':1}),('user_agent','str:255',{'null':1})],
   indexes=[['entity_type','entity_id'],['actor_user_id','created_at'],['action','created_at']]),
 dict(name='sequences', note='Gap-free counters for receipt numbers and codes (locked with SELECT ... FOR UPDATE).', pk='name', timestamps=False, cols=[
   ('name','str:40',{'pk':1}),('value','money',{'default':0})]),
 dict(name='settings', note='Admin-editable settings (support phone, PIN rules, Razorpay mode, ...).', cols=[
   ('setting_key','str:80',{'unique':1}),('value','json',{}),fk('updated_by','users',null=1)]),
 dict(name='device_tokens', note='Push notification tokens. Push is not used in V1; the table keeps the architecture ready.', cols=[
   fk('user_id','users'),('token','str:255',{'unique':1}),('platform',E('platform'),{}),('last_seen_at','datetime',{'null':1})]),
]
