-- Stores configurable rules used to identify risky transactions.
CREATE TABLE banking.risk_rules (
    risk_rule_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    rule_name VARCHAR(100) NOT NULL UNIQUE,
    rule_type VARCHAR(50) NOT NULL,
    threshold_amount NUMERIC(15,2),
    risk_score INTEGER NOT NULL,

    -- BOOLEAN stores either TRUE or FALSE.
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- BETWEEN checks that the score falls within the allowed range.
    CONSTRAINT chk_risk_rules_score
        CHECK (risk_score BETWEEN 0 AND 100),

    -- NULL is allowed because not every risk rule requires a monetary threshold.
    CONSTRAINT chk_risk_rules_threshold
        CHECK (threshold_amount IS NULL OR threshold_amount >= 0),

    CONSTRAINT chk_risk_rules_type
        CHECK (rule_type IN (
            'HIGH_VALUE_TRANSACTION',
            'RAPID_TRANSACTION',
            'MULTIPLE_FAILED_ATTEMPTS'
        ))
);

-- Flags transactions that exceed the configured high-value threshold.
INSERT INTO banking.risk_rules
(rule_name, rule_type, threshold_amount, risk_score)
VALUES
(
    'Large Transaction Alert',
    'HIGH_VALUE_TRANSACTION',
    10000.00,
    70
);

