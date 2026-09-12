-- Transfers money between accounts using deterministic row locking.
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

    -- Prevents transferring money to the same account.
    IF p_from_account_id = p_to_account_id THEN
        RAISE EXCEPTION 'Source and destination accounts must be different';
    END IF;

    -- Locks both accounts in account_id order to reduce deadlock risk.
    PERFORM account_id
    FROM banking.accounts
    WHERE account_id IN (p_from_account_id, p_to_account_id)
    ORDER BY account_id
    FOR UPDATE;

    -- Confirms the source account exists and retrieves its balance.
    SELECT balance
    INTO v_from_balance
    FROM banking.accounts
    WHERE account_id = p_from_account_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Source account % does not exist', p_from_account_id;
    END IF;

    -- Confirms the destination account exists.
    PERFORM 1
    FROM banking.accounts
    WHERE account_id = p_to_account_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Destination account % does not exist', p_to_account_id;
    END IF;

    -- Prevents overdrawing the source account.
    IF v_from_balance < p_amount THEN
        RAISE EXCEPTION 'Insufficient funds';
    END IF;

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

END;
$$;