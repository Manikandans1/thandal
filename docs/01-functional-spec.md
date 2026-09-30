# Thandal – Functional Specification (Phase 1)

Version 1.0 · Status: **for review** · Source: the approved UI prototypes and every decision made in the design chat.

The approved prototypes are the visual truth. This document is the **business-rule truth**. When a screen and this document disagree, this document wins and the screen is fixed.

---

## 1. What is being built

A system for a company that lends money and collects it back in **fixed installments** (daily, weekly or monthly).

| Part | Technology |
|---|---|
| One mobile app with three sides: Customer, Agent, Admin | Flutter |
| Super Admin web panel | Laravel 11 (Blade + Livewire) |
| API and all business logic | Laravel 11 (PHP 8.3) |
| Database | MySQL 8 |
| Online payments | Razorpay |

**The server is the source of truth.** The apps and the web panel only display what the API returns. They never calculate money, balances, statuses or allocation.

### Removed on purpose (do not build)
- No interest rate, interest amount or principal/interest split anywhere.
- No penalty. A missed installment keeps the same amount.
- No offline mode, no pending sync, no sync screens in the agent app.
- No customer self-registration. No OTP. No social login. No maps. No chat.

---

## 2. Roles and permissions

| Ability | Customer | Agent | Admin | Super Admin |
|---|:-:|:-:|:-:|:-:|
| Log in with mobile number + PIN | ✔ | ✔ | ✔ | ✔ |
| See own chits, schedule, payments, statement | ✔ | | | |
| Pay online (Razorpay) | ✔ | | | |
| See assigned customers (full details, chits, schedule, payments) | | ✔ (own only) | ✔ (all) | ✔ (all) |
| Collect cash, view receipts | | ✔ (own customers) | | |
| Request a payment correction | | ✔ (own cash payments) | | |
| Create customer (with ID proof) | | ✔ (auto-assigned to self) | ✔ | ✔ |
| Create chit | | ✔ (own customers) | ✔ | ✔ |
| Record disbursement, cancel chit | | | ✔ | ✔ |
| Create / edit / deactivate agents (address + ID proof) | | | ✔ | ✔ |
| Reset customer or agent PIN | | | ✔ | ✔ |
| Assign / transfer customers between agents | | | ✔ | ✔ |
| Approve or reject a correction request | | | ✔ | ✔ |
| Reports, exports, audit logs, system settings | | | ✔ | ✔ |
| Approve or reject new admin registrations, activate / deactivate admins | | | | ✔ |

An agent can **never**: delete a payment, change a recorded amount, see another agent's customers, change settings.
Nobody can delete a confirmed payment. Money mistakes are fixed with corrections (section 9).

---

## 3. Accounts and login

### 3.1 One login for everyone
- Fields: **mobile number** (10 digits) and **PIN** (4 digits).
- The account decides the side: customer → Customer side, agent → Agent side, admin / super admin → Admin side.
- The mobile number is **unique across all roles**. One number cannot be both a customer and an agent.
- The same login is used by the admin web panel. A customer or agent number on the web shows "please use the mobile app".

### 3.2 PIN rules
- Stored only as a **hash**. It is shown in plain text exactly once, when created or reset.
- Must be 4 digits. Not `0000`, `1111`, `1234`. A new PIN must differ from the old one.
- **3 wrong PINs lock the account for 15 minutes.** The message shows attempts left.
- **Forgot PIN:** there is no OTP. The user calls Thandal. An admin verifies the person and resets the PIN. The system creates a **temporary PIN**, shown once. On the next login the user must choose their own PIN (`must_change_pin`).
- Customers can change their PIN inside the app (current PIN + new PIN + confirm).

### 3.3 Sessions
- Mobile app: an API token (Laravel Sanctum). Expires after 30 days of no use. Logging out revokes it.
- Web panel: a server session, 30 minutes idle timeout (configurable in settings).

### 3.4 Admin registration (new admins register themselves)
1. On the web login, "Register as admin": name, mobile number, PIN (twice).
2. The account is created with status **pending**. It cannot log in or see anything.
3. A **Super Admin** sees the request (dashboard alert + "Admin users" page) and **approves** or **rejects** (a note is required to reject).
4. Approved → status **active**, role **admin**, full admin access except managing admins. Rejected → the person is told at login.
5. A Super Admin can deactivate or re-activate any admin (not themselves, not the owner).
6. The first Super Admin is created by a command during setup (`php artisan thandal:create-super-admin`).

---

## 4. People

### 4.1 Customers
- Created only by an admin or an agent. Fields: name, mobile number, address, **one ID proof** (see 4.3).
- A Customer ID (`THD-10245`) and a 4-digit PIN are generated. The PIN is shown once.
- Created by an agent → automatically assigned to that agent. Created by an admin → an agent may be chosen or left empty.
- Status **Active** or **Inactive**. Inactive customers cannot log in. Their chits and schedules continue and agents can still collect cash.
- A customer may have many chits, active and past, at the same time.

