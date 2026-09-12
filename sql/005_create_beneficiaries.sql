CREATE TABLE banking.beneficiaries (
    beneficiary_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    beneficiary_name VARCHAR(100) NOT NULL,
    beneficiary_account_number VARCHAR(20) NOT NULL,
    beneficiary_bank VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_beneficiaries_customer
        FOREIGN KEY (customer_id)
        REFERENCES banking.customers(customer_id),

    CONSTRAINT uq_customer_beneficiary_account
        UNIQUE (customer_id, beneficiary_account_number)
);

INSERT INTO banking.beneficiaries
(customer_id, beneficiary_name, beneficiary_account_number, beneficiary_bank)
VALUES
(1, 'Jane Doe', '2000000001', 'Example Bank');