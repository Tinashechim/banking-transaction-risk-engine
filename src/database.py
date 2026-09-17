import os
import time
import psycopg

from psycopg.errors import DeadlockDetected, SerializationFailure 

DB_HOST = "localhost"
DB_PORT = 5432
DB_NAME = "banking_risk_engine"
DB_USER = "bank_app"
DB_PASSWORD = os.environ.get("BANK_DB_PASSWORD")

# Creates and returns a connection to the PostgreSQL database.
def get_connection():
    if not DB_PASSWORD:
        raise RuntimeError(
            "BANK_DB_PASSWORD environment variable is not set."
        )

    return psycopg.connect(
        host=DB_HOST,
        port=DB_PORT,
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
    )

#retry function
def run_with_retry(operation, max_attempts=3):
    for attempt in range(1, max_attempts + 1):
        conn = None

        try:
            conn = get_connection()
            result = operation(conn)
            conn.commit()
            return result

        except (SerializationFailure, DeadlockDetected):
            if conn:
                conn.rollback()

            if attempt == max_attempts:
                raise

            time.sleep(attempt)

        finally:
            if conn:
                conn.close()