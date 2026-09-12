CREATE TABLE banking.loans (
    loan_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    principal_amount NUMERIC(15,2) NOT NULL,
    interest_rate NUMERIC(5,2) NOT NULL,
    outstanding_balance NUMERIC(15,2) NOT NULL,
    loan_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    start_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_loans_customer
        FOREIGN KEY (customer_id)
        REFERENCES banking.customers(customer_id),

    CONSTRAINT chk_loans_principal
        CHECK (principal_amount > 0),

    CONSTRAINT chk_loans_interest_rate
        CHECK (interest_rate >= 0),

    CONSTRAINT chk_loans_outstanding_balance
        CHECK (outstanding_balance >= 0),

    CONSTRAINT chk_loans_status
        CHECK (loan_status IN ('ACTIVE', 'PAID', 'DEFAULTED'))
);

INSERT INTO banking.loans
(customer_id, principal_amount, interest_rate, outstanding_balance)
VALUES
(1, 10000.00, 12.50, 10000.00);