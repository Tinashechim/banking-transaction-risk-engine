from psycopg.errors import SerializationFailure

from src.database import run_with_retry


attempt_count = 0


def test_operation(conn):
    global attempt_count

    attempt_count += 1
    print(f"Attempt {attempt_count}")

    if attempt_count < 3:
        raise SerializationFailure("Simulated serialization failure")

    return "Operation successful"


result = run_with_retry(test_operation)

print(result)
print(f"Total attempts: {attempt_count}")