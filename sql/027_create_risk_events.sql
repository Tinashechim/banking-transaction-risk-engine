--Risk Event history
CREATE TABLE banking.risk_events (
    risk_event_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    risk_rule_id BIGINT NOT NULL,
    transaction_reference VARCHAR(50) NOT NULL,
    transaction_amount NUMERIC(15,2) NOT NULL,
    risk_score INTEGER NOT NULL,
    risk_level VARCHAR(20) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_risk_events_rule
        FOREIGN KEY (risk_rule_id)
        REFERENCES banking.risk_rules(risk_rule_id),

    CONSTRAINT chk_risk_events_amount
        CHECK (transaction_amount > 0),

    CONSTRAINT chk_risk_events_score
        CHECK (risk_score BETWEEN 0 AND 100),

    CONSTRAINT chk_risk_events_level
        CHECK (risk_level IN ('LOW', 'MEDIUM', 'HIGH'))
);