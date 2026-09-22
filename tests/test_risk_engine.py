from decimal import Decimal

from src.risk_engine import evaluate_transaction


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


if __name__ == "__main__":
    test_transaction_below_threshold()
    print("Below-threshold risk test passed")

    test_transaction_above_threshold()
    print("Above-threshold risk test passed")