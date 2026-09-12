CREATE TABLE banking.audit_logs (
    audit_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    record_id BIGINT,
    action_type VARCHAR(20) NOT NULL,
    changed_by VARCHAR(100) NOT NULL DEFAULT CURRENT_USER,
    changed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    old_data JSONB,
    new_data JSONB,

    CONSTRAINT chk_audit_logs_action_type
        CHECK (action_type IN ('INSERT', 'UPDATE', 'DELETE'))
);

CREATE OR REPLACE FUNCTION banking.audit_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN

    IF TG_OP = 'INSERT' THEN

        INSERT INTO banking.audit_logs
        (table_name, record_id, action_type, old_data, new_data)
        VALUES
        (TG_TABLE_NAME, NULL, TG_OP, NULL, to_jsonb(NEW));

        RETURN NEW;

    ELSIF TG_OP = 'UPDATE' THEN

        INSERT INTO banking.audit_logs
        (table_name, record_id, action_type, old_data, new_data)
        VALUES
        (TG_TABLE_NAME, NULL, TG_OP, to_jsonb(OLD), to_jsonb(NEW));

        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN

        INSERT INTO banking.audit_logs
        (table_name, record_id, action_type, old_data, new_data)
        VALUES
        (TG_TABLE_NAME, NULL, TG_OP, to_jsonb(OLD), NULL);

        RETURN OLD;

    END IF;

    RETURN NULL;
END;
$$;

-- Fires the audit function after account data changes.
CREATE TRIGGER trg_accounts_audit
AFTER INSERT OR UPDATE OR DELETE
ON banking.accounts
FOR EACH ROW
EXECUTE FUNCTION banking.audit_changes();

UPDATE banking.accounts
SET balance = 4500.00
WHERE account_id = 1;

