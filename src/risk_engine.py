from src.database import get_connection


def get_active_risk_rules():
    conn = get_connection()

    try:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT
                    risk_rule_id,
                    rule_name,
                    rule_type,
                    threshold_amount,
                    risk_score
                FROM banking.risk_rules
                WHERE is_active = TRUE
                ORDER BY risk_rule_id
                """
            )

            return cur.fetchall()

    finally:
        conn.close()

def evaluate_transaction(amount):
    rules = get_active_risk_rules()
    triggered_rules = []

    for rule in rules:
        risk_rule_id = rule[0]
        rule_name = rule[1]
        rule_type = rule[2]
        threshold_amount = rule[3]
        risk_score = rule[4]

        if (
            rule_type == "HIGH_VALUE_TRANSACTION"
            and threshold_amount is not None
            and amount >= threshold_amount
        ):
            triggered_rules.append(
                {
                    "risk_rule_id": risk_rule_id,
                    "rule_name": rule_name,
                    "risk_score": risk_score,
                }
            )

    return triggered_rules