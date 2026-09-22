from decimal import Decimal
from uuid import uuid4

from psycopg.errors import RaiseException

from src.deposits import deposit_funds
from src.withdrawals import withdraw_funds
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


if __name__ == "__main__":
    test_deposit()
    print("Deposit test passed")

    test_withdrawal()
    print("Withdrawal test passed")

    test_insufficient_funds()
    print("Insufficient funds test passed")