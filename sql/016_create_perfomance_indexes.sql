-- Speeds up searches for accounts belonging to a customer.
CREATE INDEX idx_accounts_customer_id
ON banking.accounts (customer_id);

-- Speeds up transaction-history searches for an account.
CREATE INDEX idx_transactions_account_id
ON banking.transactions (account_id);

-- Speeds up searches for loans belonging to a customer.
CREATE INDEX idx_loans_customer_id
ON banking.loans (customer_id);

-- Speeds up searches for payments belonging to a loan.
CREATE INDEX idx_loan_payments_loan_id
ON banking.loan_payments (loan_id);

-- Speeds up chronological audit-log searches.
CREATE INDEX idx_audit_logs_changed_at
ON banking.audit_logs (changed_at);



---confirm new addition of indexes
SELECT
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'banking'
  AND indexname LIKE 'idx_%'
ORDER BY tablename, indexname;

















