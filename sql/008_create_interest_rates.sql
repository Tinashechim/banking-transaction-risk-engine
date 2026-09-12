CREATE TABLE banking.interest_rates (
    interest_rate_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    rate_name VARCHAR(100) NOT NULL,
    annual_rate NUMERIC(5,2) NOT NULL,
    effective_from DATE NOT NULL,
    effective_to DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_interest_rates_annual_rate
        CHECK (annual_rate >= 0),

    CONSTRAINT chk_interest_rates_date_range
        CHECK (
            effective_to IS NULL
            OR effective_to >= effective_from
        )
);

INSERT INTO banking.interest_rates
(rate_name, annual_rate, effective_from)
VALUES
('PERSONAL_LOAN_STANDARD', 12.50, CURRENT_DATE);