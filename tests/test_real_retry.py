import threading
import time

from src.database import get_connection, run_with_retry


attempt_count = 0


def competing_transaction():
    conn = get_connection()

    try:
        conn.execute(
            "SET TRANSACTION ISOLATION LEVEL SERIALIZABLE"
        )

        conn.execute(
            """
            SELECT banking.transfer_funds(
                %s::BIGINT,
                %s::BIGINT,
                %s::NUMERIC,
                %s::VARCHAR
            )
            """,
            (1, 4, 1.00, "RETRY-COMPETITOR"),
        )

        time.sleep(2)

        conn.commit()

    finally:
        conn.close()


def retry_operation(conn):
    global attempt_count
    attempt_count += 1

    print(f"Python attempt: {attempt_count}")

    conn.execute(
        "SET TRANSACTION ISOLATION LEVEL SERIALIZABLE"
    )

    conn.execute(
        "SELECT balance FROM banking.accounts WHERE account_id = 1"
    ).fetchone()

    time.sleep(1)

    conn.execute(
        """
        SELECT banking.transfer_funds(
            %s::BIGINT,
            %s::BIGINT,
            %s::NUMERIC,
            %s::VARCHAR
        )
        """,
        (1, 4, 1.00, "RETRY-MAIN"),
    )


worker = threading.Thread(target=competing_transaction)

worker.start()

time.sleep(0.5)

run_with_retry(retry_operation)

worker.join()

print(f"Total Python attempts: {attempt_count}")