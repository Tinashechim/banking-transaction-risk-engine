-- Deposits money into an account and records the transaction.
CREATE OR REPLACE FUNCTION banking.deposit_funds(
    p_account_id BIGINT,
    p_amount NUMERIC(15,2),
    p_reference VARCHAR(50)
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN

    -- Rejects zero or negative deposits before changing any data.
    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'Deposit amount must be greater than zero';
    END IF;

    -- Updates the account balance.
    UPDATE banking.accounts
    SET balance = balance + p_amount
    WHERE account_id = p_account_id;

    -- FOUND is false when the UPDATE does not match an account.
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Account % does not exist', p_account_id;
    END IF;

    -- Records the deposit in the transaction history.
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
        p_account_id,
        'DEPOSIT',
        p_amount,
        'Account deposit',
        p_reference
    );

END;
$$;

-- Calls the deposit function for account 1.
SELECT banking.deposit_funds(
    1,
    1000.00,
    'DEP-0001'
);

-- Reuses an existing reference to force the transaction insert to fail.
SELECT banking.deposit_funds(
    1,
    500.00,
    'DEP-0001'
);