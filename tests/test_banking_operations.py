
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


# verify transaction records
def get_transfer(reference):
    conn = get_connection()

    try:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT
                    from_account_id,
                    to_account_id,
                    amount,
                    status
                FROM banking.transfers
                WHERE reference = %s
                """,
                (reference,),
            )

            return cur.fetchone()

    finally:
        conn.close()


# helper to verify two transaction ledger entries
def get_transaction(reference):
    conn = get_connection()

    try:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT
                    account_id,
                    transaction_type,
                    amount,
                    reference
                FROM banking.transactions
                WHERE reference = %s
                """,
                (reference,),
            )

            return cur.fetchone()

    finally:
        conn.close()


# helper that checks whether the risk engine saved an event
def get_risk_event(reference):
    conn = get_connection()

    try:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT
                    risk_rule_id,
                    transaction_reference,
                    transaction_amount,
                    risk_score,
                    risk_level
                FROM banking.risk_events
                WHERE transaction_reference = %s
                """,
                (reference,),
            )

            return cur.fetchone()

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

    # Verify balance and the ledger
    transaction = get_transaction(reference)

    assert transaction is not None
    assert transaction[0] == account_id
    assert transaction[1] == "DEPOSIT"
    assert transaction[2] == amount
    assert transaction[3] == reference


def test_withdrawal():
    account_id = 1
    amount = Decimal("10.00")
    reference = f"TEST-WD-{uuid4().hex[:8]}"

    balance_before = get_balance(account_id)

    withdraw_funds(account_id, amount, reference)

    balance_after = get_balance(account_id)

    assert balance_after == balance_before - amount

    transaction = get_transaction(reference)

    assert transaction is not None
    assert transaction[0] == account_id
    assert transaction[1] == "WITHDRAWAL"
    assert transaction[2] == amount
    assert transaction[3] == reference


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

    transaction = get_transaction(reference)

    assert transaction is None


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

    transfer = get_transfer(reference)

    assert transfer is not None
    assert transfer[0] == from_account_id
    assert transfer[1] == to_account_id
    assert transfer[2] == amount
    assert transfer[3] == "COMPLETED"

    outgoing_transaction = get_transaction(reference + "-OUT")
    incoming_transaction = get_transaction(reference + "-IN")

    assert outgoing_transaction is not None
    assert incoming_transaction is not None

    assert outgoing_transaction[0] == from_account_id
    assert outgoing_transaction[1] == "TRANSFER_OUT"
    assert outgoing_transaction[2] == amount

    assert incoming_transaction[0] == to_account_id
    assert incoming_transaction[1] == "TRANSFER_IN"
    assert incoming_transaction[2] == amount


def test_high_value_transfer_creates_risk_event():
    from_account_id = 1
    to_account_id = 4
    amount = Decimal("15000.00")

    deposit_reference = f"TEST-RISK-DEP-{uuid4().hex[:8]}"
    transfer_reference = f"TEST-RISK-TRF-{uuid4().hex[:8]}"

    from_balance_before = get_balance(from_account_id)
    to_balance_before = get_balance(to_account_id)

    deposit_funds(
        from_account_id,
        amount,
        deposit_reference,
    )

    assert get_balance(from_account_id) == from_balance_before + amount

    transfer_funds(
        from_account_id,
        to_account_id,
        amount,
        transfer_reference,
    )

    from_balance_after = get_balance(from_account_id)
    to_balance_after = get_balance(to_account_id)

    assert from_balance_after == from_balance_before
    assert to_balance_after == to_balance_before + amount

    transfer = get_transfer(transfer_reference)

    assert transfer is not None
    assert transfer[0] == from_account_id
    assert transfer[1] == to_account_id
    assert transfer[2] == amount
    assert transfer[3] == "COMPLETED"

    risk_event = get_risk_event(transfer_reference)

    assert risk_event is not None
    assert risk_event[1] == transfer_reference
    assert risk_event[2] == amount
    assert risk_event[3] == 70
    assert risk_event[4] == "HIGH"


def test_transfer_insufficient_funds():
    from_account_id = 1
    to_account_id = 4
    amount = Decimal("100000.00")
    reference = f"TEST-TRF-FAIL-{uuid4().hex[:8]}"

    from_balance_before = get_balance(from_account_id)
    to_balance_before = get_balance(to_account_id)

    try:
        transfer_funds(
            from_account_id,
            to_account_id,
            amount,
            reference,
        )

    except RaiseException:
        pass

    else:
        raise AssertionError("Transfer should have failed")

    from_balance_after = get_balance(from_account_id)
    to_balance_after = get_balance(to_account_id)

    assert from_balance_after == from_balance_before
    assert to_balance_after == to_balance_before

    transfer = get_transfer(reference)
    outgoing_transaction = get_transaction(reference + "-OUT")
    incoming_transaction = get_transaction(reference + "-IN")

    assert transfer is None
    assert outgoing_transaction is None
    assert incoming_transaction is None


if __name__ == "__main__":
    test_deposit()
    print("Deposit test passed")

    test_withdrawal()
    print("Withdrawal test passed")

    test_insufficient_funds()
    print("Insufficient funds test passed")

    test_transfer()
    print("Transfer test passed")

    test_high_value_transfer_creates_risk_event()
    print("High-value transfer risk event test passed")

    test_transfer_insufficient_funds()
    print("Transfer insufficient funds test passed")
