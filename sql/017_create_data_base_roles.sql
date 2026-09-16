-- Creates the restricted login role used by the banking application.
-- Set the role password separately through secure environment/deployment configuration.
CREATE ROLE bank_app
WITH
    LOGIN
    NOSUPERUSER
    NOCREATEDB
    NOCREATEROLE;

-- Allows the application to access objects in the banking schema.
GRANT USAGE ON SCHEMA banking TO bank_app;

-- Gives the application read access only to required banking tables.
GRANT SELECT ON
    banking.customers,
    banking.accounts,
    banking.transactions,
    banking.transfers,
    banking.beneficiaries,
    banking.loans,
    banking.loan_payments,
    banking.interest_rates,
    banking.risk_rules
TO bank_app;

-- Removes the default ability for all roles to execute money functions.
REVOKE EXECUTE ON FUNCTION
    banking.deposit_funds(BIGINT, NUMERIC, VARCHAR)
FROM PUBLIC;

REVOKE EXECUTE ON FUNCTION
    banking.withdraw_funds(BIGINT, NUMERIC, VARCHAR)
FROM PUBLIC;

REVOKE EXECUTE ON FUNCTION
    banking.transfer_funds(BIGINT, BIGINT, NUMERIC, VARCHAR)
FROM PUBLIC;

-- Explicitly authorizes the application role to use controlled money operations.
GRANT EXECUTE ON FUNCTION
    banking.deposit_funds(BIGINT, NUMERIC, VARCHAR)
TO bank_app;

GRANT EXECUTE ON FUNCTION
    banking.withdraw_funds(BIGINT, NUMERIC, VARCHAR)
TO bank_app;

GRANT EXECUTE ON FUNCTION
    banking.transfer_funds(BIGINT, BIGINT, NUMERIC, VARCHAR)
TO bank_app;

-- Runs controlled money functions using their owner's privileges.
ALTER FUNCTION banking.deposit_funds(BIGINT, NUMERIC, VARCHAR)
SECURITY DEFINER;

ALTER FUNCTION banking.withdraw_funds(BIGINT, NUMERIC, VARCHAR)
SECURITY DEFINER;

ALTER FUNCTION banking.transfer_funds(BIGINT, BIGINT, NUMERIC, VARCHAR)
SECURITY DEFINER;

-- Restricts object lookup while privileged functions execute.
ALTER FUNCTION banking.deposit_funds(BIGINT, NUMERIC, VARCHAR)
SET search_path = banking, pg_temp;

ALTER FUNCTION banking.withdraw_funds(BIGINT, NUMERIC, VARCHAR)
SET search_path = banking, pg_temp;

ALTER FUNCTION banking.transfer_funds(BIGINT, BIGINT, NUMERIC, VARCHAR)
SET search_path = banking, pg_temp;