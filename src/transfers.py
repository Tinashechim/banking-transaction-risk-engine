from src.database import run_with_retry


# Transfer function
def transfer_funds(from_account_id, to_account_id, amount, reference):
    def operation(conn):
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT banking.transfer_funds
                (%s::BIGINT, 
                %s::BIGINT, 
                %s::NUMERIC, 
                %s::VARCHAR)
                """,
                (from_account_id, to_account_id, amount, reference),
            )

    return run_with_retry(operation)