### 4.2 Agents
- Created by an admin. Fields: name, mobile number, **address, one ID proof**. An Agent ID (`AGT-007`) and a PIN (shown once) are generated.
- **An agent with customers cannot be deactivated.** The admin must transfer all customers first (the deactivate dialog offers "transfer and deactivate").
- Deactivated agents cannot log in. Their history stays.

### 4.3 ID proof (customers and agents)
- Any **one** of: Aadhaar card, PAN card, Voter ID, Driving licence, Passport, Ration card.
- The ID number and a photo/scan of the document are **required** when creating a customer or an agent.
- The number is stored **encrypted**; only the type and the **last 4 digits** are shown in the apps. The photo is kept in **private storage** and only admins can open it.
- Replacing an ID proof keeps the old one as history (`is_current = 0`).

### 4.4 Agent assignment and transfers
- A customer has **one current agent** (or none). Every change is stored in `agent_assignments` with date, who did it and the reason.
- **Transfer:** future collections belong to the new agent. **Past payments keep the agent who collected them.** History rows are never edited.
- An agent's visible customers are exactly those whose *current* agent is that agent.

---

## 5. Chits (loans)

### 5.1 What is entered
| Field | Rule |
|---|---|
| Customer | must be Active |
| Loan amount | whole rupees, > 0. The amount given to the customer |
| Frequency | **Daily**, **Weekly** or **Monthly** |
| Number of installments | whole number > 0 (days, weeks or months depending on frequency) |
| Installment amount | whole rupees, > 0. **Set by the admin or agent, nothing is calculated from an interest rate** |
| Start date | the due date of the **first** installment |

### 5.2 What the system calculates
- **Total to pay = installment amount × number of installments.** (Example: loan ₹10,000, ₹120 daily × 100 days = ₹12,000.)
- **End date** = due date of the last installment.
- The customer pays **only** the installment amount each period. There is no separate lump sum.
- The preview on the create-chit screens shows: loan amount, repayment, installments, end date and **Total to pay**.

### 5.3 Schedule generation
One row per installment, all created when the chit is created.

| Frequency | Due date of installment *n* |
|---|---|
| Daily | start date + (n − 1) days (all 7 days count) |
| Weekly | start date + 7 × (n − 1) days |
| Monthly | same day of the month as the start date, n − 1 months later. If that day does not exist, the **last day of that month** (start 31 Jan → 28 Feb, 31 Mar, 30 Apr). Always computed from the start date, never chained. |

Each row: sequence, due date, amount, paid amount, status.

### 5.4 Status lifecycle
```
Pending ──(disbursement completed)──▶ Active ──(all installments paid)──▶ Completed
   │                                     │
   └───────────(admin cancels)───────────┴──▶ Cancelled
```
- **Pending:** created, money not given yet. No payments are accepted. Admin/agent may still edit the loan terms and start date (the schedule is regenerated).
- **Active:** a **completed** disbursement exists. Payments are accepted. Terms are locked.
- **Completed:** every installment is fully paid. Also reached by early closure.
- **Cancelled:** by an admin with a reason, only from Pending or Active. Unpaid installments become *cancelled*. Money already paid stays in the ledger.
- A chit cannot be activated if its start date is before the disbursement date. The admin edits the start date first.

### 5.5 Disbursement
- Recorded by an admin: method (**Cash** or **Bank transfer**), date, reference number (**required for bank transfer**), result **Completed** or **Failed**, note.
- **Failed** keeps the chit Pending and is kept in the history. A new attempt can be recorded.

### 5.6 Installment status
- Stored: *upcoming*, *partially paid*, *paid*, *cancelled*.
- **Overdue is derived:** due date is before today (IST) and the installment is not fully paid. An overdue installment keeps its **same amount**.
- "Due today" = due date is today and not fully paid.

---

## 6. Payments

### 6.1 Two ways in, one ledger
- **Online:** the customer pays with Razorpay in the app.
- **Cash:** an agent records cash he received from one of his customers.
- Both create rows in the same `payments` table and the same allocation logic. There is never a separate balance for the app, the agent or the admin.

### 6.2 How an amount is applied (allocation)
1. The payment amount is applied to the chit's **unpaid installments in due-date order (oldest first)**: overdue first, then today, then future installments.
2. Each installment is filled up to its remaining amount, then the next one.
3. **Partial payments are allowed.** If the money ends inside an installment, that installment becomes *partially paid*.
4. **Advance payments are allowed.** Money beyond today's due goes to the next installments.
5. A payment **cannot exceed the outstanding balance** of the chit. The server rejects it and returns the correct figure.
6. The customer and agent screens only show the result ("Applied to Sep 18, Sep 19…"). They never decide it.

