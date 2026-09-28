from decimal import Decimal
from uuid import uuid4

from src.database import get_connection
from src.risk_engine import (
    evaluate_transaction,
    classify_risk_score,
    save_risk_event,
)


def test_transaction_below_threshold():
    amount = Decimal("5000.00")

    triggered_rules = evaluate_transaction(amount)

    assert triggered_rules == []


def test_transaction_above_threshold():
    amount = Decimal("15000.00")

    triggered_rules = evaluate_transaction(amount)

    assert len(triggered_rules) > 0
    assert triggered_rules[0]["rule_name"] == "Large Transaction Alert"
    assert triggered_rules[0]["risk_score"] == 70
    assert triggered_rules[0]["risk_level"] == "HIGH"


def test_risk_score_classification():
    assert classify_risk_score(10) == "LOW"
    assert classify_risk_score(45) == "MEDIUM"
    assert classify_risk_score(70) == "HIGH"


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


def test_save_risk_event():
    reference = f"TEST-RISK-{uuid4().hex[:8]}"

    save_risk_event(
        1,
        reference,
        Decimal("15000.00"),
        70,
        "HIGH",
    )

    event = get_risk_event(reference)

    assert event is not None
    assert event[0] == 1
    assert event[1] == reference
    assert event[2] == Decimal("15000.00")
    assert event[3] == 70
    assert event[4] == "HIGH"


def test_evaluate_transaction_persists_risk_event():
    reference = f"TEST-RISK-EVAL-{uuid4().hex[:8]}"
    amount = Decimal("15000.00")

    triggered_rules = evaluate_transaction(amount, reference)

    assert len(triggered_rules) > 0

    event = get_risk_event(reference)

    assert event is not None
    assert event[0] == triggered_rules[0]["risk_rule_id"]
    assert event[1] == reference
    assert event[2] == amount
    assert event[3] == triggered_rules[0]["risk_score"]
    assert event[4] == triggered_rules[0]["risk_level"]


if __name__ == "__main__":
    test_transaction_below_threshold()
    print("Below-threshold risk test passed")

    test_transaction_above_threshold()
    print("Above-threshold risk test passed")

    test_risk_score_classification()
    print("Risk score classification test passed")

    test_save_risk_event()
    print("Risk event persistence test passed")

    test_evaluate_transaction_persists_risk_event()
    print("Integrated risk evaluation persistence test passed")