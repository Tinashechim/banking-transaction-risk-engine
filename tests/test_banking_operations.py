from decimal import Decimal
from uuid import uuid4

from psycopg.errors import RaiseException

from src.deposits import deposit_funds
from src.withdrawals import withdraw_funds
from src.transfers import transfer_funds
from src.database import get_connection


def get_balance(account_id):
    conn = get_connection()

    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT balance FROM banking.accounts WHERE account_id = %s",
                (account_id,),
            )

            row = cur.fetchone()
            return row[0]

    finally:
        conn.close()


def test_deposit():
    account_id = 1
    amount = Decimal("10.00")
    reference = f"TEST-DEP-{uuid4().hex[:8]}"

    balance_before = get_balance(account_id)

    deposit_funds(account_id, amount, reference)

    balance_after = get_balance(account_id)

    assert balance_after == balance_before + amount


def test_withdrawal():
    account_id = 1
    amount = Decimal("10.00")
    reference = f"TEST-WD-{uuid4().hex[:8]}"

    balance_before = get_balance(account_id)

    withdraw_funds(account_id, amount, reference)

    balance_after = get_balance(account_id)

    assert balance_after == balance_before - amount

def test_insufficient_funds():
    account_id = 1
    amount = Decimal("100000.00")
    reference = f"TEST-WD-FAIL-{uuid4().hex[:8]}"

    balance_before = get_balance(account_id)

    try:
        withdraw_funds(account_id, amount, reference)

    except RaiseException:
        pass

    else:
        raise AssertionError("Withdrawal should have failed")

    balance_after = get_balance(account_id)

    assert balance_after == balance_before

def test_transfer():
    from_account_id = 1
    to_account_id = 4
    amount = Decimal("10.00")
    reference = f"TEST-TRF-{uuid4().hex[:8]}"

    from_balance_before = get_balance(from_account_id)
    to_balance_before = get_balance(to_account_id)

    transfer_funds(
        from_account_id,
        to_account_id,
        amount,
        reference,
    )

    from_balance_after = get_balance(from_account_id)
    to_balance_after = get_balance(to_account_id)

    assert from_balance_after == from_balance_before - amount
    assert to_balance_after == to_balance_before + amount

    total_before = from_balance_before + to_balance_before
    total_after = from_balance_after + to_balance_after

    assert total_after == total_before


if __name__ == "__main__":
    test_deposit()
    print("Deposit test passed")

    test_withdrawal()
    print("Withdrawal test passed")

    test_insufficient_funds()
    print("Insufficient funds test passed")

    test_transfer()
    print("Transfer test passed")