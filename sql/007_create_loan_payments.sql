CREATE TABLE banking.loan_payments (
    payment_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    loan_id BIGINT NOT NULL,
    amount NUMERIC(15,2) NOT NULL,
    payment_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reference VARCHAR(50) NOT NULL UNIQUE,

    CONSTRAINT fk_loan_payments_loan
        FOREIGN KEY (loan_id)
        REFERENCES banking.loans(loan_id),

    CONSTRAINT chk_loan_payments_amount
        CHECK (amount > 0)
);

INSERT INTO banking.loan_payments
(loan_id, amount, reference)
VALUES
(1, 1000.00, 'PAY-0001');