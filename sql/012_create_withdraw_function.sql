-- Withdraws money from an account and records the transaction.
CREATE OR REPLACE FUNCTION banking.withdraw_funds(
    p_account_id BIGINT,
    p_amount NUMERIC(15,2),
    p_reference VARCHAR(50)
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_balance NUMERIC(15,2);
BEGIN

    -- Rejects zero or negative withdrawal amounts.
    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'Withdrawal amount must be greater than zero';
    END IF;

    -- Retrieves the current balance for the requested account.
    SELECT balance
    INTO v_balance
    FROM banking.accounts
    WHERE account_id = p_account_id;

    -- FOUND is false when the SELECT does not find the account.
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Account % does not exist', p_account_id;
    END IF;

    -- Prevents the account balance from going below zero.
    IF v_balance < p_amount THEN
        RAISE EXCEPTION 'Insufficient funds';
    END IF;

    -- Deducts the withdrawal from the account balance.
    UPDATE banking.accounts
    SET balance = balance - p_amount
    WHERE account_id = p_account_id;

    -- Records the withdrawal in the transaction history.
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
        'WITHDRAWAL',
        p_amount,
        'Account withdrawal',
        p_reference
    );

END;
$$;

-- Withdraws R500 from account 1.
SELECT banking.withdraw_funds(
    1,
    500.00,
    'WDL-0001'
);

--insufficient funds
SELECT banking.withdraw_funds(
    1,
    6000.00,
    'WDL-0002'
);

