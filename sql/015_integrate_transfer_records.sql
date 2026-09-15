-- Transfers money and records the complete transfer lifecycle.
CREATE OR REPLACE FUNCTION banking.transfer_funds(
    p_from_account_id BIGINT,
    p_to_account_id BIGINT,
    p_amount NUMERIC(15,2),
    p_reference VARCHAR(50)
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_from_balance NUMERIC(15,2);
BEGIN

    -- Rejects zero or negative transfer amounts.
    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'Transfer amount must be greater than zero';
    END IF;

    -- Prevents transfers between the same account.
    IF p_from_account_id = p_to_account_id THEN
        RAISE EXCEPTION 'Source and destination accounts must be different';
    END IF;

    -- Locks both accounts in a consistent order to reduce deadlock risk.
    PERFORM account_id
    FROM banking.accounts
    WHERE account_id IN (p_from_account_id, p_to_account_id)
    ORDER BY account_id
    FOR UPDATE;

    -- Retrieves the source account balance.
    SELECT balance
    INTO v_from_balance
    FROM banking.accounts
    WHERE account_id = p_from_account_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Source account % does not exist', p_from_account_id;
    END IF;

    -- Confirms that the destination account exists.
    PERFORM 1
    FROM banking.accounts
    WHERE account_id = p_to_account_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Destination account % does not exist', p_to_account_id;
    END IF;

    -- Prevents the source account from being overdrawn.
    IF v_from_balance < p_amount THEN
        RAISE EXCEPTION 'Insufficient funds';
    END IF;

    -- Creates the transfer record.
    INSERT INTO banking.transfers
    (
        from_account_id,
        to_account_id,
        amount,
        status,
        reference
    )
    VALUES
    (
        p_from_account_id,
        p_to_account_id,
        p_amount,
        'PENDING',
        p_reference
    );

    -- Deducts money from the source account.
    UPDATE banking.accounts
    SET balance = balance - p_amount
    WHERE account_id = p_from_account_id;

    -- Adds money to the destination account.
    UPDATE banking.accounts
    SET balance = balance + p_amount
    WHERE account_id = p_to_account_id;

    -- Records money leaving the source account.
    INSERT INTO banking.transactions
    (
        account_id,
        transaction_type,
        amount,
        description,
        reference
    )
    VALUES
    (
        p_from_account_id,
        'TRANSFER_OUT',
        p_amount,
        'Account transfer',
        p_reference || '-OUT'
    );

    -- Records money entering the destination account.
    INSERT INTO banking.transactions
    (
        account_id,
        transaction_type,
        amount,
        description,
        reference
    )
    VALUES
    (
        p_to_account_id,
        'TRANSFER_IN',
        p_amount,
        'Account transfer',
        p_reference || '-IN'
    );

    -- Marks the transfer as successfully completed.
    UPDATE banking.transfers
    SET
        status = 'COMPLETED',
        completed_at = CURRENT_TIMESTAMP
    WHERE reference = p_reference;

END;
$$;

--testing
SELECT banking.transfer_funds(
	1,
	4,
	1000.00,
	'TRF-015-001'
);

SELECT account_id, account_number, balance
FROM banking.accounts
WHERE account_id IN (1, 4)
ORDER BY account_id;


SELECT
    transaction_id,
    account_id,
    transaction_type,
    amount,
    reference
FROM banking.transactions
WHERE reference IN (
    'TRF-015-001-OUT',
    'TRF-015-001-IN'
)
ORDER BY transaction_id;




