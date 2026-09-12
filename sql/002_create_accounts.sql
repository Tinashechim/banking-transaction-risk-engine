CREATE TABLE banking.accounts (
    account_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    account_number VARCHAR(20) NOT NULL UNIQUE,
    account_type VARCHAR(20) NOT NULL,
    balance NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_accounts_customer
        FOREIGN KEY (customer_id)
        REFERENCES banking.customers(customer_id),

    CONSTRAINT chk_accounts_balance
        CHECK (balance >= 0),

    CONSTRAINT chk_accounts_type
        CHECK (account_type IN ('CHEQUE', 'SAVINGS')),

    CONSTRAINT chk_accounts_status
        CHECK (status IN ('ACTIVE', 'FROZEN', 'CLOSED'))
);

INSERT INTO banking.accounts
(customer_id, account_number, account_type, balance)
VALUES
(1, '1000000001', 'SAVINGS', 5000.00);


