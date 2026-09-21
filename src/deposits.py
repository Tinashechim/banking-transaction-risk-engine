from src.database import run_with_retry


def deposit_funds(account_id, amount, reference):
    def operation(conn):
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT banking.deposit_funds(
                    %s::BIGINT,
                    %s::NUMERIC,
                    %s::VARCHAR
                )
                """,
                (account_id, amount, reference),
            )

    return run_with_retry(operation)