Example: ₹120 daily. Installments of Sep 18 (missed) and Sep 19 (today) are unpaid. A payment of ₹300 → Sep 18 ₹120 paid, Sep 19 ₹120 paid, Sep 20 ₹60 partially paid.

### 6.3 Early closure
- "Pay full outstanding" = the sum of every unpaid remainder. **No discount.** The server recalculates the amount at payment time. When fully paid the chit becomes **Completed**.

### 6.4 Online payment flow (Razorpay)
1. App asks the server to pay an amount (built from the installments the customer selected, or the full outstanding).
2. Server checks the chit is Active and the amount is valid, creates a **pending** payment and a Razorpay **order** (amount decided by the server), returns the order to the app.
3. App opens Razorpay Checkout.
4. After checkout the app sends the Razorpay ids and signature to the server.
5. The server **verifies the signature and asks Razorpay for the payment status**. Only then does it confirm the payment, allocate it, and issue the receipt number, all inside one database transaction.
6. Razorpay **webhooks** are also processed. Each webhook `event_id` is stored once; a repeated webhook is ignored. A payment already confirmed is never confirmed twice.
7. The app's "success" message is **never trusted**. If the app is closed mid-payment, the webhook or a scheduled reconciliation completes it.
8. Payments still *pending* after 30 minutes are reconciled with Razorpay and marked *confirmed* or *failed*.
9. States shown to the customer: processing, pending (waiting for confirmation), success, failed. A failed payment changes nothing.

### 6.5 Cash collection flow (agent)
1. Agent opens one of **his** customers → a chit → **Collect cash**, enters the amount received.
2. Confirmation dialog, then the server records a confirmed cash payment with the agent as collector and issues the receipt immediately.
3. The app sends a unique `client_request_id` with every collection so a double tap or a retry can never create two payments.
4. **No internet = no collection.** The agent app shows a clear error. Nothing is stored on the phone (no offline mode).

### 6.6 Receipts
- Number format `THD-RCP-000231`, gap-free, issued when a payment is confirmed. The prefix is a setting.
- Content: receipt number, customer, customer ID, chit, date and time, amount, method (Razorpay / Cash), transaction id or collecting agent, and the installments it was applied to. **No** principal, interest or penalty lines.

---

## 7. Amounts shown in the apps (definitions)

| Term | Meaning |
|---|---|
| Total repayment (Total to pay) | installment amount × number of installments |
| Paid | sum of allocated (net) payments on the chit |
| Outstanding | total repayment − paid |
| Overdue | sum of remaining amounts of installments whose due date is before today |
| Today's due | remaining amount of the installment due today |
| Today's expected (agent / admin) | remaining on installments due on or before today **plus** money already allocated today to those installments (so the number does not shrink while the agent collects) |
| Today's collected | all confirmed money received today (IST) |
| Today's pending | remaining on installments due on or before today |
| Collection % | collected toward due ÷ expected |
| Agent "collected" | cash the agent took + online payments from his current customers |

"Today" always means the calendar day in **India time (IST)**.

Customer home totals ("All my chits"): number of chits, total loan amount, total repayment across the customer's active chits.

---

## 8. Numbering
| Item | Format | Example |
|---|---|---|
| Customer | `THD-` + 5 digits from 10001 | THD-10245 |
| Chit | `THD-` + 4 digits from 1001 | THD-1001 |
| Agent | `AGT-` + 3 digits | AGT-007 |
| Receipt | `THD-RCP-` + 6 digits | THD-RCP-000231 |
| Correction request | `CR-` + 3 digits | CR-041 |
Counters live in the `sequences` table and are locked while a number is issued, so numbers never repeat or skip.

---

## 9. Corrections (fixing a confirmed payment)
A confirmed payment is **never edited or deleted**.

1. The agent opens a cash payment he collected → **Request correction**: reason (*wrong amount*, *wrong customer or chit*, *duplicate entry*, *other*), the correct amount if it was wrong, and a note (at least 10 characters).
2. The admin reviews and **approves** or **rejects** (a note is required to reject).
3. On approval the server adds records; it changes nothing that was written before:
   - **Wrong amount** → an adjustment with a signed difference. If lower, the newest allocations are reversed first; if higher, the extra is allocated oldest-first.
   - **Duplicate entry** → the payment is reversed (status *reversed*, all allocations reversed).
   - **Wrong customer or chit** → the payment is reversed and a new confirmed payment is created on the chit chosen by the admin.
4. Installment and chit balances are recalculated in the same transaction. A completed chit that becomes short of money returns to Active.
5. Every step is written to the audit log. The payment shows "Correction: pending / approved / rejected".

---

## 10. Reports and exports (admin)
Daily collection · Agent collection · Customers · Payments · Outstanding · Overdue · Completed accounts · Cash payments · Razorpay payments · Disbursements. Each can be exported as **CSV or Excel**. Filters: date range, agent, status.

