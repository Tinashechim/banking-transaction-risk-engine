CREATE TABLE banking.transfers (
    transfer_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    from_account_id BIGINT NOT NULL,
    to_account_id BIGINT NOT NULL,
    amount NUMERIC(15,2) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    reference VARCHAR(50) NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMPTZ,

    CONSTRAINT fk_transfers_from_account
        FOREIGN KEY (from_account_id)
        REFERENCES banking.accounts(account_id),

    CONSTRAINT fk_transfers_to_account
        FOREIGN KEY (to_account_id)
        REFERENCES banking.accounts(account_id),

    CONSTRAINT chk_transfers_amount
        CHECK (amount > 0),

    CONSTRAINT chk_transfers_different_accounts
        CHECK (from_account_id <> to_account_id),

    CONSTRAINT chk_transfers_status
        CHECK (status IN ('PENDING', 'COMPLETED', 'FAILED', 'REVERSED'))
);

INSERT INTO banking.transfers
(from_account_id, to_account_id, amount, reference)
VALUES
(1, 4, 500.00, 'TRF-0001');


