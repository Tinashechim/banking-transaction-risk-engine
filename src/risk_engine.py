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


def classify_risk_score(risk_score):
    if risk_score >= 60:
        return "HIGH"

    if risk_score >= 30:
        return "MEDIUM"

    return "LOW"


def save_risk_event(
    risk_rule_id,
    transaction_reference,
    transaction_amount,
    risk_score,
    risk_level,
):
    conn = get_connection()

    try:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT banking.record_risk_event(
                    %s::BIGINT,
                    %s::VARCHAR,
                    %s::NUMERIC,
                    %s::INTEGER,
                    %s::VARCHAR
                )
                """,
                (
                    risk_rule_id,
                    transaction_reference,
                    transaction_amount,
                    risk_score,
                    risk_level,
                ),
            )

        conn.commit()

    except Exception:
        conn.rollback()
        raise

    finally:
        conn.close()


def evaluate_transaction(amount, reference=None):
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
            risk_level = classify_risk_score(risk_score)

            triggered_rules.append(
                {
                    "risk_rule_id": risk_rule_id,
                    "rule_name": rule_name,
                    "risk_score": risk_score,
                    "risk_level": risk_level,
                }
            )

            if reference is not None:
                save_risk_event(
                    risk_rule_id,
                    reference,
                    amount,
                    risk_score,
                    risk_level,
                )

    return triggered_rules