---

## 11. Audit log (append-only)
Recorded: login, customer / agent / admin created or edited, ID proof added or replaced, PIN reset, agent assigned or transferred, agent / customer / admin activated or deactivated, chit created / edited / cancelled, disbursement recorded or failed, payment confirmed / failed / reversed, correction requested / approved / rejected, admin registration requested / approved / rejected, settings changed, exports.
Each entry: who, what, which record, a short summary, before/after values when relevant, time, IP address.

---

## 12. Security and privacy
- PIN hashed (bcrypt). Login and PIN-reset attempts rate limited (per account and per IP).
- Every API call is checked on the server against role and ownership (an agent asking for another agent's customer gets "not found").
- ID numbers encrypted; ID photos in private storage, served only through an authorised admin request.
- Razorpay secret and webhook secret only in the server environment.
- All money changes happen in database transactions with row locks on the chit and its installments.
- Money is stored as **paise** (integers). Only whole rupees are accepted.
- HTTPS only in production. Backups of the database daily (setup guide in Phase 9).

## 13. Notifications
Push notifications are **not part of V1**. The `device_tokens` table exists so they can be added later without redesign.

## 14. Language and format
English only. Currency ₹ with Indian digit grouping (₹2,11,170). Dates like "19 Sep 2026".

---

## 15. Decision log
| # | Decision | By |
|---|---|---|
| 1 | Total to pay = installment amount × number of installments. No lump sum, no interest | Client |
| 2 | Frequencies: daily, weekly, monthly. Admin/agent sets the installment amount | Client |
| 3 | No penalty. Missed installments keep the same amount | Client |
| 4 | No interest rate anywhere | Client |
| 5 | No offline mode or sync in the agent app | Client |
| 6 | One app, one login (mobile number + PIN) for customer, agent and admin. Admin also has the web panel | Client |
| 7 | ID proof (any one) required when creating a customer or an agent; agents also give an address | Client |
| 8 | Agents can create customers and chits | Client |
| 9 | Agent sees the customer's complete details, loan details, progress and payments | Client |
| 10 | New admins register themselves and become admins after a Super Admin approves | Client (approval step added for safety, to be confirmed) |
| 11 | Payment order: oldest installment first; partial and advance payments allowed | Client ("defaults OK") |
| 12 | Early closure = all remaining, no discount | Client ("defaults OK") |
| 13 | Agent-created chits start Pending until the admin records the disbursement | Client ("defaults OK") |
| 14 | Monthly due date = same day of month, last day when missing | Client ("defaults OK") |
| 15 | ID photos private; agents see type and last 4 digits only | Client ("defaults OK") |
| 16 | Whole rupees only; all dates in IST; mobile number unique across roles | Client ("defaults OK") |
| 17 | Laravel 11 + MySQL 8 + Blade/Livewire + one Flutter app + Docker | Client ("defaults OK") |

## 16. Points added by the developer (please confirm)
These were not stated explicitly. They are safe defaults and easy to change.
1. A Super Admin approves new admin registrations (an open self-registration would give anyone full admin access).
2. Approved admins can do everything except manage other admins.
3. Pending chits can be edited (schedule regenerates) and cannot be activated if the start date is before the disbursement date.
4. Corrections are requested only by agents for their own cash payments; admins approve, they do not edit payments directly.
5. Sessions: mobile token 30 days, web 30 minutes idle.

## 17. Acceptance checklist (from the original edge-case list)
Each item becomes an automated test in Phase 5–6.

1. Customer pays the exact installment. 2. Pays several installments. 3. Pays future installments. 4. Misses an installment (shows Overdue, same amount). 5. Pays an overdue installment. 6. Pays the full outstanding (chit Completed). 7. Partial payment. 8. Payment larger than outstanding is rejected. 9. Agent records cash (receipt at once). 10. Double tap / repeat submit creates one payment. 11. Razorpay success confirmed by the server only. 12. Razorpay failure changes nothing. 13. Repeated Razorpay webhook processed once. 14. App closed during payment, webhook completes it. 15. Network failure during payment shows a clear state. 16. Duplicate payment attempt blocked. 17. Correction requested, approved (wrong amount / duplicate / wrong chit). 18. Correction rejected. 19. Customer transferred, old payments keep the old agent. 20. Agent deactivated only after customers are moved. 21. Customer deactivated (cannot log in, chits continue). 22. Chit completed. 23. Chit cancelled. 24. Disbursement failed, then completed. 25. Bank transfer without a reference is rejected. 26. Monthly schedule on the 31st. 27. Agent cannot see another agent's customer. 28. 3 wrong PINs lock the account. 29. PIN reset forces a new PIN. 30. Admin registration pending, approved and rejected. 31. ID proof required for new customer and new agent.
