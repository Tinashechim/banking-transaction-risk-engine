CREATE OR REPLACE FUNCTION banking.record_risk_event(
    p_risk_rule_id BIGINT,
    p_transaction_reference VARCHAR(50),
    p_transaction_amount NUMERIC(15,2),
    p_risk_score INTEGER,
    p_risk_level VARCHAR(20)
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO banking, pg_temp
AS $$
BEGIN
    INSERT INTO banking.risk_events (
        risk_rule_id,
        transaction_reference,
        transaction_amount,
        risk_score,
        risk_level
    )
    VALUES (
        p_risk_rule_id,
        p_transaction_reference,
        p_transaction_amount,
        p_risk_score,
        p_risk_level
    );
END;
$$;

REVOKE ALL ON FUNCTION banking.record_risk_event(
    BIGINT,
    VARCHAR,
    NUMERIC,
    INTEGER,
    VARCHAR
) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION banking.record_risk_event(
    BIGINT,
    VARCHAR,
    NUMERIC,
    INTEGER,
    VARCHAR
) TO bank_app;